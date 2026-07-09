#!/bin/bash
# modules/system/nvidia.sh — Instalação de drivers NVIDIA via repositório oficial
# Segue: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/debian.html
#
# Fluxo:
#   1. Detecta GPU NVIDIA (lspci)
#   2. Instala pré-requisitos (linux-headers, wget)
#   3. Adiciona repositório oficial NVIDIA via cuda-keyring
#   4. Instala driver (open ou proprietário, full/compute/desktop)
#   5. Instrui reboot
#
# Uso:
#   ./qxdc.sh system nvidia [--dry-run] [--yes] [--verbose]
#   ./qxdc.sh system nvidia --driver open        # open kernel modules (Turing+)
#   ./qxdc.sh system nvidia --driver proprietary  # módulos proprietários
#   ./qxdc.sh system nvidia --mode full           # full (padrão)
#   ./qxdc.sh system nvidia --mode compute        # headless, sem GL/Vulkan/X
#   ./qxdc.sh system nvidia --mode desktop        # desktop sem CUDA

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"

# --- Defaults ---
NVIDIA_DRIVER="open"       # open | proprietary
NVIDIA_MODE="full"         # full | compute | desktop

# --- Parse flags ---
parse_common_flags "$@"
set -- "${QXDC_REMAINING_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --driver)
            NVIDIA_DRIVER="$2"
            if [[ "$NVIDIA_DRIVER" != "open" && "$NVIDIA_DRIVER" != "proprietary" ]]; then
                log_error "--driver deve ser 'open' ou 'proprietary'."
                exit 1
            fi
            shift
            ;;
        --mode)
            NVIDIA_MODE="$2"
            if [[ "$NVIDIA_MODE" != "full" && "$NVIDIA_MODE" != "compute" && "$NVIDIA_MODE" != "desktop" ]]; then
                log_error "--mode deve ser 'full', 'compute' ou 'desktop'."
                exit 1
            fi
            shift
            ;;
        --profile) shift ;; # aceita mas ignora (não usa profiles)
        *) log_error "Flag desconhecida: $1"; exit 1 ;;
    esac
    shift
done

# --- Detecção de GPU ---
detect_nvidia() {
    if command_exists lspci; then
        lspci 2>/dev/null | grep -qi "nvidia"
        return $?
    fi
    if lsmod 2>/dev/null | grep -qi "nouveau\|nvidia"; then
        return 0
    fi
    return 1
}

get_nvidia_model() {
    if command_exists lspci; then
        lspci 2>/dev/null | grep -i "vga.*nvidia\|3d.*nvidia" | head -1 | sed 's/.*: //'
    else
        echo "GPU NVIDIA (modelo desconhecido)"
    fi
}

# Retorna a arquitetura da GPU (para recomendar open vs proprietary)
get_nvidia_arch_hint() {
    local model
    model="$(get_nvidia_model)"
    # Turing (GTX 16xx, RTX 20xx) e mais recentes suportam open kernel modules
    if echo "$model" | grep -qiE "RTX [2-9]0|RTX [A-Z]|GTX 16|A[0-9]{3,4}|L[0-9]{2,3}|H100|H200|B100|B200"; then
        echo "open"
    else
        echo "proprietary"
    fi
}

# --- Mapear distro para formato NVIDIA (debian12, debian13, etc) ---
get_nvidia_distro_string() {
    case "$DISTRO_ID" in
        debian)
            echo "debian${DISTRO_VERSION%%.*}"
            ;;
        ubuntu)
            echo "ubuntu${DISTRO_VERSION//.}"
            ;;
        *)
            echo ""
            ;;
    esac
}

# --- Verificar se cuda-keyring já está instalado ---
has_nvidia_repo() {
    is_installed cuda-keyring 2>/dev/null && return 0
    # Fallback: verificar se o sources.list.d tem algo da NVIDIA
    ls /etc/apt/sources.list.d/cuda-* 2>/dev/null | grep -q . && return 0
    return 1
}

# --- Verificar se driver NVIDIA já está funcional ---
nvidia_is_working() {
    command_exists nvidia-smi && nvidia-smi &>/dev/null
}

# --- Instalar pré-requisitos ---
install_prerequisites() {
    log_step "Instalando pré-requisitos"

    local prereqs=(
        linux-headers-"$(uname -r)"
        wget
        dkms
    )

    log_info "Pacotes: ${prereqs[*]}"
    pkg_install "${prereqs[@]}"
}

