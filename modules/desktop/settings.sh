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

# --- Thunar ---
configure_thunar() {
    local location_bar
    location_bar="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
    location_bar="${location_bar:-ThunarLocationButtons}"

    log_info "Thunar location bar: $location_bar"

    local thunarrc="$HOME/.config/Thunar/thunarrc"
    mkdir -p "$(dirname "$thunarrc")"

    if [[ -f "$thunarrc" ]]; then
        if grep -q "^last-location-bar=" "$thunarrc"; then
            run sed -i "s/^last-location-bar=.*/last-location-bar=$location_bar/" "$thunarrc"
        else
            run bash -c "echo 'last-location-bar=$location_bar' >> '$thunarrc'"
        fi
    else
        run bash -c "echo '[Configuration]' > '$thunarrc' && echo 'last-location-bar=$location_bar' >> '$thunarrc'"
    fi
}

# --- Main ---
main() {
    log_step "Configurações de desktop — perfil: $PROFILE"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        local ws tb
        ws="$(config_get "desktop.workspaces" "$QXDC_CONFIG")"
        tb="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
        log_info "[DRY-RUN] Configurações que seriam aplicadas:"
        echo "  Workspaces:          ${ws:-1}"
        echo "  Thunar location bar: ${tb:-ThunarLocationButtons}"
        return 0
    fi

    configure_workspaces
    configure_thunar

    log_ok "Configurações de desktop aplicadas."
}

main
