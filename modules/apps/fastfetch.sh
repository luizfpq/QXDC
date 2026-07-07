#!/bin/bash
# modules/apps/fastfetch.sh — Instala e configura fastfetch com logo customizado
# Uso: ./modules/apps/fastfetch.sh [--dry-run] [--yes] [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"

# --- Flags ---
parse_common_flags "$@"

# --- Main ---
main() {
    log_step "Instalação e configuração do fastfetch"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Seria instalado: fastfetch"
        log_info "[DRY-RUN] Config: ~/.config/fastfetch/config.jsonc"
        log_info "[DRY-RUN] Logo: ~/.config/fastfetch/logo.txt (ASCII art QXDC)"
        return 0
    fi

    # Instalar fastfetch
    if command_exists fastfetch; then
        log_info "fastfetch já instalado ($(fastfetch --version 2>/dev/null | head -1))."
    else
        log_info "Instalando fastfetch..."
        case "$DISTRO_FAMILY" in
            debian)
                # Debian 13+ tem fastfetch nos repos
                if run_sudo apt-get install -qq -y fastfetch; then
                    log_ok "fastfetch instalado via apt."
                else
                    # Fallback: instalar via release do GitHub
                    log_info "Tentando instalar via GitHub release..."
                    local arch
                    arch="$(dpkg --print-architecture)"
                    local url="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${arch}.deb"
                    run wget -q -O /tmp/fastfetch.deb "$url"
                    run_sudo dpkg -i /tmp/fastfetch.deb
                    run_sudo apt-get install -f -qq -y
                    rm -f /tmp/fastfetch.deb
                    log_ok "fastfetch instalado via GitHub release."
                fi
                ;;
            arch)
                run_sudo pacman -S --noconfirm fastfetch
                log_ok "fastfetch instalado."
                ;;
            *)
                log_error "Instalação de fastfetch não suportada em $DISTRO_FAMILY."
                return 1
                ;;
        esac
    fi

    # Deploy da configuração
    local config_dir="$HOME/.config/fastfetch"
    local dotfiles_dir="$QXDC_ROOT/modules/dotfiles/files/fastfetch"

    mkdir -p "$config_dir"

    log_info "Copiando configuração..."
    cp "$dotfiles_dir/config.jsonc" "$config_dir/config.jsonc"
    cp "$dotfiles_dir/logo.txt" "$config_dir/logo.txt"

    log_ok "fastfetch configurado."
    log_info "Execute 'fastfetch' para ver o resultado."

    # Mostrar preview
    if command_exists fastfetch; then
        echo ""
        fastfetch
    fi
}

main
