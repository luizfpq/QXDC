#!/bin/bash
# modules/desktop/panel.sh — Constrói o layout base do painel XFCE (barra superior)
# Cria /panels/panel-1/plugin-ids e os plugins associados quando ausentes.
#
# Este é o passo que os módulos 'desktop settings' assumem já existir:
# configure_app_menu, configure_tasklist e ensure_pulseaudio_plugin todos leem
# /panels/panel-1/plugin-ids. Sem este módulo, uma sessão XFCE recém-criada pode
# ter panel-1 sem plugin-ids — resultando numa barra superior vazia.
#
# Idempotente: se panel-1 já tem plugins, não sobrescreve (respeita customizações),
# a menos que --force seja passado.
#
# Uso: ./modules/desktop/panel.sh [--dry-run] [--yes] [--verbose] [--profile <nome>] [--force]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

# --- Flags ---
PROFILE="minimal"
FORCE=false

parse_common_flags "$@"
set -- "${QXDC_REMAINING_ARGS[@]}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift ;;
        --force)   FORCE=true ;;
        *) log_error "Flag desconhecida: $1"; exit 1 ;;
    esac
    shift
done

CHANNEL="xfce4-panel"

# --- Conta quantos plugins o panel-1 já referencia ---
# Retorna via stdout o número de IDs válidos (0 se a propriedade não existe).
panel1_plugin_count() {
    local ids
    ids="$(xfconf-query -c "$CHANNEL" -p /panels/panel-1/plugin-ids 2>/dev/null \
        | grep -Ec '^[[:space:]]*[0-9]+[[:space:]]*$' || true)"
    echo "${ids:-0}"
}

# --- Garante que o panel-1 existe com propriedades básicas de aparência ---
ensure_panel1_props() {
    # position: p=6 = topo, horizontal, largura total
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/position \
        -s "p=6;x=0;y=0" --create -t string
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/length \
        -s 100 --create -t uint
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/position-locked \
        -s true --create -t bool
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/size \
        -s 26 --create -t uint
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/icon-size \
        -s 16 --create -t uint

    # Garantir que panel-1 está listado no array /panels
    # (se /panels não existir ou não incluir 1, o painel não é exibido)
    local panels
    panels="$(xfconf-query -c "$CHANNEL" -p /panels 2>/dev/null \
        | grep -Ec '^[[:space:]]*[0-9]+[[:space:]]*$' || true)"
    if [[ "${panels:-0}" -eq 0 ]]; then
        log_info "Registrando panel-1 no array /panels..."
        run xfconf-query -c "$CHANNEL" -p /panels --create -t int -s 1 -a
    fi
}

# --- Constrói o layout de plugins do panel-1 ---
# Layout: whiskermenu | tasklist | <separator-expand> | pager | separator |
#         systray | pulseaudio | separator | clock | separator | actions
build_panel1_layout() {
    log_info "Construindo layout do painel superior (panel-1)..."

    # 1) Definir cada plugin pelo seu tipo. Usamos IDs 1..10 + pulseaudio.
    #    O tipo é definido em /plugins/plugin-N (string).
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-1 -s "whiskermenu" --create -t string

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-2 -s "tasklist" --create -t string
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-2/grouping -s 0 --create -t uint

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-3 -s "separator" --create -t string
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-3/expand -s true --create -t bool
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-3/style -s 0 --create -t uint

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-4 -s "pager" --create -t string

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-5 -s "separator" --create -t string
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-5/style -s 0 --create -t uint

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-6 -s "systray" --create -t string

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-7 -s "pulseaudio" --create -t string

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-8 -s "separator" --create -t string
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-8/style -s 0 --create -t uint

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-9 -s "clock" --create -t string

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-10 -s "separator" --create -t string
    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-10/style -s 0 --create -t uint

    run xfconf-query -c "$CHANNEL" -p /plugins/plugin-11 -s "actions" --create -t string

    # 2) Associar os IDs ao panel-1 (a ordem aqui é a ordem visual na barra).
    #    -r remove o array antigo, -n cria o novo (evita append duplicado).
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/plugin-ids -r 2>/dev/null || true
    run xfconf-query -c "$CHANNEL" -p /panels/panel-1/plugin-ids -n \
        -t int -s 1  -t int -s 2  -t int -s 3  -t int -s 4  -t int -s 5 \
        -t int -s 6  -t int -s 7  -t int -s 8  -t int -s 9  -t int -s 10 \
        -t int -s 11

    log_ok "Layout do painel superior construído (11 itens)."
}

# --- Main ---
main() {
    log_step "Configuração do painel — perfil: $PROFILE"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Painel que seria configurado:"
        echo "  panel-1 (topo): whiskermenu, tasklist, separator(expand),"
        echo "                  pager, separator, systray, pulseaudio,"
        echo "                  separator, clock, separator, actions"
        echo "  Idempotência:   só (re)constrói se panel-1 estiver vazio (ou --force)"
        return 0
    fi

    # Verificar pré-condições de sessão desktop
    if ! check_desktop_session; then
        log_error "Módulo 'desktop panel' requer sessão XFCE ativa."
        log_error "Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus."
        return 1
    fi

    # Garantir dependência do whiskermenu (o layout usa esse plugin)
    if ! is_installed xfce4-whiskermenu-plugin 2>/dev/null; then
        log_info "Instalando xfce4-whiskermenu-plugin..."
        pkg_install xfce4-whiskermenu-plugin || \
            log_warn "Falha ao instalar whiskermenu; o painel ainda será construído."
    fi

    ensure_panel1_props

    local count
    count="$(panel1_plugin_count)"

    if [[ "$count" -gt 0 && "$FORCE" != "true" ]]; then
        log_info "panel-1 já possui $count plugin(s). Nada a fazer (use --force para reconstruir)."
    else
        if [[ "$count" -eq 0 ]]; then
            log_warn "panel-1 sem plugins — barra superior estaria vazia. Construindo layout base."
        else
            log_info "Reconstruindo layout (--force)."
        fi
        build_panel1_layout
    fi

    # Reiniciar painel para aplicar
    xfce4-panel --restart 2>/dev/null &

    log_ok "Painel configurado."
}

main
