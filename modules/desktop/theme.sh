#!/bin/bash
# modules/desktop/theme.sh — Instala e configura tema GTK, ícones e WM
# Tema: Arc (github.com/Eugeny/Arc-theme)
# Ícones: Papirus + papirus-folders (cor configurável)
#
# Uso: ./modules/desktop/theme.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Instalar tema Arc ---
install_arc_theme() {
    log_step "Instalando tema Arc"

    # Verificar se já está instalado
    if [[ -d /usr/share/themes/Arc-Dark ]]; then
        log_info "Tema Arc já está instalado."
        return 0
    fi

    # Instalar via pacote da distro (preferencial)
    # O pacote arc-theme inclui Arc, Arc-Dark, Arc-Darker, Arc-Lighter
    local deps=(arc-theme gnome-themes-extra gtk2-engines-murrine)

    log_info "Instalando arc-theme via apt..."
    for dep in "${deps[@]}"; do
        if ! is_installed "$dep" 2>/dev/null; then
            run_sudo apt-get install -qq -y "$dep"
        fi
    done

    if [[ -d /usr/share/themes/Arc-Dark ]]; then
        log_ok "Tema Arc instalado via pacote."
    else
        log_error "Falha ao instalar tema Arc."
        return 1
    fi
}

# --- Instalar Papirus Icons + papirus-folders ---
install_papirus_icons() {
    log_step "Instalando ícones Papirus"

    if is_installed papirus-icon-theme 2>/dev/null; then
        log_info "papirus-icon-theme já instalado."
    else
        log_info "Instalando papirus-icon-theme via apt..."
        run_sudo apt-get install -qq -y papirus-icon-theme
    fi

    # papirus-folders para customizar cor das pastas
    if command_exists papirus-folders; then
        log_info "papirus-folders já disponível."
    else
        log_info "Instalando papirus-folders..."
        if [[ "$QXDC_DRY_RUN" != "true" ]]; then
            wget -qO- https://git.io/papirus-folders-install | sudo sh >> "$QXDC_LOG" 2>&1
        fi
    fi

    # Aplicar cor configurada
    local color
    color="$(config_get "desktop.papirus_folders_color" "$QXDC_CONFIG")"
    color="${color:-paleorange}"

    log_info "Aplicando cor de pastas: $color"
    run_sudo papirus-folders -C "$color" --theme Papirus-Dark
    log_ok "Papirus configurado com cor $color."
}

# --- Aplicar tema via xfconf ---
apply_xfce_theme() {
    log_step "Aplicando configurações XFCE"

    local gtk_theme wm_theme icons font
    gtk_theme="$(config_get "desktop.gtk_theme" "$QXDC_CONFIG")"
    wm_theme="$(config_get "desktop.wm_theme" "$QXDC_CONFIG")"
    icons="$(config_get "desktop.icons" "$QXDC_CONFIG")"
    font="$(config_get "desktop.font" "$QXDC_CONFIG")"

    gtk_theme="${gtk_theme:-Arc-Dark}"
    wm_theme="${wm_theme:-Arc-Dark}"
    icons="${icons:-Papirus-Dark}"
    font="${font:-Noto Sans 10}"

    # Tema GTK
    log_info "GTK Theme: $gtk_theme"
    run xfconf-query -c xsettings -p /Net/ThemeName -s "$gtk_theme" --create -t string

    # Tema WM (xfwm4)
    log_info "WM Theme: $wm_theme"
    run xfconf-query -c xfwm4 -p /general/theme -s "$wm_theme" --create -t string

    # Ícones
    log_info "Icon Theme: $icons"
    run xfconf-query -c xsettings -p /Net/IconThemeName -s "$icons" --create -t string

    # Fonte
    log_info "Font: $font"
    run xfconf-query -c xsettings -p /Gtk/FontName -s "$font" --create -t string

    log_ok "Configurações XFCE aplicadas."
}

# --- Main ---
main() {
    log_step "Configuração de tema — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        local gtk_theme wm_theme icons color
        gtk_theme="$(config_get "desktop.gtk_theme" "$QXDC_CONFIG")"
        wm_theme="$(config_get "desktop.wm_theme" "$QXDC_CONFIG")"
        icons="$(config_get "desktop.icons" "$QXDC_CONFIG")"
        color="$(config_get "desktop.papirus_folders_color" "$QXDC_CONFIG")"
        log_info "[DRY-RUN] Configurações que seriam aplicadas:"
        echo "  GTK Theme:      ${gtk_theme:-Arc-Dark}"
        echo "  WM Theme:       ${wm_theme:-Arc-Dark}"
        echo "  Icons:          ${icons:-Papirus-Dark}"
        echo "  Folders Color:  ${color:-paleorange}"
        echo "  Source:         github.com/Eugeny/Arc-theme"
        echo "  Papirus:        github.com/PapirusDevelopmentTeam/papirus-folders"
        return 0
    fi

    # Verificar pré-condições de sessão desktop
    if ! check_desktop_session; then
        log_error "Módulo 'desktop theme' requer sessão XFCE ativa."
        log_error "Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus."
        return 1
    fi

    install_arc_theme
    install_papirus_icons
    apply_xfce_theme

    log_ok "Tema configurado com sucesso."
    log_info "Log completo em: $QXDC_LOG"
}

main
