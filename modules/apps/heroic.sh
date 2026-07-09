#!/bin/bash
# modules/apps/heroic.sh — Instala Heroic Games Launcher (Epic/GOG/Amazon)
# Método: .deb oficial do GitHub Releases (sempre a versão mais recente)
#
# Heroic é um launcher open-source para jogos da Epic Games Store,
# GOG e Amazon Games. Empacotado como Electron app, sem dependências
# problemáticas no Debian 13.
#
# O script consulta a API do GitHub para descobrir a última release e
# baixar o .deb correspondente automaticamente.
#
# Uso: ./modules/apps/heroic.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- GitHub repo ---
HEROIC_REPO="Heroic-Games-Launcher/HeroicGamesLauncher"
HEROIC_API="https://api.github.com/repos/${HEROIC_REPO}/releases/latest"

# --- Descobrir última versão e URL do .deb ---
resolve_latest_release() {
    log_info "Consultando última release do Heroic Games Launcher..."

    if ! command_exists curl; then
        log_error "curl não encontrado. Instale com: apt install curl"
        return 1
    fi

    local api_response
    api_response="$(curl -sL "$HEROIC_API")"

    if [[ -z "$api_response" ]]; then
        log_error "Falha ao consultar API do GitHub (sem resposta)."
        return 1
    fi

    # Extrair tag_name (ex: "v2.22.0")
    HEROIC_TAG="$(echo "$api_response" | grep -oP '"tag_name"\s*:\s*"\K[^"]+')"
    if [[ -z "$HEROIC_TAG" ]]; then
        log_error "Não foi possível determinar a versão mais recente."
        log_error "Verifique conectividade com api.github.com"
        return 1
    fi

    HEROIC_VERSION="${HEROIC_TAG#v}"
    log_info "Última versão: ${HEROIC_VERSION} (tag: ${HEROIC_TAG})"

    # Extrair URL do .deb amd64
    HEROIC_DEB_URL="$(echo "$api_response" | grep -oP '"browser_download_url"\s*:\s*"\K[^"]+linux-amd64\.deb')"

    if [[ -z "$HEROIC_DEB_URL" ]]; then
        log_error "Não encontrado .deb amd64 nos assets da release ${HEROIC_TAG}."
        log_error "Verifique manualmente: https://github.com/${HEROIC_REPO}/releases/latest"
        return 1
    fi

    log_info "URL do .deb: $HEROIC_DEB_URL"
}

# --- Verificar se já está na versão mais recente ---
check_installed_version() {
    if ! is_installed heroic 2>/dev/null; then
        return 1
    fi

    local installed_version
    installed_version="$(dpkg-query -W -f='${Version}' heroic 2>/dev/null || true)"

    # O pacote pode ter sufixo (ex: "2.22.0" ou "2.22.0-1")
    local installed_base="${installed_version%%-*}"

    if [[ "$installed_base" == "$HEROIC_VERSION" ]]; then
        return 0
    fi

    return 1
}

# --- Garantir que o apt está em estado limpo ---
fix_broken_if_needed() {
    check_apt_health || return 1
}

# --- Instalar Heroic Games Launcher ---
install_heroic() {
    log_step "Instalando Heroic Games Launcher v${HEROIC_VERSION}"

    if check_installed_version; then
        log_info "Heroic Games Launcher v${HEROIC_VERSION} já instalado (versão atual)."
        return 0
    fi

    fix_broken_if_needed

    if is_installed heroic 2>/dev/null; then
        local old_ver
        old_ver="$(dpkg-query -W -f='${Version}' heroic 2>/dev/null || echo '?')"
        log_info "Atualizando Heroic: ${old_ver} → ${HEROIC_VERSION}"
    fi

    local tmp_deb="${QXDC_TMPDIR}/heroic-${HEROIC_VERSION}.deb"

    download_file "$HEROIC_DEB_URL" "$tmp_deb" || return 1

    log_info "Instalando Heroic Games Launcher..."
    run_sudo apt-get install -qq -y "$tmp_deb"

    if command_exists heroic; then
        log_ok "Heroic Games Launcher v${HEROIC_VERSION} instalado com sucesso."
    elif [[ -x /opt/Heroic/heroic ]] || [[ -x /usr/bin/heroic ]]; then
        log_ok "Heroic Games Launcher v${HEROIC_VERSION} instalado."
    else
        log_warn "Heroic instalado mas binário não localizado no PATH."
        log_info "Procure em: /opt/Heroic/ ou verifique o .desktop em /usr/share/applications/"
    fi
}

# --- Main ---
main() {
    log_step "Heroic Games Launcher — perfil: $PROFILE"

    load_profile "$PROFILE"

    resolve_latest_release || exit 1

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Heroic Games Launcher v${HEROIC_VERSION}"
        log_info "[DRY-RUN] Método: .deb oficial (apt install, sempre última versão)"
        log_info "[DRY-RUN] URL: $HEROIC_DEB_URL"
        if check_installed_version; then
            log_info "[DRY-RUN] Já está na versão mais recente. Nada a fazer."
        fi
        return 0
    fi

    install_heroic
}

main
