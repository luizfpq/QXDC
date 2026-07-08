#!/bin/bash
# lib/distro.sh — Detecção de distribuição e gerenciador de pacotes
# Sourced by modules — não executar diretamente.

# Detecta a distribuição e exporta variáveis
detect_distro() {
    DISTRO_ID=""
    DISTRO_VERSION=""
    DISTRO_CODENAME=""
    DISTRO_FAMILY=""

    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        DISTRO_CODENAME="${VERSION_CODENAME:-unknown}"
    elif command_exists lsb_release; then
        DISTRO_ID="$(lsb_release -si | tr '[:upper:]' '[:lower:]')"
        DISTRO_VERSION="$(lsb_release -sr)"
        DISTRO_CODENAME="$(lsb_release -sc)"
    fi

    # Determinar família
    case "$DISTRO_ID" in
        debian|ubuntu|linuxmint|pop|elementary|zorin)
            DISTRO_FAMILY="debian"
            ;;
        arch|manjaro|endeavouros|garuda)
            DISTRO_FAMILY="arch"
            ;;
        fedora|rhel|centos|rocky|alma)
            DISTRO_FAMILY="redhat"
            ;;
        *)
            DISTRO_FAMILY="unknown"
            ;;
    esac

    export DISTRO_ID DISTRO_VERSION DISTRO_CODENAME DISTRO_FAMILY
}

# Retorna o comando de instalação de pacotes
pkg_install_cmd() {
    case "$DISTRO_FAMILY" in
        debian)
            echo "apt-get install -qq -y"
            ;;
        arch)
            if command_exists yay; then
                echo "yay -S --noconfirm"
            elif command_exists paru; then
                echo "paru -S --noconfirm"
            else
                echo "pacman -S --noconfirm"
            fi
            ;;
        redhat)
            echo "dnf install -y"
            ;;
        *)
            log_error "Família de distro não suportada: $DISTRO_FAMILY"
            return 1
            ;;
    esac
}

# Retorna o comando de remoção de pacotes
pkg_remove_cmd() {
    case "$DISTRO_FAMILY" in
        debian)
            echo "apt-get purge -qq -y"
            ;;
        arch)
            echo "pacman -Rns --noconfirm"
            ;;
        redhat)
            echo "dnf remove -y"
            ;;
        *)
            log_error "Família de distro não suportada: $DISTRO_FAMILY"
            return 1
            ;;
    esac
}

# Atualiza índice de pacotes
pkg_update() {
    case "$DISTRO_FAMILY" in
        debian)
            run_sudo apt-get update -qq
            ;;
        arch)
            run_sudo pacman -Sy
            ;;
        redhat)
            run_sudo dnf check-update || true
            ;;
    esac
}

# Instala lista de pacotes
pkg_install() {
    local cmd
    cmd="$(pkg_install_cmd)"
    local failed=0

    for pkg in "$@"; do
        if is_installed "$pkg" 2>/dev/null; then
            [[ "$QXDC_VERBOSE" == "true" ]] && log_info "$pkg já instalado, pulando."
            continue
        fi
        log_info "Instalando $pkg..."
        if run_sudo $cmd "$pkg"; then
            log_ok "$pkg"
        else
            log_warn "Falha ao instalar $pkg"
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed pacote(s) falharam na instalação."
        return 1
    fi
}

# Remove lista de pacotes
pkg_remove() {
    local cmd
    cmd="$(pkg_remove_cmd)"
    local failed=0

    for pkg in "$@"; do
        if ! is_installed "$pkg" 2>/dev/null; then
            [[ "$QXDC_VERBOSE" == "true" ]] && log_info "$pkg não está instalado, pulando."
            continue
        fi
        log_info "Removendo $pkg..."
        if run_sudo $cmd "$pkg"; then
            log_ok "$pkg removido"
        else
            log_warn "Falha ao remover $pkg"
            failed=$((failed + 1))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed pacote(s) falharam na remoção."
        return 1
    fi
}

# Habilita repositórios contrib + non-free (Debian)
# Debian 12+ separou non-free-firmware (firmware livre de redistribuir) de non-free (drivers
# proprietários, codecs, etc). Muitos pacotes úteis vivem em contrib/non-free.
enable_nonfree_repos() {
    local sources="/etc/apt/sources.list"

    if [[ "$DISTRO_FAMILY" != "debian" ]]; then
        return 0
    fi

    # Já tem contrib + non-free?
    if grep -qE "^deb .* main contrib non-free" "$sources" 2>/dev/null; then
        [[ "$QXDC_VERBOSE" == "true" ]] && log_info "Repositórios contrib + non-free já habilitados."
        return 0
    fi

    log_info "Habilitando repositórios contrib + non-free no sources.list..."

    # Adicionar contrib e non-free preservando non-free-firmware se existir
    run_sudo sed -i 's/main non-free-firmware/main contrib non-free non-free-firmware/' "$sources"
    # Linhas com apenas "main" (sem non-free-firmware)
    run_sudo sed -i '/contrib/!s/ main$/ main contrib non-free/' "$sources"

    pkg_update
    log_ok "Repositórios contrib + non-free habilitados."
}

# Inicializa detecção automaticamente ao ser sourced
detect_distro
