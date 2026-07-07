#!/bin/bash
# modules/desktop/wallpaper.sh — Configura wallpaper do desktop e tela de login
# Baixa de URL configurada e aplica em XFCE + LightDM greeter.
#
# Uso: ./modules/desktop/wallpaper.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

WALLPAPER_DIR="/usr/share/backgrounds/qxdc"

# --- Download do wallpaper ---
download_wallpaper() {
    local url="$1"
    local filename
    filename="$(basename "$url")"
    local dest="$WALLPAPER_DIR/$filename"

    if [[ -f "$dest" ]]; then
        log_info "Wallpaper já existe: $dest"
        echo "$dest"
        return 0
    fi

    run_sudo mkdir -p "$WALLPAPER_DIR"
    log_info "Baixando wallpaper: $url"
    run_sudo wget -q -O "$dest" "$url"

    if [[ -f "$dest" ]]; then
        echo "$dest"
    else
        log_error "Falha ao baixar wallpaper."
        return 1
    fi
}

# --- Aplicar no desktop XFCE ---
apply_desktop_wallpaper() {
    local wallpaper="$1"

    log_info "Aplicando wallpaper no desktop: $wallpaper"

    # Setar para todos os monitores
    local props
    props="$(xfconf-query -c xfce4-desktop --list 2>/dev/null | grep -E 'last-image|image-path')"

    if [[ -n "$props" ]]; then
        while IFS= read -r prop; do
            run xfconf-query -c xfce4-desktop -p "$prop" -s "$wallpaper"
        done <<< "$props"
    else
        # Criar propriedades padrão se não existirem
        run xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "$wallpaper" --create -t string
        run xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/last-image -s "$wallpaper" --create -t string
    fi

    log_ok "Wallpaper do desktop aplicado."
}

# --- Aplicar na tela de login (LightDM) ---
apply_login_wallpaper() {
    local wallpaper="$1"
    local greeter_conf="/etc/lightdm/lightdm-gtk-greeter.conf"

    log_info "Aplicando wallpaper na tela de login: $wallpaper"

    # Ler configurações de tema do config
    local gtk_theme icons font
    gtk_theme="$(config_get "desktop.gtk_theme" "$QXDC_CONFIG")"
    icons="$(config_get "desktop.icons" "$QXDC_CONFIG")"
    font="$(config_get "desktop.font" "$QXDC_CONFIG")"
    gtk_theme="${gtk_theme:-Arc-Dark}"
    icons="${icons:-Papirus-Dark}"
    font="${font:-Noto Sans 10}"

    run_sudo bash -c "cat > '$greeter_conf' << GREETER
[greeter]
background=$wallpaper
user-background=false
theme-name=$gtk_theme
icon-theme-name=$icons
font-name=$font
GREETER"

    log_ok "Wallpaper da tela de login aplicado."
}

# --- Main ---
main() {
    log_step "Configuração de wallpaper — perfil: $PROFILE"

    load_profile "$PROFILE"

    local url
    url="$(config_get "desktop.wallpaper_url" "$QXDC_CONFIG")"

    if [[ -z "$url" ]]; then
        log_warn "Nenhuma URL de wallpaper definida em desktop.wallpaper_url"
        return 0
    fi

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Wallpaper que seria aplicado:"
        echo "  URL:    $url"
        echo "  Dest:   $WALLPAPER_DIR/$(basename "$url")"
        echo "  Desktop: sim (xfce4-desktop)"
        echo "  Login:   sim (lightdm-gtk-greeter)"
        return 0
    fi

    local wallpaper_path
    wallpaper_path="$(download_wallpaper "$url")"

    if [[ -z "$wallpaper_path" ]]; then
        log_error "Não foi possível obter o wallpaper."
        return 1
    fi

    apply_desktop_wallpaper "$wallpaper_path"
    apply_login_wallpaper "$wallpaper_path"

    log_ok "Wallpaper configurado com sucesso."
}

main
