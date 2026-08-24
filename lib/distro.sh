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
        alpine)
            DISTRO_FAMILY="alpine"
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

# Retorna o comando de instalação de pacotes como array (via nameref)
# Uso: local -a cmd; pkg_install_cmd cmd
pkg_install_cmd() {
    # shellcheck disable=SC2178
    local -n _arr="${1:-_pkg_cmd}"
    case "$DISTRO_FAMILY" in
        debian)
            _arr=(apt-get install -qq -y)
            ;;
        alpine)
            _arr=(apk add --no-interactive)
            ;;
        arch)
            if command_exists yay; then
                _arr=(yay -S --noconfirm)
            elif command_exists paru; then
                _arr=(paru -S --noconfirm)
            else
                _arr=(pacman -S --noconfirm)
            fi
            ;;
        redhat)
            _arr=(dnf install -y)
            ;;
        *)
            log_error "Família de distro não suportada: $DISTRO_FAMILY"
            return 1
            ;;
    esac
}

# Retorna o comando de remoção de pacotes como array (via nameref)
# Uso: local -a cmd; pkg_remove_cmd cmd
pkg_remove_cmd() {
    # shellcheck disable=SC2178
    local -n _arr="${1:-_pkg_cmd}"
    case "$DISTRO_FAMILY" in
        debian)
            _arr=(apt-get purge -qq -y)
            ;;
        alpine)
            _arr=(apk del --no-interactive)
            ;;
        arch)
            _arr=(pacman -Rns --noconfirm)
            ;;
        redhat)
            _arr=(dnf remove -y)
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
        alpine)
            run_sudo apk update
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
    local -a cmd=()
    pkg_install_cmd cmd || return 1
    local failed=0

    for pkg in "$@"; do
        if is_installed "$pkg" 2>/dev/null; then
            [[ "$QXDC_VERBOSE" == "true" ]] && log_info "$pkg já instalado, pulando."
            continue
        fi
        log_info "Instalando $pkg..."
        if run_sudo "${cmd[@]}" "$pkg"; then
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
    local -a cmd=()
    pkg_remove_cmd cmd || return 1
    local failed=0

    for pkg in "$@"; do
        if ! is_installed "$pkg" 2>/dev/null; then
            [[ "$QXDC_VERBOSE" == "true" ]] && log_info "$pkg não está instalado, pulando."
            continue
        fi
        log_info "Removendo $pkg..."
        if run_sudo "${cmd[@]}" "$pkg"; then
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

# Habilita repositórios extras conforme a distro
# Debian: contrib + non-free
# Alpine: community + testing (se necessário)
enable_nonfree_repos() {
    case "$DISTRO_FAMILY" in
        debian) _enable_debian_nonfree ;;
        alpine) _enable_alpine_community ;;
        *) return 0 ;;
    esac
}

# --- Debian: contrib + non-free ---
_enable_debian_nonfree() {
    local sources="/etc/apt/sources.list"

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

# --- Alpine: habilitar community ---
_enable_alpine_community() {
    local repos="/etc/apk/repositories"

    if grep -qE "^[^#].*/community$" "$repos" 2>/dev/null; then
        [[ "$QXDC_VERBOSE" == "true" ]] && log_info "Repositório community já habilitado."
        return 0
    fi

    log_info "Habilitando repositório community..."

    # Descomentar linha de community se existir comentada
    if grep -qE "^#.*/community$" "$repos" 2>/dev/null; then
        run_sudo sed -i 's|^#\(.*community\)$|\1|' "$repos"
    else
        # Adicionar baseado no main existente
        local main_url
        main_url="$(grep -m1 "^[^#].*/main$" "$repos" | sed 's|/main$||')"
        if [[ -n "$main_url" ]]; then
            echo "${main_url}/community" | run_sudo tee -a "$repos" > /dev/null
        fi
    fi

    pkg_update
    log_ok "Repositório community habilitado."
}

# Inicializa detecção automaticamente ao ser sourced
detect_distro
