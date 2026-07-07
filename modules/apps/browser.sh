#!/bin/bash
# modules/apps/browser.sh — Instala browser e configura tema Arc
# Suporta: firefox-esr, google-chrome
# Tema Arc para Firefox: via userChrome.css (Arc-firefox-theme)
# Tema Arc para Chrome: instalação via extensão (informativo)
#
# Uso: ./modules/apps/browser.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Instalar Firefox ESR ---
install_firefox() {
    log_step "Instalando Firefox ESR"

    if command_exists firefox-esr || command_exists firefox; then
        log_info "Firefox já instalado."
        return 0
    fi

    pkg_install firefox-esr
}

# --- Instalar Google Chrome ---
install_chrome() {
    log_step "Instalando Google Chrome"

    if command_exists google-chrome-stable || command_exists google-chrome; then
        log_info "Google Chrome já instalado."
        return 0
    fi

    case "$DISTRO_FAMILY" in
        debian)
            log_info "Baixando Google Chrome..."
            run wget -q -O /tmp/google-chrome.deb \
                "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            log_info "Instalando .deb..."
            run_sudo apt-get install -qq -y /tmp/google-chrome.deb
            run rm -f /tmp/google-chrome.deb
            ;;
        arch)
            if command_exists yay; then
                run yay -S --noconfirm google-chrome
            else
                log_error "AUR helper necessário para Chrome no Arch."
                return 1
            fi
            ;;
        *)
            log_error "Instalação do Chrome não suportada em $DISTRO_FAMILY."
            return 1
            ;;
    esac

    log_ok "Google Chrome instalado."
}

# --- Tema Arc para Firefox (userChrome.css) ---
apply_firefox_arc_theme() {
    log_step "Aplicando tema Arc ao Firefox"

    # Encontrar perfil Firefox (pode não existir se nunca abriu)
    local firefox_dir="$HOME/.mozilla/firefox"
    if [[ ! -d "$firefox_dir" ]]; then
        log_warn "Diretório Firefox não encontrado. Inicie o Firefox uma vez e re-execute."
        log_info "Alternativa: instale manualmente o Arc-firefox-theme após primeiro uso."
        return 0
    fi

    # Encontrar perfil default
    local profile_dir
    profile_dir="$(find "$firefox_dir" -maxdepth 1 -name "*.default-esr" -o -name "*.default-release" -o -name "*.default" | head -1)"

    if [[ -z "$profile_dir" ]]; then
        log_warn "Perfil Firefox não encontrado. Execute o Firefox uma vez primeiro."
        return 0
    fi

    local chrome_dir="$profile_dir/chrome"
    mkdir -p "$chrome_dir"

    # Clonar tema Arc para Firefox
    local arc_ff_dir="/tmp/arc-firefox-theme"
    run rm -rf "$arc_ff_dir"
    log_info "Clonando Arc-firefox-theme..."
    run git clone --depth 1 https://github.com/nickcz/Arc-firefox-theme.git "$arc_ff_dir"

    if [[ -f "$arc_ff_dir/userChrome.css" ]]; then
        run cp "$arc_ff_dir/userChrome.css" "$chrome_dir/userChrome.css"
        log_ok "userChrome.css instalado em $chrome_dir"
    elif [[ -d "$arc_ff_dir/Arc-Dark" ]]; then
        run cp "$arc_ff_dir/Arc-Dark/userChrome.css" "$chrome_dir/userChrome.css" 2>/dev/null || true
        log_ok "userChrome.css (Arc-Dark) instalado."
    else
        log_warn "Estrutura do Arc-firefox-theme mudou. Verifique manualmente."
    fi

    run rm -rf "$arc_ff_dir"

    # Ativar userChrome.css no about:config
    local prefs_file="$profile_dir/user.js"
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$prefs_file" 2>/dev/null; then
        echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$prefs_file"
        log_info "Habilitado toolkit.legacyUserProfileCustomizations.stylesheets no user.js"
    fi

    log_ok "Tema Arc aplicado ao Firefox."
    log_info "Reinicie o Firefox para ver as mudanças."
}

# --- Info sobre tema Arc para Chrome ---
chrome_arc_theme_info() {
    log_step "Tema Arc para Google Chrome"
    log_info "Para aplicar o tema Arc ao Chrome, instale a extensão:"
    log_info "  https://chrome.google.com/webstore/detail/arc-dark/adicoenigffoolephelklheejpcpoolk"
    log_info "Ou use o GTK theme matching nativo:"
    log_info "  chrome://flags/#gtk-theme → Enabled"
    log_info "  O Chrome usará automaticamente o tema Arc-Dark do sistema."
    log_ok "Com Arc-Dark como tema GTK, o Chrome já herda a aparência."
}

# --- Main ---
main() {
    log_step "Instalação de browser — perfil: $PROFILE"

    load_profile "$PROFILE"

    local browser browser_theme
    browser="$(config_get "apps.browser" "$QXDC_CONFIG")"
    browser_theme="$(config_get "apps.browser_theme" "$QXDC_CONFIG")"
    browser="${browser:-firefox-esr}"
    browser_theme="${browser_theme:-arc}"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Browser: $browser"
        log_info "[DRY-RUN] Browser theme: $browser_theme"
        return 0
    fi

    # Instalar browser
    case "$browser" in
        firefox-esr|firefox)
            install_firefox
            [[ "$browser_theme" == "arc" ]] && apply_firefox_arc_theme
            ;;
        google-chrome|chrome)
            install_chrome
            [[ "$browser_theme" == "arc" ]] && chrome_arc_theme_info
            ;;
        *)
            log_info "Instalando $browser via gerenciador de pacotes..."
            pkg_install "$browser"
            ;;
    esac
}

main
