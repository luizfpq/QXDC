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
    compgen -G "/etc/apt/sources.list.d/cuda-*" >/dev/null 2>&1 && return 0
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

# --- Reativar linha deb comentada do repo CUDA/NVIDIA ---
# Procura em /etc/apt/sources.list.d/ por arquivos cuda*.list com a linha "deb"
# comentada e a descomenta (com backup). Cobre o caso clássico de alguém ter
# comentado o repo para "testar" e depois o driver sumir dos candidatos do apt.
ensure_nvidia_repo_enabled() {
    local changed=0
    local f
    for f in /etc/apt/sources.list.d/cuda*.list; do
        [[ -f "$f" ]] || continue
        if grep -qE '^[[:space:]]*#[[:space:]]*deb[[:space:]].*nvidia\.com' "$f"; then
            log_warn "Repo NVIDIA comentado em $f — reativando (com backup)."
            run_sudo cp "$f" "${f}.qxdc-bak.$(date +%Y%m%d%H%M%S)"
            run_sudo sed -i 's|^[[:space:]]*#[[:space:]]*\(deb[[:space:]].*nvidia\.com.*\)|\1|' "$f"
            changed=1
        fi
    done
    if [[ "$changed" -eq 1 ]]; then
        log_info "Atualizando índice de pacotes após reativar o repo..."
        run_sudo apt-get update -qq
    fi
}

# --- Adicionar repositório oficial NVIDIA ---
setup_nvidia_repo() {
    log_step "Configurando repositório oficial NVIDIA"

    # Mesmo com cuda-keyring instalado, a linha "deb" pode estar COMENTADA
    # (ex.: usuário comentou tentando depurar). Detecta e reativa, senão o
    # driver "some" dos candidatos do apt e a instalação falha silenciosamente.
    ensure_nvidia_repo_enabled

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

# --- Detectar e neutralizar xorg.conf legado conflitante ---
# Um /etc/X11/xorg.conf gerado por `nvidia-xconfig` (ou mão) costuma apontar
# Driver "nvidia"/"nv" com ChipId 0x0 e SEM BusID válido. Se o driver não estiver
# instalado/funcional, isso trava o Xorg em "Cannot run in framebuffer mode"
# (tela preta). Este passo faz backup e remove o arquivo, deixando o Xorg usar
# o autoconfig + o drop-in correto gerado por setup_nvidia_xorg().
check_xorg_conflict() {
    local xorg_conf="/etc/X11/xorg.conf"
    [[ -f "$xorg_conf" ]] || return 0

    if grep -qiE "nvidia-xconfig|ChipId[[:space:]]+0x0|Driver[[:space:]]+\"nv\"" "$xorg_conf" 2>/dev/null; then
        log_warn "Detectado /etc/X11/xorg.conf legado (provável nvidia-xconfig)."
        log_warn "Esse arquivo quebra o X se o driver não estiver 100% funcional (tela preta)."
        local bkp="${xorg_conf}.qxdc-bak.$(date +%Y%m%d%H%M%S)"
        log_info "Backup em $bkp e removendo o xorg.conf conflitante."
        run_sudo cp "$xorg_conf" "$bkp"
        run_sudo rm -f "$xorg_conf"
    else
        log_info "/etc/X11/xorg.conf existe e não parece conflitante; mantido."
    fi
}

# --- Descobrir o BusID PCI da GPU NVIDIA no formato Xorg (PCI:bus:dev:func) ---
# lspci dá "02:00.0" (hex); o Xorg espera "PCI:2:0:0" (decimal). Converte na mão.
get_nvidia_xorg_busid() {
    local pci
    pci="$(lspci -d 10de:: 2>/dev/null | grep -iE "vga|3d" | head -1 | awk '{print $1}')"
    [[ -z "$pci" ]] && return 1
    local bus dev func
    bus="$(printf '%d' "0x${pci%%:*}")"
    local rest="${pci#*:}"
    dev="$(printf '%d' "0x${rest%%.*}")"
    func="$(printf '%d' "0x${rest##*.}")"
    printf 'PCI:%d:%d:%d\n' "$bus" "$dev" "$func"
}

# --- Configurar Xorg para workstation com display na própria NVIDIA ---
# Em desktops/workstations onde o monitor sai pelas saídas da placa NVIDIA
# (dGPU dedicada, não Optimus de laptop), gera um drop-in mínimo e CORRETO em
# /etc/X11/xorg.conf.d/ apontando o Driver nvidia no BusID real + habilita o
# modeset do nvidia-drm. Isso evita que o usuário precise recorrer a
# `nvidia-xconfig` (que gera um xorg.conf frágil). Só aplica no modo full/desktop.
setup_nvidia_xorg() {
    [[ "$NVIDIA_MODE" == "compute" ]] && return 0  # headless não precisa de X

    local busid
    busid="$(get_nvidia_xorg_busid)" || {
        log_warn "Não foi possível determinar o BusID da NVIDIA; pulando config do Xorg."
        return 0
    }

    local dropin="/etc/X11/xorg.conf.d/10-nvidia.conf"
    log_info "Gerando drop-in do Xorg para a NVIDIA ($busid): $dropin"
    run_sudo install -d /etc/X11/xorg.conf.d
    run_sudo tee "$dropin" > /dev/null <<EOF
# Gerado por QXDC — nvidia.sh
# Workstation/desktop com saída de vídeo na própria GPU NVIDIA (dGPU dedicada).
# Driver nvidia no BusID real + AllowEmptyInitialConfiguration (permite o X subir
# mesmo sem monitor detectado no boot). NÃO use nvidia-xconfig manualmente — ele
# gera um /etc/X11/xorg.conf frágil que pode causar tela preta.
Section "Device"
    Identifier     "nvidia"
    Driver         "nvidia"
    BusID          "$busid"
    Option         "AllowEmptyInitialConfiguration" "true"
EndSection

Section "Screen"
    Identifier     "nvidia-screen"
    Device         "nvidia"
EndSection
EOF

    # Habilitar modeset do nvidia-drm (recomendado p/ Wayland, PRIME e integração)
    local modeset_conf="/etc/modprobe.d/nvidia-drm-modeset.conf"
    if [[ ! -f "$modeset_conf" ]]; then
        log_info "Habilitando nvidia-drm modeset=1."
        run_sudo tee "$modeset_conf" > /dev/null <<EOF
# Gerado por QXDC — nvidia.sh
options nvidia-drm modeset=1
EOF
        command_exists update-initramfs && run_sudo update-initramfs -u
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
        log_info "  2. Baixar e instalar cuda-keyring (repo oficial NVIDIA) + reativar repo se comentado"
        log_info "     URL: https://developer.download.nvidia.com/compute/cuda/repos/${distro_str}/x86_64/cuda-keyring_1.1-1_all.deb"
        log_info "  3. Blacklist nouveau"
        log_info "  4. Neutralizar /etc/X11/xorg.conf legado conflitante (se houver)"
        log_info "  5. Instalar: $(get_install_packages)"
        log_info "  6. Configurar Xorg p/ dGPU (drop-in 10-nvidia.conf + nvidia-drm modeset=1)"
        log_info "  7. Reboot necessário"
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
    check_xorg_conflict   || exit 1
    install_driver        || exit 1
    setup_nvidia_xorg     || exit 1
    post_install_summary
}

main
