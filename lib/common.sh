#!/bin/bash
# lib/common.sh — Funções compartilhadas do QXDC 2.0
# Sourced by modules — não executar diretamente.

set -euo pipefail

# --- Variáveis globais ---
QXDC_VERSION="2.0.0-dev"
QXDC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QXDC_LOG="${QXDC_LOG:-/tmp/qxdc-$(date +%Y%m%d-%H%M%S).log}"
QXDC_DRY_RUN="${QXDC_DRY_RUN:-false}"
QXDC_YES="${QXDC_YES:-false}"
QXDC_VERBOSE="${QXDC_VERBOSE:-false}"

# Garantir DISPLAY para xfconf-query e xrandr (necessário via SSH)
export DISPLAY="${DISPLAY:-:0}"

# --- Cores ---
if [[ -t 1 ]]; then
    C_RESET='\033[0m'
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_BOLD='\033[1m'
else
    C_RESET='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_BOLD=''
fi

# --- Logging ---
log_info() {
    echo -e "${C_BLUE}[INFO]${C_RESET} $*"
    echo "[INFO] $(date +%H:%M:%S) $*" >> "$QXDC_LOG"
}

log_ok() {
    echo -e "${C_GREEN}[OK]${C_RESET} $*"
    echo "[OK] $(date +%H:%M:%S) $*" >> "$QXDC_LOG"
}

log_warn() {
    echo -e "${C_YELLOW}[WARN]${C_RESET} $*" >&2
    echo "[WARN] $(date +%H:%M:%S) $*" >> "$QXDC_LOG"
}

log_error() {
    echo -e "${C_RED}[ERRO]${C_RESET} $*" >&2
    echo "[ERRO] $(date +%H:%M:%S) $*" >> "$QXDC_LOG"
}

log_step() {
    echo -e "${C_BOLD}:: $*${C_RESET}"
    echo "[STEP] $(date +%H:%M:%S) $*" >> "$QXDC_LOG"
}

# --- Verificações ---
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este módulo precisa ser executado como root (use sudo)."
        exit 1
    fi
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Não execute como root. O script pedirá sudo quando necessário."
        exit 1
    fi
}

# --- Execução controlada ---
# Executa comando respeitando dry-run e logging
run() {
    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        echo -e "  ${C_YELLOW}[DRY-RUN]${C_RESET} $*"
        echo "[DRY-RUN] $*" >> "$QXDC_LOG"
        return 0
    fi

    if [[ "$QXDC_VERBOSE" == "true" ]]; then
        echo -e "  ${C_BLUE}[CMD]${C_RESET} $*"
    fi

    echo "[CMD] $*" >> "$QXDC_LOG"
    "$@" >> "$QXDC_LOG" 2>&1
}

# Executa com sudo
run_sudo() {
    run sudo "$@"
}

# --- Confirmação ---
confirm() {
    local msg="${1:-Continuar?}"
    if [[ "$QXDC_YES" == "true" ]]; then
        return 0
    fi
    echo -ne "${C_BOLD}${msg} [s/N] ${C_RESET}"
    read -r reply
    [[ "$reply" =~ ^[sS]$ ]]
}

# --- Utilitários ---
command_exists() {
    command -v "$1" &>/dev/null
}

is_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q "^ii" 2>/dev/null
}

# Parseia flags comuns (chamar no início de cada módulo)
# Aceita flags em qualquer ordem, passando o restante em QXDC_REMAINING_ARGS.
parse_common_flags() {
    QXDC_REMAINING_ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)    QXDC_DRY_RUN=true ;;
            --yes|-y)     QXDC_YES=true ;;
            --verbose|-v) QXDC_VERBOSE=true ;;
            *)            QXDC_REMAINING_ARGS+=("$1") ;;
        esac
        shift
    done
}

# --- Checagem de pré-condições para módulos desktop ---
# Verifica DISPLAY, D-Bus e xfconfd. Retorna 0 se OK, 1 se não.
# Se falhar, loga motivo e retorna — o chamador decide se é fatal.
check_desktop_session() {
    local errors=0

    # DISPLAY
    if [[ -z "${DISPLAY:-}" ]]; then
        log_error "DISPLAY não definido. Execute dentro de uma sessão gráfica."
        errors=$((errors + 1))
    fi

    # D-Bus session
    if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        log_error "DBUS_SESSION_BUS_ADDRESS não definido."
        log_error "Se estiver rodando via sudo, use: sudo -E (preservar ambiente)"
        log_error "Ou exporte: export DBUS_SESSION_BUS_ADDRESS=\$(cat /proc/\$(pgrep -u \$SUDO_USER xfce4-session | head -1)/environ 2>/dev/null | tr '\\0' '\\n' | grep DBUS_SESSION_BUS_ADDRESS | cut -d= -f2-)"
        errors=$((errors + 1))
    fi

    # xfconfd rodando
    if ! pgrep -x xfconfd &>/dev/null; then
        log_warn "xfconfd não está rodando. xfconf-query pode falhar."
        log_warn "Certifique-se de estar em uma sessão XFCE ativa."
        errors=$((errors + 1))
    fi

    # Rodando como root sem SUDO_USER
    if [[ $EUID -eq 0 && -z "${SUDO_USER:-}" ]]; then
        log_warn "Rodando como root puro (sem sudo -E). Configurações vão para /root, não para o usuário."
        errors=$((errors + 1))
    fi

    # Rodando como root COM SUDO_USER mas sem -E
    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        log_error "Rodando via sudo sem preservar ambiente."
        log_error "Use: sudo -E ./qxdc.sh ... (ou rode sem sudo — o script pede sudo quando precisa)"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        log_error "Pré-condições de sessão desktop NÃO atendidas ($errors problema(s))."
        return 1
    fi

    return 0
}
