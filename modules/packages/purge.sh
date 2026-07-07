#!/bin/bash
# modules/packages/purge.sh — Remove pacotes indesejados definidos no perfil
# Uso: ./modules/packages/purge.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Main ---
main() {
    log_step "Remoção de pacotes indesejados — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    # Lê lista de pacotes a remover
    mapfile -t packages < <(config_get_list "packages.purge" "$QXDC_CONFIG")

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "Nenhum pacote definido para remoção neste perfil."
        return 0
    fi

    log_info "${#packages[@]} pacote(s) a remover."

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Pacotes que seriam removidos:"
        printf "  - %s\n" "${packages[@]}"
        return 0
    fi

    if [[ "$QXDC_YES" != "true" ]]; then
        echo "Pacotes a remover:"
        printf "  - %s\n" "${packages[@]}"
        if ! confirm "Prosseguir com a remoção?"; then
            log_info "Operação cancelada pelo usuário."
            return 0
        fi
    fi

    pkg_remove "${packages[@]}"

    # Limpa dependências órfãs (Debian)
    if [[ "$DISTRO_FAMILY" == "debian" ]]; then
        log_info "Removendo dependências órfãs..."
        run_sudo apt-get autoremove -qq -y
    fi

    log_ok "Remoção de pacotes concluída."
}

main
