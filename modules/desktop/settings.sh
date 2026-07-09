#!/bin/bash
# modules/desktop/settings.sh — Configurações de comportamento do desktop XFCE
# Workspaces, Thunar, atalhos, etc.
#
# Uso: ./modules/desktop/settings.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Workspaces ---
configure_workspaces() {
    local count
    count="$(config_get "desktop.workspaces" "$QXDC_CONFIG")"
    count="${count:-1}"

    log_info "Espaços de trabalho: $count"
    run xfconf-query -c xfwm4 -p /general/workspace_count -s "$count" --create -t int
}

# --- Menu de aplicativos (Whisker Menu) ---
configure_app_menu() {
    local menu
    menu="$(config_get "desktop.app_menu" "$QXDC_CONFIG")"
    menu="${menu:-whiskermenu}"

    log_info "Menu de aplicativos: $menu"

    # Verifica se whiskermenu está instalado
    if [[ "$menu" == "whiskermenu" ]]; then
        if ! is_installed xfce4-whiskermenu-plugin 2>/dev/null; then
            log_info "Instalando xfce4-whiskermenu-plugin..."
            run_sudo apt-get install -qq -y xfce4-whiskermenu-plugin
        fi
    fi

    # Verificar se o plugin-1 já é o tipo correto
    local current
    current="$(xfconf-query -c xfce4-panel -p /plugins/plugin-1 2>/dev/null || true)"
    if [[ "$current" == "$menu" ]]; then
        log_info "Plugin-1 já é $menu."
        return 0
    fi

    # Mudar o tipo do plugin-1.
    # NOTA: Não usar -r + recriar — isso pode desassociar o ID do painel.
    # Em vez disso, apenas sobrescrever o valor do plugin (--create trata como upsert
    # se já existir a propriedade com o mesmo tipo).
    if [[ -z "$current" ]]; then
        # Plugin-1 não existe — criar
        log_info "Criando plugin-1 como $menu..."
        run xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s "$menu" --create -t string
    else
        # Plugin-1 existe mas é outro tipo — sobrescrever valor
        log_info "Alterando plugin-1 de '$current' para '$menu'..."
        run xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s "$menu"
    fi
}

# --- Menu de clique direito na área de trabalho ---
configure_desktop_menu() {
    local show_menu
    show_menu="$(config_get "desktop.desktop_right_click_menu" "$QXDC_CONFIG")"
    show_menu="${show_menu:-false}"

    log_info "Menu clique direito desktop: $show_menu"
    run xfconf-query -c xfce4-desktop -p /desktop-menu/show -s "$show_menu" --create -t bool
}

# --- Painel 2: transparência ---
configure_panel2() {
    local alpha
    alpha="$(config_get "desktop.panel2_background_alpha" "$QXDC_CONFIG")"
    alpha="${alpha:-12}"

    # XFCE 4.20: background-style=1 (cor sólida) + background-rgba com alpha
    local alpha_dec
    alpha_dec="$(echo "scale=2; $alpha / 100" | bc)"

    log_info "Painel 2 background: cor sólida, alpha ${alpha}% (${alpha_dec})"
    run xfconf-query -c xfce4-panel -p /panels/panel-2/background-style -s 1 --create -t uint
    run xfconf-query -c xfce4-panel -p /panels/panel-2/background-rgba \
        -s 1.0 -s 1.0 -s 1.0 -s "$alpha_dec" --create -t double -t double -t double -t double
}

# --- Ícones da área de trabalho ---
configure_desktop_icons() {
    local show_home show_trash show_filesystem show_removable
    show_home="$(config_get "desktop.icons_show_home" "$QXDC_CONFIG")"
    show_trash="$(config_get "desktop.icons_show_trash" "$QXDC_CONFIG")"
    show_filesystem="$(config_get "desktop.icons_show_filesystem" "$QXDC_CONFIG")"
    show_removable="$(config_get "desktop.icons_show_removable" "$QXDC_CONFIG")"

    show_home="${show_home:-false}"
    show_trash="${show_trash:-false}"
    show_filesystem="${show_filesystem:-false}"
    show_removable="${show_removable:-true}"

    log_info "Ícones desktop: home=$show_home trash=$show_trash filesystem=$show_filesystem removable=$show_removable"
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-home -s "$show_home" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-trash -s "$show_trash" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s "$show_filesystem" --create -t bool
    run xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-removable -s "$show_removable" --create -t bool
}

