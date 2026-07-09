#!/bin/bash
# qxdc.sh — Quirino's XFCE Default Config v2.0
# Entrypoint principal. Executa módulos via CLI.
#
# Uso:
#   ./qxdc.sh <módulo> [--dry-run] [--yes] [--profile <nome>]
#   ./qxdc.sh packages install --profile minimal --yes
#   ./qxdc.sh packages purge --dry-run
#   ./qxdc.sh --help

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# --- Help ---
show_help() {
    cat <<EOF
${C_BOLD}QXDC ${QXDC_VERSION}${C_RESET} — Quirino's XFCE Default Config

${C_BOLD}Uso:${C_RESET}
  qxdc.sh [opções]                  Instalação completa (all install)
  qxdc.sh <módulo> <ação> [opções]  Executar módulo específico

${C_BOLD}Instalação completa:${C_RESET}
  qxdc.sh --yes                     Roda tudo com perfil full, sem perguntas
  qxdc.sh --dry-run                 Mostra tudo que faria sem executar
  qxdc.sh all install --profile full --yes

${C_BOLD}Módulos disponíveis:${C_RESET}
  all        Instalação completa (todos os módulos em sequência)
  packages   Gerenciamento de pacotes (install, purge)
  desktop    Configuração visual (theme, settings, wallpaper)
  apps       Instalação de aplicativos (browser, editor, media, stremio, fastfetch)
  system     Configuração de hardware (hardware)
  dotfiles   Deploy de arquivos de configuração

${C_BOLD}Opções globais:${C_RESET}
  --dry-run       Mostra o que faria sem executar
  --yes, -y       Responde sim para todas confirmações
  --verbose, -v   Saída detalhada
  --profile <p>   Perfil de configuração (minimal, full, lab)
  --help, -h      Mostra esta ajuda

${C_BOLD}Exemplos:${C_RESET}
  qxdc.sh --yes                            # Instalação completa
  qxdc.sh --dry-run                        # Preview completo
  qxdc.sh packages install --profile minimal --yes
  qxdc.sh desktop theme --profile full --yes
  qxdc.sh all install --profile lab --yes

${C_BOLD}Log:${C_RESET}
  Toda execução gera log em /tmp/qxdc-*.log
EOF
}

# --- Resolve módulo ---
resolve_module() {
    local module="$1"
    local action="$2"
    local module_path="$SCRIPT_DIR/modules/$module/$action.sh"

    if [[ -f "$module_path" ]]; then
        echo "$module_path"
    else
        return 1
    fi
}

# --- Main ---
main() {
    # Sem argumentos → help
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    # Flags globais antes do módulo
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --version)
            echo "QXDC $QXDC_VERSION"
            exit 0
            ;;
        --yes|-y|--dry-run|--verbose|-v|--profile)
            # Flags sem módulo → roda 'all install' com essas flags
            exec bash "$SCRIPT_DIR/modules/all/install.sh" "$@"
            ;;
    esac

    local module="$1"
    shift

    # Módulo sem ação → comportamento padrão
    if [[ $# -eq 0 || "$1" == --* ]]; then
        # 'all' sem ação explícita → rodar 'install' com as flags restantes
        if [[ "$module" == "all" ]]; then
            exec bash "$SCRIPT_DIR/modules/all/install.sh" "$@"
        fi

        local module_dir="$SCRIPT_DIR/modules/$module"
        if [[ -d "$module_dir" ]]; then
            log_info "Ações disponíveis para '$module':"
            for f in "$module_dir"/*.sh; do
                [[ -f "$f" ]] && echo "  - $(basename "$f" .sh)"
            done
            exit 0
        else
            log_error "Módulo '$module' não encontrado."
            echo "Use 'qxdc.sh --help' para ver módulos disponíveis."
            exit 1
        fi
    fi

    local action="$1"
    shift

    local module_path
    module_path="$(resolve_module "$module" "$action")" || {
        log_error "Ação '$action' não encontrada para módulo '$module'."
        echo "Use 'qxdc.sh $module' para listar ações disponíveis."
        exit 1
    }

    # Executa o módulo passando as flags restantes
    exec bash "$module_path" "$@"
}

main "$@"