# --- Adicionar repositório oficial NVIDIA ---
setup_nvidia_repo() {
    log_step "Configurando repositório oficial NVIDIA"

    if has_nvidia_repo; then
        log_info "Repositório NVIDIA já configurado (cuda-keyring presente)."
        return 0
    fi

    local distro_str
    distro_str="$(get_nvidia_distro_string)"

    if [[ -z "$distro_str" ]]; then
        log_error "Distro '$DISTRO_ID $DISTRO_VERSION' não suportada pelo repositório NVIDIA."
        log_info "Distros suportadas: Debian 12+, Ubuntu 22.04+"
        return 1
    fi

    local arch
    arch="$(dpkg --print-architecture)"

    # NVIDIA usa x86_64 no path da URL, não amd64
    local url_arch="x86_64"
    if [[ "$arch" == "arm64" ]]; then
        url_arch="sbsa"
    fi

    local keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/${distro_str}/${url_arch}/cuda-keyring_1.1-1_all.deb"
    local keyring_deb="/tmp/cuda-keyring_1.1-1_all.deb"

    log_info "Baixando cuda-keyring de:"
    log_info "  $keyring_url"

    run wget -q -O "$keyring_deb" "$keyring_url" || {
        log_error "Falha ao baixar cuda-keyring."
        log_info "Verifique conexão com developer.download.nvidia.com"
        log_info "URL tentada: $keyring_url"
        return 1
    }

    run_sudo dpkg -i "$keyring_deb" || {
        log_error "Falha ao instalar cuda-keyring."
        return 1
    }

    rm -f "$keyring_deb"

    log_info "Atualizando índice de pacotes..."
    run_sudo apt-get update -qq

    log_ok "Repositório oficial NVIDIA configurado."
}

# --- Remover nouveau (conflita com driver proprietário) ---
blacklist_nouveau() {
    local blacklist_file="/etc/modprobe.d/nvidia-blacklist-nouveau.conf"

    if [[ -f "$blacklist_file" ]]; then
        [[ "$QXDC_VERBOSE" == "true" ]] && log_info "Nouveau já está em blacklist."
        return 0
    fi

    log_info "Adicionando nouveau à blacklist (conflita com driver NVIDIA)..."
    run_sudo tee "$blacklist_file" > /dev/null <<EOF
# Gerado por QXDC — nvidia.sh
# Nouveau conflita com o driver proprietário/open da NVIDIA
blacklist nouveau
options nouveau modeset=0
EOF

    # Rebuild initramfs para aplicar
    if command_exists update-initramfs; then
        log_info "Reconstruindo initramfs..."
        run_sudo update-initramfs -u
    fi
}

# --- Determinar pacotes a instalar ---
get_install_packages() {
    local packages=()

    case "$NVIDIA_MODE" in
        full)
            if [[ "$NVIDIA_DRIVER" == "open" ]]; then
                packages=(nvidia-open)
            else
                packages=(cuda-drivers)
            fi
            ;;
        compute)
            if [[ "$NVIDIA_DRIVER" == "open" ]]; then
                packages=(nvidia-driver-cuda nvidia-kernel-open-dkms)
            else
                packages=(nvidia-driver-cuda nvidia-kernel-dkms)
            fi
            ;;
        desktop)
            if [[ "$NVIDIA_DRIVER" == "open" ]]; then
                packages=(nvidia-driver nvidia-kernel-open-dkms)
            else
                packages=(nvidia-driver nvidia-kernel-dkms)
            fi
            ;;
    esac

    echo "${packages[@]}"
}

# --- Instalar driver ---
install_driver() {
    log_step "Instalando driver NVIDIA (driver=$NVIDIA_DRIVER, mode=$NVIDIA_MODE)"

    local packages
    packages="$(get_install_packages)"

    log_info "Pacotes: $packages"

    # shellcheck disable=SC2086
    run_sudo apt-get install -y $packages || {
        log_error "Falha na instalação dos pacotes NVIDIA."
        log_info "Verifique o log em $QXDC_LOG para detalhes."
        return 1
    }

    log_ok "Driver NVIDIA instalado com sucesso."
}

