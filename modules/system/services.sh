#!/bin/bash
# modules/system/services.sh — Habilita serviços do sistema conforme perfil
# Alpine: rc-update add <service> default
# Debian: systemctl enable <service>
#
# Lê a lista de serviços de packages.services no perfil.
# Uso: ./modules/system/services.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Habilitar serviço ---
enable_service() {
    local svc="$1"

    case "$DISTRO_FAMILY" in
        alpine)
            if run_sudo rc-update add "$svc" default 2>/dev/null; then
                log_ok "Serviço $svc habilitado (OpenRC)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        debian)
            if run_sudo systemctl enable "$svc" 2>/dev/null; then
                log_ok "Serviço $svc habilitado (systemd)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        arch)
            if run_sudo systemctl enable "$svc" 2>/dev/null; then
                log_ok "Serviço $svc habilitado (systemd)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        *)
            log_warn "Habilitação de serviços não implementada para $DISTRO_FAMILY."
            return 0
            ;;
    esac
}

# --- Iniciar serviço agora ---
start_service() {
    local svc="$1"

    case "$DISTRO_FAMILY" in
        alpine)
            run_sudo rc-service "$svc" start 2>/dev/null || true
            ;;
        debian|arch)
            run_sudo systemctl start "$svc" 2>/dev/null || true
            ;;
    esac
}

# --- Main ---
main() {
    log_step "Habilitação de serviços — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    mapfile -t services < <(config_get_list "packages.services" "$QXDC_CONFIG")

    if [[ ${#services[@]} -eq 0 ]]; then
        log_info "Nenhum serviço definido em packages.services. Pulando."
        return 0
    fi

    log_info "${#services[@]} serviço(s) a habilitar."

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Serviços que seriam habilitados:"
        printf "  - %s\n" "${services[@]}"
        return 0
    fi

    for svc in "${services[@]}"; do
        enable_service "$svc"
        start_service "$svc"
    done

    log_ok "Serviços configurados."
}

main
