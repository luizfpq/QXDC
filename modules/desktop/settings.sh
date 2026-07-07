#!/bin/bash
# modules/desktop/settings.sh — Configurações de comportamento do desktop XFCE
# Workspaces, Thunar, atalhos, etc.
#
# Uso: ./modules/desktop/settings.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Workspaces ---
configure_workspaces() {
    local count
    count="$(config_get "desktop.workspaces" "$QXDC_CONFIG")"
    count="${count:-1}"

    log_info "Espaços de trabalho: $count"
    run xfconf-query -c xfwm4 -p /general/workspace_count -s "$count" --create -t int
}

# --- Menu de aplicativos (Whisker Menu) ---
configure_app_menu() {
    local menu
    menu="$(config_get "desktop.app_menu" "$QXDC_CONFIG")"
    menu="${menu:-whiskermenu}"

    log_info "Menu de aplicativos: $menu"

    # Verifica se whiskermenu está instalado
    if [[ "$menu" == "whiskermenu" ]]; then
        if ! is_installed xfce4-whiskermenu-plugin 2>/dev/null; then
            log_info "Instalando xfce4-whiskermenu-plugin..."
            run_sudo apt-get install -qq -y xfce4-whiskermenu-plugin
        fi
    fi

    # Substituir plugin-1 (primeiro item do painel) pelo menu escolhido
    run xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s "$menu" --create -t string
}

# --- Menu de clique direito na área de trabalho ---
configure_desktop_menu() {
    local show_menu
    show_menu="$(config_get "desktop.desktop_right_click_menu" "$QXDC_CONFIG")"
    show_menu="${show_menu:-false}"

    log_info "Menu clique direito desktop: $show_menu"
    run xfconf-query -c xfce4-desktop -p /desktop-menu/show -s "$show_menu" --create -t bool
}

# --- Painel 2: transparência ---
configure_panel2() {
    local alpha
    alpha="$(config_get "desktop.panel2_background_alpha" "$QXDC_CONFIG")"
    alpha="${alpha:-12}"

    # XFCE 4.20: background-style=1 (cor sólida) + background-rgba com alpha
    local alpha_dec
    alpha_dec="$(echo "scale=2; $alpha / 100" | bc)"

    log_info "Painel 2 background: cor sólida, alpha ${alpha}% (${alpha_dec})"
    run xfconf-query -c xfce4-panel -p /panels/panel-2/background-style -s 1 --create -t uint
    run xfconf-query -c xfce4-panel -p /panels/panel-2/background-rgba \
        -s 1.0 -s 1.0 -s 1.0 -s "$alpha_dec" --create -t double -t double -t double -t double
}

# --- Ícones da área de trabalho ---
configure_desktop_icons() {
    local show_home show_trash show_filesystem show_removable
    show_home="$(config_get "desktop.icons_show_home" "$QXDC_CONFIG")"
    show_trash="$(config_get "desktop.icons_show_trash" "$QXDC_CONFIG")"
    show_filesystem="$(config_get "desktop.icons_show_filesystem" "$QXDC_CONFIG")"
    show_removable="$(config_get "desktop.icons_show_removable" "$QXDC_CONFIG")"

    show_home="${show_home:-false}"
    show_trash="${show_trash:-false}"
    show_filesystem="${show_filesystem:-false}"
    show_removable="${show_removable:-true}"

    log_info "Ícones desktop: home=$show_home trash=$show_trash filesystem=$show_filesystem removable=$show_removable"
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s "$show_home" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s "$show_trash" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s "$show_filesystem" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s "$show_removable" --create -t bool
}

# --- Thunar ---
configure_thunar() {
    local location_bar
    location_bar="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
    location_bar="${location_bar:-ThunarLocationButtons}"

    log_info "Thunar location bar: $location_bar"

    # XFCE 4.18+: Thunar usa xfconf (canal thunar)
    run xfconf-query -c thunar -p /last-location-bar -s "$location_bar" --create -t string
}

# --- Main ---
main() {
    log_step "Configurações de desktop — perfil: $PROFILE"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        local ws tb menu desktop_menu
        ws="$(config_get "desktop.workspaces" "$QXDC_CONFIG")"
        tb="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
        menu="$(config_get "desktop.app_menu" "$QXDC_CONFIG")"
        desktop_menu="$(config_get "desktop.desktop_right_click_menu" "$QXDC_CONFIG")"
        log_info "[DRY-RUN] Configurações que seriam aplicadas:"
        echo "  Workspaces:              ${ws:-1}"
        echo "  Thunar location bar:     ${tb:-ThunarLocationButtons}"
        echo "  App menu (painel):       ${menu:-whiskermenu}"
        echo "  Right-click desktop menu: ${desktop_menu:-false}"
        echo "  Desktop icons:           home=false trash=false filesystem=false removable=true"
        return 0
    fi

    configure_workspaces
    configure_app_menu
    configure_desktop_menu
    configure_desktop_icons
    configure_panel2
    configure_thunar

    # Restart panel para aplicar mudanças
    xfce4-panel --restart 2>/dev/null &

    log_ok "Configurações de desktop aplicadas."
}

main