# --- Resumo pós-instalação ---
post_install_summary() {
    echo ""
    log_step "Resumo da instalação NVIDIA"
    log_info "Driver:    $NVIDIA_DRIVER kernel modules"
    log_info "Modo:      $NVIDIA_MODE"
    log_info "Pacotes:   $(get_install_packages)"
    echo ""
    log_warn "REBOOT NECESSARIO para carregar o driver."
    log_info "Após reiniciar, verifique com:"
    log_info "  nvidia-smi"
    log_info "  cat /proc/driver/nvidia/version"
    echo ""
    log_info "Para atualizar o driver no futuro:"
    log_info "  sudo apt dist-upgrade"
}

# --- Main ---
main() {
    log_step "QXDC — Instalação NVIDIA (guia oficial)"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    # --- Validar distro ---
    if [[ "$DISTRO_FAMILY" != "debian" ]]; then
        log_error "Este módulo suporta apenas Debian/Ubuntu."
        log_info "Para Arch, use: pacman -S nvidia nvidia-open nvidia-utils"
        exit 1
    fi

    local distro_str
    distro_str="$(get_nvidia_distro_string)"
    if [[ -z "$distro_str" ]]; then
        log_error "Não foi possível mapear distro para o formato NVIDIA."
        exit 1
    fi
    log_info "Distro NVIDIA: $distro_str"

    # --- Detectar GPU ---
    log_info "Verificando GPU NVIDIA..."
    if ! detect_nvidia; then
        log_error "Nenhuma GPU NVIDIA detectada (lspci)."
        log_info "Se a GPU está presente mas não aparece, verifique:"
        log_info "  - Slot PCIe / conexão física"
        log_info "  - BIOS/UEFI (GPU desabilitada?)"
        exit 1
    fi

    local gpu_model
    gpu_model="$(get_nvidia_model)"
    log_ok "GPU detectada: $gpu_model"

    # --- Recomendar open vs proprietary ---
    local recommended
    recommended="$(get_nvidia_arch_hint)"
    if [[ "$NVIDIA_DRIVER" != "$recommended" ]]; then
        log_warn "Recomendação para sua GPU: --driver $recommended"
        log_info "Você selecionou: --driver $NVIDIA_DRIVER"
        log_info "(Open kernel modules requerem Turing ou mais recente — GTX 16xx/RTX 20xx+)"
    else
        log_info "Driver selecionado ($NVIDIA_DRIVER) é compatível com sua GPU."
    fi

    # --- Verificar se já está funcional ---
    if nvidia_is_working; then
        log_ok "nvidia-smi já está funcional!"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | while read -r line; do
            log_info "  $line"
        done
        echo ""
        if ! confirm "Driver já funcional. Reinstalar/atualizar mesmo assim?"; then
            log_info "Abortado pelo usuário."
            return 0
        fi
    fi

    # --- Dry-run: apenas reportar ---
    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        echo ""
        log_info "[DRY-RUN] Ações que seriam executadas:"
        log_info "  1. Instalar pré-requisitos: linux-headers-$(uname -r), wget, dkms"
        log_info "  2. Baixar e instalar cuda-keyring (repo oficial NVIDIA)"
        log_info "     URL: https://developer.download.nvidia.com/compute/cuda/repos/${distro_str}/x86_64/cuda-keyring_1.1-1_all.deb"
        log_info "  3. Blacklist nouveau"
        log_info "  4. Instalar: $(get_install_packages)"
        log_info "  5. Reboot necessário"
        echo ""
        log_info "Para executar: remova --dry-run e adicione --yes (ou confirme interativamente)"
        return 0
    fi

    # --- Confirmação ---
    echo ""
    log_info "Configuração selecionada:"
    log_info "  GPU:     $gpu_model"
    log_info "  Driver:  $NVIDIA_DRIVER"
    log_info "  Modo:    $NVIDIA_MODE"
    log_info "  Pacotes: $(get_install_packages)"
    log_info "  Repo:    NVIDIA oficial via cuda-keyring"
    echo ""
    log_warn "Isso irá:"
    log_info "  - Adicionar o repositório oficial NVIDIA ao apt"
    log_info "  - Bloquear o driver nouveau"
    log_info "  - Instalar driver NVIDIA + DKMS"
    log_info "  - Exigir reboot após conclusão"
    echo ""

    if ! confirm "Prosseguir com a instalação?"; then
        log_info "Abortado pelo usuário."
        return 0
    fi

    # --- Execução ---
    install_prerequisites || exit 1
    setup_nvidia_repo     || exit 1
    blacklist_nouveau     || exit 1
    install_driver        || exit 1
    post_install_summary
}

main
