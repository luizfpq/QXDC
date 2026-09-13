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

    if ! download_file "$url" "$dest" --sudo; then
        log_error "Falha ao baixar wallpaper."
        return 1
    fi

    echo "$dest"
}

# --- Aplicar no desktop XFCE ---
# Estratégia em duas frentes, para funcionar em qualquer máquina:
#   1) Detecta monitores CONECTADOS via xrandr e cria a chave para cada um.
#      Os nomes variam por hardware/driver (eDP-1, HDMI-2, VGA-0, DP-1, LVDS-1...),
#      por isso nunca fixamos nomes — sempre lemos do xrandr em runtime.
#   2) Reescreve QUALQUER chave last-image já existente no canal (cobre perfis de
#      monitor pré-existentes, incluindo workspaces adicionais e o formato legado
#      monitor0/monitor1).
apply_desktop_wallpaper() {
    local wallpaper="$1"
    local applied=0

    log_info "Aplicando wallpaper no desktop: $wallpaper"

    # 1) Monitores conectados (nome = 1º campo da linha " connected").
    #    xrandr não usa espaços em nomes de saída, então o 1º campo é seguro.
    local monitors
    monitors="$(xrandr 2>/dev/null | awk '/ connected/{print $1}')"

    if [[ -n "$monitors" ]]; then
        while IFS= read -r mon; do
            [[ -z "$mon" ]] && continue
            log_info "  Monitor conectado: $mon"
            run xfconf-query -c xfce4-desktop \
                -p "/backdrop/screen0/monitor${mon}/workspace0/last-image" \
                -s "$wallpaper" --create -t string
            run xfconf-query -c xfce4-desktop \
                -p "/backdrop/screen0/monitor${mon}/workspace0/image-style" \
                -s 5 --create -t int
            applied=$((applied + 1))
        done <<< "$monitors"
    else
        log_warn "xrandr não retornou monitores conectados; usando apenas chaves existentes."
    fi

    # 2) Reescrever todas as chaves last-image/image-path já existentes.
    #    Preserva compatibilidade com perfis antigos e workspaces extras.
    local props
    props="$(xfconf-query -c xfce4-desktop --list 2>/dev/null | grep -E 'last-image|image-path' || true)"

    if [[ -n "$props" ]]; then
        while IFS= read -r prop; do
            [[ -z "$prop" ]] && continue
            run xfconf-query -c xfce4-desktop -p "$prop" -s "$wallpaper"
        done <<< "$props"
    fi

    if [[ "$applied" -eq 0 && -z "$props" ]]; then
        # Nenhum monitor detectado e nenhuma chave existente: criar um fallback
        # genérico para que o xfdesktop tenha ao menos um backdrop definido.
        log_warn "Nenhuma chave de monitor encontrada; criando fallback monitor0."
        run xfconf-query -c xfce4-desktop \
            -p "/backdrop/screen0/monitor0/workspace0/last-image" \
            -s "$wallpaper" --create -t string
        run xfconf-query -c xfce4-desktop \
            -p "/backdrop/screen0/monitor0/workspace0/image-style" \
            -s 5 --create -t int
    fi

    # Reload xfdesktop
    xfdesktop --reload 2>/dev/null || true

    log_ok "Wallpaper do desktop aplicado."
}

# --- Aplicar na tela de login (LightDM) ---
apply_login_wallpaper() {
    local wallpaper="$1"
    local greeter_conf="/etc/lightdm/lightdm-gtk-greeter.conf"

    log_info "Aplicando wallpaper na tela de login: $wallpaper"

    # Ler configurações de tema do config (com fallback para defaults)
    local gtk_theme icons font
    gtk_theme="$(config_get "desktop.gtk_theme" "$QXDC_CONFIG")"
    [[ -z "$gtk_theme" ]] && gtk_theme="$(config_get "desktop.gtk_theme" "$QXDC_ROOT/config/defaults.yml")"
    icons="$(config_get "desktop.icons" "$QXDC_CONFIG")"
    [[ -z "$icons" ]] && icons="$(config_get "desktop.icons" "$QXDC_ROOT/config/defaults.yml")"
    font="$(config_get "desktop.font" "$QXDC_CONFIG")"
    [[ -z "$font" ]] && font="$(config_get "desktop.font" "$QXDC_ROOT/config/defaults.yml")"
    gtk_theme="${gtk_theme:-Arc-Lighter}"
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

    # Fallback para defaults se o perfil não define wallpaper
    if [[ -z "$url" ]]; then
        url="$(config_get "desktop.wallpaper_url" "$QXDC_ROOT/config/defaults.yml")"
    fi

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

    # Verificar pré-condições de sessão desktop
    if ! check_desktop_session; then
        log_error "Módulo 'desktop wallpaper' requer sessão XFCE ativa."
        log_error "Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus."
        return 1
    fi

    local wallpaper_path
    wallpaper_path="$(download_wallpaper "$url")" || {
        log_error "Não foi possível obter o wallpaper."
        return 1
    }

    if [[ -z "$wallpaper_path" ]]; then
        log_error "Não foi possível obter o wallpaper."
        return 1
    fi

    apply_desktop_wallpaper "$wallpaper_path"
    apply_login_wallpaper "$wallpaper_path"

    log_ok "Wallpaper configurado com sucesso."
}

main
