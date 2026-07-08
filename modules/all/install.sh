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
    # Exportar QXDC_LOG para submódulos herdarem o mesmo arquivo
    export QXDC_LOG

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
        "apps media"
        "apps fastfetch"
        "system hardware"
        "dotfiles deploy"
    )

    local flags="--profile $PROFILE --yes"
    [[ "$QXDC_DRY_RUN" == "true" ]] && flags="$flags --dry-run"
    [[ "$QXDC_VERBOSE" == "true" ]] && flags="$flags --verbose"

    local total=${#modules[@]}
    local current=0
    local failed=0
    local -a failed_modules=()
    local -a failed_errors=()

    # Diretório temporário para capturar stderr de cada módulo
    local err_dir
    err_dir="$(mktemp -d /tmp/qxdc-errors-XXXXXX)"

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
            failed_modules+=("$mod")
            failed_errors+=("Arquivo não encontrado: $module_path")
            continue
        fi

        local err_file="$err_dir/${module_name}-${action}.err"

        # Exportar QXDC_LOG para que submódulos herdem o mesmo log
        if QXDC_LOG="$QXDC_LOG" bash "$module_path" $flags 2> >(tee "$err_file" >&2); then
            log_ok "[$current/$total] $mod concluído."
        else
            local exit_code=$?
            log_warn "[$current/$total] $mod falhou (exit code: $exit_code)."
            failed=$((failed + 1))
            failed_modules+=("$mod")

            # Capturar últimas linhas de erro
            local err_summary=""
            if [[ -s "$err_file" ]]; then
                err_summary="$(tail -5 "$err_file")"
            fi
            failed_errors+=("${err_summary:-Sem saída de erro capturada (verifique o log)}")

            # Mostrar preview do erro inline
            if [[ -n "$err_summary" ]]; then
                echo ""
                log_error "--- Erro em '$mod' (últimas 5 linhas) ---"
                while IFS= read -r line; do
                    echo "  $line" >&2
                    echo "[STDERR] $line" >> "$QXDC_LOG"
                done <<< "$err_summary"
                log_error "--- fim ---"
            fi
        fi
    done

    echo ""
    log_step "Resultado final"
    log_ok "$((total - failed))/$total módulos concluídos com sucesso."

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed módulo(s) com erros."
        echo ""
        log_step "Detalhes dos erros"
        for i in "${!failed_modules[@]}"; do
            echo ""
            log_error "[FALHA] ${failed_modules[$i]}"
            while IFS= read -r line; do
                echo "  $line" >&2
            done <<< "${failed_errors[$i]}"
        done
    fi

    # Limpar diretório temporário de erros
    rm -rf "$err_dir"

    if [[ "$QXDC_DRY_RUN" != "true" ]]; then
        echo ""
        log_info "Faça logout/login para aplicar todas as mudanças visuais."
        log_info "Log completo em: $QXDC_LOG"
    fi
}

main
