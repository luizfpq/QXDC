#!/bin/bash
# modules/system/printer.sh — Detecção e configuração de impressoras HP (HPLIP)
# Detecta impressoras HP conectadas, instala o HPLIP a partir dos repositórios
# oficiais da distro e habilita o CUPS. Opcionalmente roda hp-setup.
#
# Por que existe:
#   O instalador .run oficial da HP (hplip-*.run) falha em distros modernas
#   (ex.: Debian 13/trixie) tentando instalar o pacote obsoleto python3-pyqt4,
#   entrando num loop de retry infinito. O HPLIP empacotado pela distro é a
#   forma correta, estável e atualizada de instalar — e é o que este módulo usa.
#   NUNCA usamos o .run aqui.
#
# Comportamento:
#   - Detecta impressora HP (USB via lsusb; rede é best-effort)
#   - Avisa o usuário sobre o que foi encontrado
#   - Pede confirmação antes de instalar (respeita --yes)
#   - Instala HPLIP + drivers de impressão da distro, habilita CUPS/Avahi
#   - Oferece rodar hp-setup -i para configurar a fila de impressão
#
# Uso: ./modules/system/printer.sh [--dry-run] [--yes] [--verbose] [--profile <nome>] [--setup]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

# --- Flags ---
PROFILE="minimal"
RUN_SETUP=false   # --setup força oferecer hp-setup mesmo sem TTY interativo
HP_MATCH_ID=""    # preenchido por detect_hp_usb com o ID USB da impressora HP

parse_common_flags "$@"
set -- "${QXDC_REMAINING_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift ;;
        --setup)   RUN_SETUP=true ;;
        *) log_error "Flag desconhecida: $1"; exit 1 ;;
    esac
    shift
done

# --- Pacotes HPLIP por família de distro ---
# Retorna a lista de pacotes via nameref.
# Uso: local -a pkgs; hplip_packages pkgs
hplip_packages() {
    # shellcheck disable=SC2178
    local -n _arr="${1:-_hplip_pkgs}"
    case "$DISTRO_FAMILY" in
        debian)
            # hplip: drivers de impressão/scan; hplip-gui: hp-toolbox (Qt5, moderno);
            # printer-driver-postscript-hp: PPDs PostScript; cups: servidor de impressão.
            _arr=(hplip hplip-gui printer-driver-postscript-hp cups)
            ;;
        alpine)
            # No Alpine o pacote é 'hplip'; cups separado.
            _arr=(hplip cups)
            ;;
        arch)
            _arr=(hplip cups)
            ;;
        redhat)
            _arr=(hplip cups)
            ;;
        *)
            _arr=(hplip cups)
            ;;
    esac
}

# --- Detecção de impressora HP (USB) ---
# Cuidado: a HP (vendor 03f0) também fabrica mouses/teclados/webcams, então
# NÃO basta casar o vendor. Confirmamos que o dispositivo expõe a classe USB
# de impressora (bInterfaceClass 7) via 'lsusb -v'. Fallback: heurística por nome.
detect_hp_usb() {
    command_exists lsusb || return 1

    # IDs de dispositivos HP presentes no barramento.
    local hp_ids
    hp_ids="$(lsusb 2>/dev/null | grep -iE "hewlett|hp,? inc|03f0:" | grep -oE "03f0:[0-9a-fA-F]{4}")"
    [[ -z "$hp_ids" ]] && return 1

    # Para cada dispositivo HP, checar se tem interface de classe 7 (Printer).
    local id
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        if lsusb -v -d "$id" 2>/dev/null | grep -qiE "bInterfaceClass[[:space:]]+7"; then
            HP_MATCH_ID="$id"
            return 0
        fi
        # Alguns modelos só descrevem "Printer" na string do produto.
        if lsusb -v -d "$id" 2>/dev/null | grep -qiE "iProduct.*printer|iInterface.*printer"; then
            HP_MATCH_ID="$id"
            return 0
        fi
    done <<< "$hp_ids"

    return 1
}

# --- Detecção genérica de impressora (qualquer fabricante, best-effort) ---
detect_any_printer() {
    if command_exists lpstat && lpstat -p >/dev/null 2>&1; then
        if lpstat -p 2>/dev/null | grep -qi "printer"; then
            return 0
        fi
    fi
    return 1
}

# --- Obter modelo da impressora HP (best-effort) ---
get_hp_model() {
    if command_exists lsusb && [[ -n "${HP_MATCH_ID:-}" ]]; then
        lsusb 2>/dev/null | grep -i "$HP_MATCH_ID" | head -1 | sed 's/.*'"$HP_MATCH_ID"' //'
    elif command_exists lsusb; then
        lsusb 2>/dev/null | grep -iE "hewlett|hp,? inc|03f0:" | head -1 | sed 's/.*: //'
    else
        echo "Impressora HP (modelo desconhecido)"
    fi
}

# --- Instalar HPLIP + drivers ---
install_hplip() {
    log_step "Instalando HPLIP (repositórios oficiais da distro)"

    # Debian: garantir estado saudável do apt antes (resíduo de instaladores manuais).
    if [[ "$DISTRO_FAMILY" == "debian" ]]; then
        check_apt_health || log_warn "apt com pendências; seguindo mesmo assim."
    fi

    local -a pkgs=()
    hplip_packages pkgs
    log_info "Pacotes: ${pkgs[*]}"

    pkg_install "${pkgs[@]}"

    # Habilitar CUPS (systemd ou OpenRC).
    enable_printing_services

    log_ok "HPLIP instalado."
    log_info "Nunca use o instalador hplip-*.run em distros modernas: ele falha"
    log_info "tentando instalar python3-pyqt4 (obsoleto). Este módulo usa o pacote da distro."
}

