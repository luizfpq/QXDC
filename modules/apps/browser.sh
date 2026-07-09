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
            local tmp_deb="${QXDC_TMPDIR}/google-chrome.deb"
            download_file "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "$tmp_deb" || return 1
            log_info "Instalando .deb..."
            run_sudo apt-get install -qq -y "$tmp_deb"
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

# --- Definir browser padrão ---
set_default_browser() {
    local browser_bin="$1"

    log_step "Definindo $browser_bin como browser padrão"

    # update-alternatives (Debian)
    if command_exists update-alternatives; then
        local bin_path
        bin_path="$(command -v "$browser_bin" 2>/dev/null)"
        if [[ -n "$bin_path" ]]; then
            run_sudo update-alternatives --set x-www-browser "$bin_path" 2>/dev/null || true
            run_sudo update-alternatives --set gnome-www-browser "$bin_path" 2>/dev/null || true
        fi
    fi

    # xdg-settings (funciona sem root, preferido)
    if command_exists xdg-settings; then
        local desktop_file=""
        case "$browser_bin" in
            google-chrome-stable|google-chrome)
                desktop_file="google-chrome.desktop"
                ;;
            firefox-esr)
                desktop_file="firefox-esr.desktop"
                ;;
            firefox)
                desktop_file="firefox.desktop"
                ;;
        esac

        if [[ -n "$desktop_file" ]]; then
            run xdg-settings set default-web-browser "$desktop_file"
        fi
    fi

    log_ok "$browser_bin definido como browser padrão."
}

# --- Tema Arc para Firefox (userChrome.css) ---
apply_firefox_arc_theme() {
    log_step "Aplicando tema Arc ao Firefox"

    # Encontrar perfil Firefox (pode não existir se nunca abriu)
    local firefox_dir="$HOME/.mozilla/firefox"
    if [[ ! -d "$firefox_dir" ]]; then
        log_info "Criando perfil Firefox..."
        timeout 5 firefox-esr --headless 2>/dev/null || true
        sleep 2
    fi

    # Encontrar perfil default
    local profile_dir
    profile_dir="$(find "$firefox_dir" -maxdepth 1 -name "*.default-esr" -o -name "*.default-release" -o -name "*.default" 2>/dev/null | head -1)"

    if [[ -z "$profile_dir" ]]; then
        log_warn "Perfil Firefox não encontrado. Execute o Firefox uma vez primeiro."
        return 0
    fi

    local chrome_dir="$profile_dir/chrome"
    mkdir -p "$chrome_dir"

    # Criar userChrome.css harmonizado com Arc-Lighter
    cat > "$chrome_dir/userChrome.css" << 'CSS'
/* Arc-Lighter Firefox Theme
 * Harmoniza a UI do Firefox com o tema Arc-Lighter do sistema.
 */

:root {
  --arc-bg: #e7e8eb;
  --arc-fg: #2e3440;
  --arc-toolbar: #f5f6f7;
  --arc-border: #cfd6e6;
  --arc-accent: #5294e2;
}

/* Toolbar e tab bar */
#navigator-toolbox {
  background-color: var(--arc-toolbar) !important;
  border-bottom: 1px solid var(--arc-border) !important;
}

/* Tabs */
.tabbrowser-tab .tab-background {
  background-color: var(--arc-bg) !important;
  border: none !important;
}

.tabbrowser-tab[selected] .tab-background {
  background-color: var(--arc-toolbar) !important;
}

/* URL bar */
#urlbar-background {
  background-color: #ffffff !important;
  border: 1px solid var(--arc-border) !important;
}

/* Sidebar */
#sidebar-header {
  background-color: var(--arc-bg) !important;
}
CSS

    # Ativar userChrome.css no user.js
    local user_js="$profile_dir/user.js"
    local needs_write=false

    for pref in \
        'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' \
        'user_pref("browser.display.use_system_colors", true);'; do
        if ! grep -qF "$pref" "$user_js" 2>/dev/null; then
            echo "$pref" >> "$user_js"
            needs_write=true
        fi
    done

    log_ok "Tema Arc-Lighter aplicado ao Firefox."
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

    # Browser theme precisa de sessão de usuário (perfil Firefox, HOME correto)
    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
        log_warn "Rodando como root via sudo. Perfil Firefox será em /root, não em ~$SUDO_USER."
        log_warn "O tema do browser pode não ser aplicado corretamente."
    fi

    # Instalar browser
    case "$browser" in
        firefox-esr|firefox)
            install_firefox
            [[ "$browser_theme" == "arc" ]] && apply_firefox_arc_theme
            set_default_browser "$browser"
            ;;
        google-chrome|chrome)
            install_chrome
            [[ "$browser_theme" == "arc" ]] && chrome_arc_theme_info
            set_default_browser "google-chrome-stable"
            ;;
        *)
            log_info "Instalando $browser via gerenciador de pacotes..."
            pkg_install "$browser"
            ;;
    esac
}

main
