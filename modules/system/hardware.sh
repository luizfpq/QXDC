#!/bin/bash
# modules/system/hardware.sh — Detecção e configuração de hardware opcional
# Detecta Bluetooth e NVIDIA, oferece instalação com confirmação do usuário.
#
# Comportamento:
#   - Detecta hardware presente na máquina
#   - Avisa o usuário sobre o que foi encontrado
#   - Pede confirmação antes de instalar drivers/suporte
#   - Com --yes, instala sem perguntar
#
# Uso: ./modules/system/hardware.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

# --- Flags ---
PROFILE="minimal"

parse_common_flags "$@"
set -- "${QXDC_REMAINING_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift ;;
        *) log_error "Flag desconhecida: $1"; exit 1 ;;
    esac
    shift
done

# --- Detecção de Bluetooth ---
detect_bluetooth() {
    # Método 1: rfkill
    if command_exists rfkill; then
        if rfkill list bluetooth 2>/dev/null | grep -qi "bluetooth"; then
            return 0
        fi
    fi

    # Método 2: lsusb (adaptadores USB)
    if command_exists lsusb; then
        if lsusb 2>/dev/null | grep -qi "bluetooth"; then
            return 0
        fi
    fi

    # Método 3: lspci (adaptadores integrados)
    if command_exists lspci; then
        if lspci 2>/dev/null | grep -qi "bluetooth"; then
            return 0
        fi
    fi

    # Método 4: hciconfig (se bluez já estiver parcialmente instalado)
    if command_exists hciconfig; then
        if hciconfig 2>/dev/null | grep -q "hci"; then
            return 0
        fi
    fi

    return 1
}

# --- Detecção de NVIDIA ---
detect_nvidia() {
    if command_exists lspci; then
        if lspci 2>/dev/null | grep -qi "nvidia"; then
            return 0
        fi
    fi

    # Fallback: verificar módulo no kernel
    if lsmod 2>/dev/null | grep -qi "nouveau\|nvidia"; then
        return 0
    fi

    return 1
}

# --- Obter modelo da GPU NVIDIA ---
get_nvidia_model() {
    if command_exists lspci; then
        lspci 2>/dev/null | grep -i "nvidia" | head -1 | sed 's/.*: //'
    else
        echo "GPU NVIDIA (modelo desconhecido)"
    fi
}

# --- Instalar suporte Bluetooth ---
install_bluetooth() {
    log_step "Instalando suporte Bluetooth"

    local bt_packages=(
        bluez
        blueman
        pulseaudio-module-bluetooth
    )

    log_info "Pacotes: ${bt_packages[*]}"

    pkg_install "${bt_packages[@]}"

    # Habilitar serviço bluetooth
    if command_exists systemctl; then
        log_info "Habilitando serviço bluetooth..."
        run_sudo systemctl enable bluetooth
        run_sudo systemctl start bluetooth
    fi

    log_ok "Suporte Bluetooth instalado e habilitado."
    log_info "Blueman fornece o applet/indicator no system tray do XFCE."
    log_info "Use o ícone Bluetooth no painel para parear e gerenciar dispositivos."
}

# --- Habilitar non-free no sources.list (Debian) ---
# Usa enable_nonfree_repos de lib/distro.sh (já sourced acima)

# --- Instalar drivers NVIDIA ---
install_nvidia() {
    log_step "Instalando drivers NVIDIA"

    case "$DISTRO_FAMILY" in
        debian)
            enable_nonfree_repos

            local nvidia_packages=(
                nvidia-driver
                firmware-misc-nonfree
                nvidia-settings
            )

            log_info "Pacotes: ${nvidia_packages[*]}"
            pkg_install "${nvidia_packages[@]}"

            log_ok "Driver NVIDIA instalado."
            log_warn "REBOOT NECESSARIO para ativar o driver proprietário."
            log_info "Após reiniciar, verifique com: nvidia-smi"
            ;;
        arch)
            local nvidia_packages=(nvidia nvidia-utils nvidia-settings)
            log_info "Pacotes: ${nvidia_packages[*]}"
            pkg_install "${nvidia_packages[@]}"
            log_ok "Driver NVIDIA instalado."
            log_warn "REBOOT NECESSARIO para ativar o driver proprietário."
            ;;
        *)
            log_error "Instalação de driver NVIDIA não suportada em $DISTRO_FAMILY."
            log_info "Instale manualmente seguindo a documentação da sua distro."
            return 1
            ;;
    esac
}

# --- Main ---
main() {
    log_step "Detecção de hardware — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    local found_bluetooth=false
    local found_nvidia=false

    # --- Detectar Bluetooth ---
    log_info "Verificando Bluetooth..."
    if detect_bluetooth; then
        found_bluetooth=true
        log_ok "Controlador Bluetooth detectado."
    else
        log_info "Nenhum controlador Bluetooth encontrado."
    fi

    # --- Detectar NVIDIA ---
    log_info "Verificando GPU NVIDIA..."
    if detect_nvidia; then
        found_nvidia=true
        local gpu_model
        gpu_model="$(get_nvidia_model)"
        log_ok "GPU NVIDIA detectada: $gpu_model"
    else
        log_info "Nenhuma GPU NVIDIA encontrada."
    fi

    # --- Nada encontrado ---
    if [[ "$found_bluetooth" == "false" && "$found_nvidia" == "false" ]]; then
        log_info "Nenhum hardware opcional detectado. Nada a fazer."
        return 0
    fi

    # --- Dry-run: apenas reportar ---
    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        [[ "$found_bluetooth" == "true" ]] && \
            log_info "[DRY-RUN] Instalaria suporte Bluetooth (bluez, blueman)"
        [[ "$found_nvidia" == "true" ]] && \
            log_info "[DRY-RUN] Instalaria driver NVIDIA (nvidia-driver, nvidia-settings)"
        return 0
    fi

    # --- Bluetooth: confirmar e instalar ---
    if [[ "$found_bluetooth" == "true" ]]; then
        if is_installed bluez 2>/dev/null && is_installed blueman 2>/dev/null; then
            log_info "Suporte Bluetooth já instalado (bluez + blueman)."
        else
            echo ""
            log_warn "Bluetooth detectado mas suporte não está instalado."
            log_info "Pacotes necessários: bluez, blueman"
            log_info "Isso permitirá conectar fones, teclados e outros dispositivos BT."
            echo ""
            if confirm "Instalar suporte Bluetooth?"; then
                install_bluetooth
            else
                log_info "Bluetooth ignorado pelo usuário."
            fi
        fi
    fi

    # --- NVIDIA: confirmar e instalar ---
    if [[ "$found_nvidia" == "true" ]]; then
        if is_installed nvidia-driver 2>/dev/null; then
            log_info "Driver NVIDIA já instalado."
        else
            echo ""
            log_warn "GPU NVIDIA detectada mas driver proprietário não está instalado."
            log_info "O sistema está usando nouveau (driver open-source genérico)."
            log_info "O driver proprietário oferece melhor performance e suporte a CUDA."
            log_warn "A instalação requer reboot e pode alterar o sources.list (non-free)."
            echo ""
            if confirm "Instalar driver NVIDIA proprietário?"; then
                install_nvidia
            else
                log_info "Driver NVIDIA ignorado pelo usuário."
            fi
        fi
    fi
}

main
