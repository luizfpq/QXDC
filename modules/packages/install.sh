#!/bin/bash
# modules/packages/install.sh — Instala pacotes base definidos no perfil
# Uso: ./modules/packages/install.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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
    log_step "Instalação de pacotes — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    # Lê lista de pacotes do config
    mapfile -t packages < <(config_get_list "packages.install" "$QXDC_CONFIG")

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "Nenhum pacote definido em packages.install para o perfil '$PROFILE'."
        return 0
    fi

    log_info "${#packages[@]} pacote(s) a instalar."

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Pacotes que seriam instalados:"
        printf "  - %s\n" "${packages[@]}"
        return 0
    fi

    # Habilitar contrib + non-free (necessário para drivers, codecs, etc)
    enable_nonfree_repos

    # Atualiza índice
    log_info "Atualizando índice de pacotes..."
    pkg_update

    # Instala
    pkg_install "${packages[@]}" || true

    log_ok "Instalação de pacotes concluída."
    log_info "Log completo em: $QXDC_LOG"
}

main
