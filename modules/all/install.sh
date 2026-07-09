#!/bin/bash
# modules/all/install.sh — Instalação completa do QXDC em sequência
# Executa todos os módulos na ordem correta.
# Cada módulo gera um log individual em /tmp/qxdc-modules/ para análise.
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

# --- Sanitizar estado do apt antes de tudo ---
sanitize_apt() {
    check_apt_health
}

# --- Main ---
main() {
    export QXDC_LOG

    log_step "QXDC ${QXDC_VERSION} — Instalação completa (perfil: $PROFILE)"
    echo ""

    # Corrigir estado do apt antes de rodar qualquer módulo
    if [[ "$QXDC_DRY_RUN" != "true" ]]; then
        sanitize_apt || {
            log_error "Abortando: apt em estado inconsistente."
            exit 1
        }
        echo ""
    fi

    local modules=(
        "packages install"
        "packages purge"
        "desktop theme"
        "desktop settings"
        "desktop wallpaper"
        "apps editor"
        "apps browser"
        "apps media"
        "apps stremio"
        "apps heroic"
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
    local -a failed_codes=()

    # Diretório de logs por módulo (sobrevive à execução para análise)
    local module_log_dir="/tmp/qxdc-modules"
    rm -rf "$module_log_dir"
    mkdir -p "$module_log_dir"

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
            failed_codes+=("N/A")
            echo "ERRO: Arquivo não encontrado: $module_path" > "$module_log_dir/${current}-${module_name}-${action}.log"
            continue
        fi

        # Log individual do módulo: captura stdout + stderr combinados
        local mod_log="$module_log_dir/${current}-${module_name}-${action}.log"

        # Executa módulo com pipefail desabilitado para capturar exit code real
        local exit_code=0
        QXDC_LOG="$QXDC_LOG" bash "$module_path" $flags > "$mod_log" 2>&1 || exit_code=$?

        # Mostrar output do módulo no terminal
        cat "$mod_log"

        if [[ $exit_code -eq 0 ]]; then
            log_ok "[$current/$total] $mod concluído."
        else
            log_warn "[$current/$total] $mod falhou (exit code: $exit_code)."
            failed=$((failed + 1))
            failed_modules+=("$mod")
            failed_codes+=("$exit_code")

            # Mostrar últimas linhas do output do módulo
            echo ""
            log_error "--- Saída de '$mod' (últimas 10 linhas) ---"
            tail -10 "$mod_log" | while IFS= read -r line; do
                echo "  $line" >&2
            done
            log_error "--- fim ---"
        fi
    done

    echo ""
    log_step "Resultado final"
    log_ok "$((total - failed))/$total módulos concluídos com sucesso."

    if [[ $failed -gt 0 ]]; then
        log_warn "$failed módulo(s) com erros."
        echo ""
        log_step "Detalhes dos erros"
        echo ""
        for i in "${!failed_modules[@]}"; do
            log_error "[FALHA] ${failed_modules[$i]} (exit code: ${failed_codes[$i]})"
        done

        echo ""
        log_info "Logs individuais por módulo em: $module_log_dir/"
        log_info "Para analisar uma falha:"
        log_info "  cat $module_log_dir/<N>-<modulo>-<acao>.log"
    fi

    if [[ "$QXDC_DRY_RUN" != "true" ]]; then
        echo ""
        log_info "Faça logout/login para aplicar todas as mudanças visuais."
        log_info "Log global em: $QXDC_LOG"
        log_info "Logs por módulo em: $module_log_dir/"
    fi
}

main