# --- Habilitar serviços de impressão (CUPS + Avahi) ---
enable_printing_services() {
    if command_exists systemctl; then
        log_info "Habilitando CUPS (systemd)..."
        run_sudo systemctl enable --now cups 2>/dev/null \
            || log_warn "Não consegui habilitar cups via systemctl."
        run_sudo systemctl enable --now avahi-daemon 2>/dev/null \
            || log_warn "avahi-daemon não habilitado (descoberta de impressoras de rede)."
    elif command_exists rc-update; then
        # Alpine / OpenRC
        log_info "Habilitando CUPS (OpenRC)..."
        run_sudo rc-update add cupsd default 2>/dev/null || log_warn "rc-update cupsd falhou."
        run_sudo rc-service cupsd start 2>/dev/null || log_warn "rc-service cupsd start falhou."
        run_sudo rc-update add avahi-daemon default 2>/dev/null || true
        run_sudo rc-service avahi-daemon start 2>/dev/null || true
    else
        log_warn "Gerenciador de serviços não reconhecido; inicie o CUPS manualmente."
    fi

    # Adicionar o usuário ao grupo lp (acesso à impressora).
    local target_user="${SUDO_USER:-$USER}"
    if id -nG "$target_user" 2>/dev/null | grep -qw lp; then
        [[ "$QXDC_VERBOSE" == "true" ]] && log_info "Usuário '$target_user' já está no grupo 'lp'."
    else
        if run_sudo usermod -aG lp "$target_user" 2>/dev/null; then
            log_ok "Usuário '$target_user' adicionado ao grupo 'lp' (efeito após novo login)."
        else
            log_warn "Não consegui adicionar '$target_user' ao grupo 'lp'."
        fi
    fi
}

# --- Oferecer configuração da impressora (hp-setup) ---
offer_hp_setup() {
    if ! command_exists hp-setup; then
        log_warn "hp-setup não encontrado; instalação do HPLIP pode ter falhado."
        return 0
    fi

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Ofereceria rodar 'hp-setup -i' para configurar a impressora."
        return 0
    fi

    echo ""
    log_info "Para configurar a fila de impressão, com a impressora ligada e conectada:"
    log_info "  hp-setup -i    (assistente no terminal)"
    log_info "  hp-setup       (assistente gráfico, se houver sessão gráfica)"
    echo ""

    # Só rodar automaticamente se houver TTY interativo ou --setup explícito.
    if [[ "$RUN_SETUP" != "true" && ! -t 0 ]]; then
        return 0
    fi

    if confirm "Rodar 'hp-setup -i' agora?"; then
        # hp-setup NÃO deve rodar como root; rodar como o usuário real.
        if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
            run sudo -u "$SUDO_USER" hp-setup -i
        else
            run hp-setup -i
        fi
    else
        log_info "Configuração adiada. Rode 'hp-setup -i' quando quiser."
    fi
}

# --- Main ---
main() {
    log_step "Configuração de impressora HP (HPLIP) — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    local found_hp=false

    log_info "Verificando impressora HP via USB..."
    if detect_hp_usb; then
        found_hp=true
        log_ok "Impressora HP detectada: $(get_hp_model)"
    else
        log_info "Nenhuma impressora HP USB detectada."
        if detect_any_printer; then
            log_info "Há filas de impressão configuradas, mas nenhuma HP via USB agora."
        fi
    fi

    # Se HPLIP já está instalado, ainda vale garantir serviços e oferecer setup.
    local hplip_present=false
    is_installed hplip 2>/dev/null && hplip_present=true

    # --- Nada detectado e HPLIP ausente ---
    if [[ "$found_hp" == "false" && "$hplip_present" == "false" ]]; then
        log_info "Nenhuma impressora HP detectada e HPLIP não instalado."
        log_info "Conecte a impressora HP e rode novamente, ou force com --yes."
        if [[ "$QXDC_YES" != "true" ]]; then
            return 0
        fi
        log_warn "--yes ativo: instalando HPLIP mesmo sem detecção."
    fi

    # --- Dry-run: apenas reportar ---
    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        local -a pkgs=()
        hplip_packages pkgs
        log_info "[DRY-RUN] Instalaria: ${pkgs[*]}"
        log_info "[DRY-RUN] Habilitaria CUPS/Avahi e adicionaria usuário ao grupo lp."
        offer_hp_setup
        return 0
    fi

    # --- Instalar (ou confirmar já instalado) ---
    if [[ "$hplip_present" == "true" ]]; then
        log_info "HPLIP já instalado. Garantindo serviços de impressão..."
        enable_printing_services
    else
        echo ""
        log_info "Será instalado o HPLIP oficial da distro (drivers de impressão/scan HP)."
        log_info "Isso substitui com segurança o instalador hplip-*.run, que falha aqui."
        echo ""
        if confirm "Instalar HPLIP e habilitar o CUPS?"; then
            install_hplip
        else
            log_info "Instalação de impressora ignorada pelo usuário."
            return 0
        fi
    fi

    # --- Oferecer configuração ---
    offer_hp_setup

    log_ok "Módulo de impressora concluído."
}

main
