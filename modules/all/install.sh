#!/bin/bash
# modules/all/install.sh — Instalação completa do QXDC em sequência
# Executa todos os módulos na ordem correta.
#
# Uso: ./qxdc.sh all install [--dry-run] [--yes] [--verbose] [--profile <nome>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

# --- Flags ---
PROFILE="full"

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
    log_step "QXDC ${QXDC_VERSION} — Instalação completa (perfil: $PROFILE)"
    echo ""

    local modules=(
        "packages install"
        "packages purge"
        "desktop theme"
        "desktop settings"
        "desktop wallpaper"
        "apps editor"
        "apps browser"
        "apps fastfetch"
        "dotfiles deploy"
    )

    local flags="--profile $PROFILE --yes"
    [[ "$QXDC_DRY_RUN" == "true" ]] && flags="$flags --dry-run"
    [[ "$QXDC_VERBOSE" == "true" ]] && flags="$flags --verbose"

    local total=${#modules[@]}
    local current=0
    local failed=0

    for mod in "${modules[@]}"; do
        current=$((current + 1))
        echo ""
        log_step "[$current/$total] qxdc.sh $mod"

        local module_name="${mod%% *}"
        local action="${mod##* }"
        local module_path="$QXDC_ROOT/modules/$module_name/$action.sh"

        if [[ ! -f "$module_path" ]]; then
            log_warn "Módulo não encontrado: $module_path (pulando)"
            failed=$((failed + 1))
            continue
        fi

        if bash "$module_path" $flags; then
            log_ok "[$current/$total] $mod concluído."
        else
            log_warn "[$current/$total] $mod teve erros (continuando)."
            failed=$((failed + 1))
        fi
    done

    echo ""
    log_step "Resultado final"
    log_ok "$((total - failed))/$total módulos concluídos com sucesso."
    [[ $failed -gt 0 ]] && log_warn "$failed módulo(s) com erros."

    if [[ "$QXDC_DRY_RUN" != "true" ]]; then
        echo ""
        log_info "Faça logout/login para aplicar todas as mudanças visuais."
        log_info "Log completo em: $QXDC_LOG"
    fi
}

main
