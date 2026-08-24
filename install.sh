#!/usr/bin/env bash
# install.sh — Instalador interativo do QXDC
# Detecta a distro, sugere perfil e executa a configuração completa.
#
# Uso:
#   ./install.sh              # Modo interativo
#   ./install.sh --auto       # Detecta tudo e roda sem perguntas
#   ./install.sh --dry-run    # Preview sem executar

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/distro.sh"

# --- Cores inline (caso common.sh não tenha carregado) ---
_bold() { echo -e "${C_BOLD}$*${C_RESET}"; }
_green() { echo -e "${C_GREEN}$*${C_RESET}"; }
_yellow() { echo -e "${C_YELLOW}$*${C_RESET}"; }
_blue() { echo -e "${C_BLUE}$*${C_RESET}"; }

# --- Banner ---
show_banner() {
    echo ""
    _bold "  QXDC ${QXDC_VERSION} — Quirino's XFCE Default Config"
    echo "  Instalador interativo"
    echo ""
    echo "  Distro detectada: $(_green "$DISTRO_ID $DISTRO_VERSION") ($DISTRO_FAMILY)"
    echo ""
}

# --- Sugerir perfil baseado na distro ---
suggest_profile() {
    echo "full"
}

# --- Listar perfis disponíveis ---
list_profiles() {
    local profiles_dir="$SCRIPT_DIR/config/profiles/$DISTRO_FAMILY"
    local fallback_dir="$SCRIPT_DIR/config/profiles"
    local i=1
    PROFILES=()

    # Listar perfis da distro detectada
    if [[ -d "$profiles_dir" ]]; then
        for f in "$profiles_dir"/*.yml; do
            [[ -f "$f" ]] || continue
            local name
            name="$(basename "$f" .yml)"
            PROFILES+=("$name")
            local marker=""
            [[ "$name" == "$SUGGESTED" ]] && marker=" $(_green "<-- recomendado")"
            # Ler primeira linha de comentario como descricao
            local desc
            desc="$(grep -m1 "^# Perfil:" "$f" 2>/dev/null | sed 's/^# Perfil: //' || echo "")"
            [[ -z "$desc" ]] && desc="$(sed -n '2s/^# //p' "$f" 2>/dev/null)"
            echo "  $i) $name$marker"
            [[ -n "$desc" ]] && echo "     $desc"
            i=$((i + 1))
        done
    fi

    # Se nao encontrou perfis por distro, listar genéricos
    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        for f in "$fallback_dir"/*.yml; do
            [[ -f "$f" ]] || continue
            local name
            name="$(basename "$f" .yml)"
            PROFILES+=("$name")
            local marker=""
            [[ "$name" == "$SUGGESTED" ]] && marker=" $(_green "<-- recomendado")"
            echo "  $i) $name$marker"
            i=$((i + 1))
        done
    fi
}

# --- Selecionar perfil ---
select_profile() {
    echo "  Perfis disponíveis:"
    echo ""
    list_profiles
    echo ""

    if [[ "$AUTO_MODE" == "true" ]]; then
        SELECTED_PROFILE="$SUGGESTED"
        _blue "  [AUTO] Usando perfil: $SELECTED_PROFILE"
        return
    fi

    local default_num=1
    for i in "${!PROFILES[@]}"; do
        if [[ "${PROFILES[$i]}" == "$SUGGESTED" ]]; then
            default_num=$((i + 1))
            break
        fi
    done

    echo -n "  Escolha o perfil [$default_num]: "
    read -r choice
    choice="${choice:-$default_num}"

    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#PROFILES[@]} )); then
        SELECTED_PROFILE="${PROFILES[$((choice - 1))]}"
    else
        SELECTED_PROFILE="$SUGGESTED"
    fi

    echo ""
    _blue "  Perfil selecionado: $SELECTED_PROFILE"
}

# --- Confirmar execução ---
confirm_install() {
    if [[ "$AUTO_MODE" == "true" ]]; then
        return 0
    fi

    echo ""
    echo "  O QXDC vai:"
    echo "    - Instalar pacotes do perfil '$SELECTED_PROFILE'"
    echo "    - Habilitar serviços necessários"
    echo "    - Configurar tema, ícones e wallpaper (se sessão XFCE ativa)"
    echo "    - Instalar e configurar aplicativos"
    echo ""

    echo -n "  Prosseguir? [S/n]: "
    read -r confirm
    confirm="${confirm:-s}"

    case "$confirm" in
        [sS]|[yY]) return 0 ;;
        *)
            echo ""
            _yellow "  Instalação cancelada."
            exit 0
            ;;
    esac
}

# --- Preview (dry-run) ---
run_preview() {
    echo ""
    _bold "  === PREVIEW (nada será alterado) ==="
    echo ""
    bash "$SCRIPT_DIR/qxdc.sh" all install --profile "$SELECTED_PROFILE" --dry-run
}

# --- Executar instalação ---
run_install() {
    echo ""
    _bold "  === Instalando... ==="
    echo ""
    bash "$SCRIPT_DIR/qxdc.sh" all install --profile "$SELECTED_PROFILE" --yes
}

# --- Main ---
main() {
    AUTO_MODE="false"
    DRY_RUN="false"

    for arg in "$@"; do
        case "$arg" in
            --auto) AUTO_MODE="true" ;;
            --dry-run) DRY_RUN="true" ;;
            --help|-h)
                echo "Uso: ./install.sh [--auto] [--dry-run] [--help]"
                echo ""
                echo "  --auto      Detecta distro e roda sem perguntas"
                echo "  --dry-run   Mostra o que faria sem executar"
                echo "  --help      Mostra esta ajuda"
                exit 0
                ;;
        esac
    done

    SUGGESTED="$(suggest_profile)"

    show_banner
    select_profile

    if [[ "$DRY_RUN" == "true" ]]; then
        run_preview
    else
        confirm_install
        run_install
    fi

    echo ""
    _green "  QXDC finalizado."
    echo ""

    if [[ "$DISTRO_FAMILY" == "alpine" && "$DRY_RUN" != "true" ]]; then
        echo "  Para iniciar o desktop agora:"
        echo "    doas rc-service lightdm start"
        echo ""
        echo "  Ou reinicie: doas reboot"
        echo ""
    fi
}

main "$@"