# --- Thunar ---
configure_thunar() {
    local location_bar
    location_bar="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
    location_bar="${location_bar:-ThunarLocationButtons}"

    log_info "Thunar location bar: $location_bar"

    # XFCE 4.18+: Thunar usa xfconf (canal thunar)
    run xfconf-query -c thunar -p /last-location-bar -s "$location_bar" --create -t string
}

# --- Plugin de volume (pulseaudio) — garantir presença no painel 1 ---
ensure_pulseaudio_plugin() {
    log_info "Verificando plugin pulseaudio no painel 1..."

    # 1) Ler IDs do painel 1
    local panel1_ids
    panel1_ids="$(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null \
        | grep -E '^\s*[0-9]+\s*$' | tr -d '[:space:]' || true)"

    if [[ -z "$panel1_ids" ]]; then
        log_warn "Não foi possível ler plugin-ids do painel 1. Pulando."
        return 0
    fi

    # 2) Verificar se pulseaudio já existe no painel 1
    local id
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local ptype
        ptype="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)"
        if [[ "$ptype" == "pulseaudio" ]]; then
            log_info "Plugin pulseaudio já presente no painel 1 (plugin-${id}). Nada a fazer."
            return 0
        fi
    done <<< "$panel1_ids"

    # 3) Não existe — verificar se xfce4-pulseaudio-plugin está instalado
    if ! is_installed xfce4-pulseaudio-plugin 2>/dev/null; then
        log_info "Instalando xfce4-pulseaudio-plugin..."
        run_sudo apt-get install -qq -y xfce4-pulseaudio-plugin
    fi

    # 4) Encontrar o maior ID de plugin em uso (todos os painéis)
    local max_id=0
    local all_plugins
    all_plugins="$(xfconf-query -c xfce4-panel -p /plugins -l 2>/dev/null \
        | grep -oP '/plugins/plugin-\K[0-9]+' | sort -n || true)"
    if [[ -n "$all_plugins" ]]; then
        max_id="$(echo "$all_plugins" | tail -1)"
    fi
    local new_id=$((max_id + 1))

    log_info "Criando plugin pulseaudio como plugin-${new_id}..."
    run xfconf-query -c xfce4-panel -p "/plugins/plugin-${new_id}" \
        -s "pulseaudio" --create -t string

    # 5) Determinar posição de inserção: após systray, antes do clock.
    #    Estratégia: encontrar o ID do plugin 'systray' no painel 1.
    #    Inserir o novo ID logo após o systray (ou após o separator seguinte).
    #    Se não encontrar systray, inserir antes do último elemento (actions).
    local ids_array=()
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        ids_array+=("$id")
    done <<< "$panel1_ids"

    local insert_pos=${#ids_array[@]}  # default: final
    local systray_found=false
    for i in "${!ids_array[@]}"; do
        local ptype
        ptype="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${ids_array[$i]}" 2>/dev/null || true)"
        if [[ "$ptype" == "systray" || "$ptype" == "statusnotifier" ]]; then
            systray_found=true
            # Inserir após o systray. Se o próximo é separator, inserir depois dele.
            local next=$((i + 1))
            if [[ $next -lt ${#ids_array[@]} ]]; then
                local next_type
                next_type="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${ids_array[$next]}" 2>/dev/null || true)"
                if [[ "$next_type" == "separator" ]]; then
                    insert_pos=$((next + 1))
                else
                    insert_pos=$((i + 1))
                fi
            else
                insert_pos=$((i + 1))
            fi
            break
        fi
    done

    if [[ "$systray_found" == "false" ]]; then
        # Fallback: inserir antes do último (geralmente 'actions')
        if [[ ${#ids_array[@]} -gt 1 ]]; then
            insert_pos=$(( ${#ids_array[@]} - 1 ))
        fi
        log_warn "Plugin systray não encontrado. Inserindo pulseaudio na posição ${insert_pos}."
    fi

    # 6) Construir nova lista com inserção
    local new_ids=()
    for i in "${!ids_array[@]}"; do
        if [[ $i -eq $insert_pos ]]; then
            new_ids+=("$new_id")
        fi
        new_ids+=("${ids_array[$i]}")
    done
    # Se insert_pos == tamanho do array, adicionar no final
    if [[ $insert_pos -ge ${#ids_array[@]} ]]; then
        new_ids+=("$new_id")
    fi

    # 7) Aplicar nova lista ao painel 1 (reset + create separados)
    log_info "Atualizando plugin-ids do painel 1 (${#new_ids[@]} itens)..."

    # Construir argumentos -t int -s <id> para xfconf-query
    local xfconf_args=()
    for pid in "${new_ids[@]}"; do
        xfconf_args+=(-t int -s "$pid")
    done

    run xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -r
    run xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids -n "${xfconf_args[@]}"

    log_ok "Plugin pulseaudio (plugin-${new_id}) adicionado ao painel 1."
}

# --- Botão de janelas (tasklist) — desativar agrupamento ---
configure_tasklist() {
    log_info "Tasklist (window buttons): agrupamento desativado"

    # Encontrar o plugin tasklist no painel 1
    # xfconf-query retorna output localizado (ex: "O valor é uma matriz com 10 itens:")
    # Filtrar apenas linhas numéricas para obter os IDs dos plugins.
    local plugin_id=""
    local plugin_ids
    plugin_ids="$(xfconf-query -c xfce4-panel -p /panels/panel-1/plugin-ids 2>/dev/null | grep -E '^\s*[0-9]+\s*$' || true)"

    if [[ -n "$plugin_ids" ]]; then
        while IFS= read -r id; do
            id="$(echo "$id" | tr -d '[:space:]')"
            [[ -z "$id" ]] && continue
            local ptype
            ptype="$(xfconf-query -c xfce4-panel -p "/plugins/plugin-${id}" 2>/dev/null || true)"
            if [[ "$ptype" == "tasklist" ]]; then
                plugin_id="$id"
                break
            fi
        done <<< "$plugin_ids"
    fi

    if [[ -z "$plugin_id" ]]; then
        log_warn "Plugin tasklist não encontrado no painel 1. Pulando configuração."
        return 0
    fi

    log_info "Tasklist encontrado: plugin-${plugin_id}"

    # grouping: 0 = nunca agrupar, 1 = sempre agrupar
    run xfconf-query -c xfce4-panel -p "/plugins/plugin-${plugin_id}/grouping" \
        -s 0 --create -t uint

    log_ok "Agrupamento de janelas desativado (plugin-${plugin_id})."
}

# --- Main ---
main() {
    log_step "Configurações de desktop — perfil: $PROFILE"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        local ws tb menu desktop_menu
        ws="$(config_get "desktop.workspaces" "$QXDC_CONFIG")"
        tb="$(config_get "desktop.thunar_location_bar" "$QXDC_CONFIG")"
        menu="$(config_get "desktop.app_menu" "$QXDC_CONFIG")"
        desktop_menu="$(config_get "desktop.desktop_right_click_menu" "$QXDC_CONFIG")"
        log_info "[DRY-RUN] Configurações que seriam aplicadas:"
        echo "  Workspaces:              ${ws:-1}"
        echo "  Thunar location bar:     ${tb:-ThunarLocationButtons}"
        echo "  App menu (painel):       ${menu:-whiskermenu}"
        echo "  Right-click desktop menu: ${desktop_menu:-false}"
        echo "  Desktop icons:           home=false trash=false filesystem=false removable=true"
        echo "  Tasklist grouping:       desativado (never group)"
        echo "  Pulseaudio plugin:       garantir presença no painel 1"
        return 0
    fi

    # Verificar pré-condições de sessão desktop
    if ! check_desktop_session; then
        log_error "Módulo 'desktop settings' requer sessão XFCE ativa."
        log_error "Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus."
        return 1
    fi

    configure_workspaces
    configure_app_menu
    configure_desktop_menu
    configure_desktop_icons
    configure_panel2
    configure_thunar
    configure_tasklist
    ensure_pulseaudio_plugin

    # Restart panel para aplicar mudanças
    xfce4-panel --restart 2>/dev/null &

    log_ok "Configurações de desktop aplicadas."
}

main
