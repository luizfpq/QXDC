#!/bin/bash
# modules/apps/editor.sh — Instala editor de código (VSCode por padrão)
# Uso: ./modules/apps/editor.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Instalar VSCode ---
install_vscode() {
    log_step "Instalando Visual Studio Code"

    if command_exists code; then
        log_info "VSCode já instalado ($(code --version 2>/dev/null | head -1))."
        return 0
    fi

    case "$DISTRO_FAMILY" in
        debian)
            log_info "Adicionando repositório Microsoft..."
            run_sudo apt-get install -qq -y wget gpg apt-transport-https

            run bash -c "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg"
            run_sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

            run_sudo bash -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

            log_info "Atualizando índice..."
            run_sudo apt-get update -qq

            log_info "Instalando code..."
            run_sudo apt-get install -qq -y code

            run rm -f /tmp/packages.microsoft.gpg
            ;;
        arch)
            if command_exists yay; then
                run yay -S --noconfirm visual-studio-code-bin
            else
                log_error "AUR helper (yay) necessário para instalar VSCode no Arch."
                return 1
            fi
            ;;
        *)
            log_error "Instalação de VSCode não suportada para $DISTRO_FAMILY."
            return 1
            ;;
    esac

    if command_exists code; then
        log_ok "VSCode instalado com sucesso."
    else
        log_error "Falha na instalação do VSCode."
        return 1
    fi
}

# --- Main ---
main() {
    log_step "Instalação de editor — perfil: $PROFILE"

    load_profile "$PROFILE"

    local editor
    editor="$(config_get "apps.editor" "$QXDC_CONFIG")"
    editor="${editor:-code}"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Editor que seria instalado: $editor"
        return 0
    fi

    case "$editor" in
        code|vscode)
            install_vscode
            ;;
        *)
            log_warn "Editor '$editor' não tem instalador dedicado. Tentando via pkg_install..."
            pkg_install "$editor"
            ;;
    esac
}

main
