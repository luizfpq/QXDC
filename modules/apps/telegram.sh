#!/bin/bash
# modules/apps/telegram.sh — Instala Telegram Desktop (binário oficial)
# Método: download do tar.xz oficial → extrai em /opt/Telegram/ → symlink + .desktop
#
# O Telegram Desktop distribui um binário estático para Linux x86_64.
# Não depende de repos externos, flatpak ou snap.
# O updater interno mantém o app atualizado após a instalação inicial.
#
# Uso: ./modules/apps/telegram.sh [--dry-run] [--yes] [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

# --- Flags ---
parse_common_flags "$@"
set -- "${QXDC_REMAINING_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        *) log_error "Flag desconhecida: $1"; exit 1 ;;
    esac
    shift
done

# --- Config ---
TELEGRAM_URL="https://telegram.org/dl/desktop/linux"
INSTALL_DIR="/opt/Telegram"
SYMLINK="/usr/local/bin/telegram-desktop"
DESKTOP_FILE="/usr/share/applications/telegram-desktop.desktop"

# --- Instalar Telegram ---
install_telegram() {
    log_step "Instalando Telegram Desktop"

    # Verificar se já está instalado
    if [[ -x "$INSTALL_DIR/Telegram" ]]; then
        local version_info
        version_info="$("$INSTALL_DIR/Telegram" --version 2>/dev/null || echo "instalado")"
        log_info "Telegram Desktop já instalado: $version_info"
        log_info "O updater interno mantém o app atualizado."
        return 0
    fi

    if command_exists telegram-desktop; then
        log_info "telegram-desktop já disponível no PATH."
        return 0
    fi

    # Download
    local tmp_tar="${QXDC_TMPDIR}/telegram.tar.xz"

    log_info "Baixando Telegram Desktop (binário oficial)..."
    download_file "$TELEGRAM_URL" "$tmp_tar" || return 1

    # Validar que é um tar válido
    if ! file "$tmp_tar" | grep -qi "xz\|tar"; then
        log_error "Arquivo baixado não é um tar.xz válido."
        return 1
    fi

    # Extrair
    log_info "Extraindo em $INSTALL_DIR..."
    run_sudo rm -rf "$INSTALL_DIR"
    run_sudo mkdir -p "$INSTALL_DIR"
    run_sudo tar -xJf "$tmp_tar" -C /opt/ || {
        log_error "Falha ao extrair o tar.xz."
        return 1
    }

    # O tar extrai como /opt/Telegram/ com o binário "Telegram" dentro
    if [[ ! -x "$INSTALL_DIR/Telegram" ]]; then
        log_error "Binário não encontrado em $INSTALL_DIR/Telegram após extração."
        log_info "Conteúdo de /opt/Telegram:"
        ls -la "$INSTALL_DIR" 2>/dev/null || true
        return 1
    fi

    log_ok "Telegram Desktop extraído em $INSTALL_DIR."
}

# --- Criar symlink ---
create_symlink() {
    log_step "Criando symlink: $SYMLINK"

    if [[ -L "$SYMLINK" || -e "$SYMLINK" ]]; then
        run_sudo rm -f "$SYMLINK"
    fi

    run_sudo ln -sf "$INSTALL_DIR/Telegram" "$SYMLINK"
    log_ok "Symlink criado: $SYMLINK → $INSTALL_DIR/Telegram"
}

# --- Criar .desktop entry ---
create_desktop_entry() {
    log_step "Criando entrada no menu de aplicativos"

    run_sudo tee "$DESKTOP_FILE" > /dev/null << 'DESKTOP'
[Desktop Entry]
Version=1.0
Name=Telegram Desktop
Comment=Official Telegram Desktop client
Exec=/opt/Telegram/Telegram -- %u
Icon=telegram
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Chat;Network;InstantMessaging;
MimeType=x-scheme-handler/tg;
Keywords=tg;chat;im;messaging;messenger;sms;
DESKTOP

    # Atualizar cache de .desktop
    if command_exists update-desktop-database; then
        run_sudo update-desktop-database /usr/share/applications 2>/dev/null || true
    fi

    log_ok "Entrada .desktop criada: $DESKTOP_FILE"
}

# --- Main ---
main() {
    log_step "Instalação do Telegram Desktop"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Telegram Desktop — método: binário oficial (tar.xz)"
        log_info "[DRY-RUN] URL: $TELEGRAM_URL"
        log_info "[DRY-RUN] Destino: $INSTALL_DIR/Telegram"
        log_info "[DRY-RUN] Symlink: $SYMLINK"
        log_info "[DRY-RUN] Desktop entry: $DESKTOP_FILE"
        return 0
    fi

    install_telegram || exit 1
    create_symlink
    create_desktop_entry

    log_ok "Telegram Desktop pronto. Execute: telegram-desktop"
}

main
