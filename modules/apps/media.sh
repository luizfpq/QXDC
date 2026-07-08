#!/bin/bash
# modules/apps/media.sh — Instala player de vídeo e define como padrão
# Suporta: vlc, celluloid, mpv
#
# Uso: ./modules/apps/media.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Instalar VLC ---
install_vlc() {
    log_step "Instalando VLC"

    if command_exists vlc; then
        log_info "VLC já instalado."
        return 0
    fi

    pkg_install vlc
    log_ok "VLC instalado."
}

# --- Instalar Celluloid (GTK frontend para mpv) ---
install_celluloid() {
    log_step "Instalando Celluloid"

    if command_exists celluloid; then
        log_info "Celluloid já instalado."
        return 0
    fi

    pkg_install celluloid
    log_ok "Celluloid instalado."
}

# --- Instalar mpv ---
install_mpv() {
    log_step "Instalando mpv"

    if command_exists mpv; then
        log_info "mpv já instalado."
        return 0
    fi

    pkg_install mpv
    log_ok "mpv instalado."
}

# --- Definir player como padrão para vídeo ---
set_default_player() {
    local player="$1"
    local desktop_file=""

    log_step "Definindo $player como player de vídeo padrão"

    case "$player" in
        vlc)         desktop_file="vlc.desktop" ;;
        celluloid)   desktop_file="io.github.celluloid_player.Celluloid.desktop" ;;
        mpv)         desktop_file="mpv.desktop" ;;
        *)           desktop_file="${player}.desktop" ;;
    esac

    if ! command_exists xdg-mime; then
        log_warn "xdg-mime não disponível. Associações de mídia não configuradas."
        return 0
    fi

    local mime_types=(
        video/mp4
        video/x-matroska
        video/webm
        video/x-msvideo
        video/x-flv
        video/quicktime
        video/mpeg
        video/ogg
        video/x-ogm+ogg
    )

    for mime in "${mime_types[@]}"; do
        run xdg-mime default "$desktop_file" "$mime"
    done

    log_ok "$player definido como player padrão para vídeo."
}

# --- Main ---
main() {
    log_step "Instalação de media player — perfil: $PROFILE"

    load_profile "$PROFILE"

    local player
    player="$(config_get "apps.media_player" "$QXDC_CONFIG")"
    player="${player:-vlc}"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Media player: $player"
        return 0
    fi

    # Instalar player
    case "$player" in
        vlc)
            install_vlc
            ;;
        celluloid)
            install_celluloid
            ;;
        mpv)
            install_mpv
            ;;
        *)
            log_info "Instalando $player via gerenciador de pacotes..."
            pkg_install "$player"
            ;;
    esac

    set_default_player "$player"
}

main
