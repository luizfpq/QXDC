#!/bin/bash
# modules/desktop/fonts.sh — Instala Nerd Fonts (fontes com ícones)
# As Nerd Fonts NÃO existem nos repositórios (apt/apk/pacman), então são
# baixadas dos releases oficiais do GitHub e instaladas system-wide.
#
# Por que isso importa: TUIs e prompts do QXDC (ex.: monitor IronLAN, fastfetch,
# starship) usam glifos do range private-use das Nerd Fonts (nf-fa, nf-md,
# nf-oct, nf-dev, nf-linux). Sem uma Nerd Font instalada esses ícones aparecem
# como caixas vazias (tofu).
#
# Instala:
#   - Hack Nerd Font        → fonte mono principal (com ícones embutidos)
#   - Symbols Nerd Font      → fallback de 'monospace' via fontconfig (.conf),
#                              para quem usa outra fonte mono sem ícones
#
# Uso: ./modules/desktop/fonts.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Config ---
# Diretório system-wide de fontes do QXDC (fora dos caminhos de pacote).
FONT_DIR="/usr/share/fonts/nerd-fonts"
# Fallback de fontconfig system-wide.
FONTCONFIG_DIR="/etc/fonts/conf.d"
# Base dos releases "latest" do nerd-fonts.
NF_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

# Lista default de Nerd Fonts a instalar (nome do zip, sem extensão).
# Pode ser sobrescrita no perfil via chave 'fonts.nerd_fonts'.
DEFAULT_NERD_FONTS=("Hack" "NerdFontsSymbolsOnly")

# --- Verifica se já há alguma Nerd Font instalada ---
# Nota: não usar `fc-list | grep -q` sob `pipefail` — o grep fecha o pipe no
# primeiro match e o fc-list morre com SIGPIPE (141), fazendo a função reportar
# "ausente" por engano. Capturamos a saída e testamos a string em memória.
nerd_font_present() {
    command_exists fc-list || return 1
    local listing
    listing="$(fc-list 2>/dev/null || true)"
    [[ "$listing" == *[Nn]erd\ [Ff]ont* ]]
}

# --- Instala um pacote de Nerd Font a partir do zip do release ---
# Uso: install_nerd_font <NomeDoZip>
install_nerd_font() {
    local name="$1"
    local url="$NF_BASE/${name}.zip"
    local zip="$QXDC_TMPDIR/${name}.zip"
    local extract="$QXDC_TMPDIR/${name}"

    log_info "Nerd Font: $name"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        echo -e "  ${C_YELLOW}[DRY-RUN]${C_RESET} baixar $url → instalar .ttf em $FONT_DIR"
        return 0
    fi

    download_file "$url" "$zip" || {
        log_warn "Falha ao baixar $name. Pulando."
        return 1
    }

    mkdir -p "$extract"
    if ! unzip -o "$zip" -d "$extract" >> "$QXDC_LOG" 2>&1; then
        log_warn "Falha ao extrair $name. Pulando."
        return 1
    fi

    # Instala os .ttf/.otf (ignora README/LICENSE).
    run_sudo mkdir -p "$FONT_DIR"
    local installed=0
    local f
    while IFS= read -r -d '' f; do
        run_sudo cp "$f" "$FONT_DIR/" && installed=$((installed + 1))
    done < <(find "$extract" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0)

    # Se o zip trouxe um .conf de fontconfig (caso do SymbolsOnly), instala como
    # fallback system-wide — faz 'monospace' herdar os ícones automaticamente.
    local conf
    conf="$(find "$extract" -type f -iname '*.conf' | head -n1)"
    if [[ -n "$conf" ]]; then
        run_sudo mkdir -p "$FONTCONFIG_DIR"
        run_sudo cp "$conf" "$FONTCONFIG_DIR/"
        log_info "Fallback fontconfig instalado: $(basename "$conf")"
    fi

    if [[ $installed -gt 0 ]]; then
        log_ok "$name: $installed arquivo(s) de fonte instalado(s)."
    else
        log_warn "$name: nenhum arquivo de fonte encontrado no zip."
        return 1
    fi
}

# --- Main ---
main() {
    log_step "Instalação de Nerd Fonts — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    # Lê lista do perfil; cai no default se a chave não existir.
    # Sanitiza cada item: remove comentário inline (# ...) e espaços nas bordas.
    local -a fonts=()
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && fonts+=("$line")
    done < <(config_get_list "fonts.nerd_fonts" "$QXDC_CONFIG" 2>/dev/null || true)
    if [[ ${#fonts[@]} -eq 0 ]]; then
        fonts=("${DEFAULT_NERD_FONTS[@]}")
    fi

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Nerd Fonts que seriam instaladas em $FONT_DIR:"
        local n
        for n in "${fonts[@]}"; do
            echo "  - $n  ($NF_BASE/${n}.zip)"
        done
        return 0
    fi

    # Idempotência: se já há Nerd Font instalada, só garante o cache e sai.
    if nerd_font_present; then
        log_info "Nerd Fonts já presentes no sistema. Pulando download."
        run_sudo fc-cache -f "$FONT_DIR" 2>/dev/null || run_sudo fc-cache -f
        log_ok "Cache de fontes atualizado."
        return 0
    fi

    # Dependência: unzip (declarado nos perfis, mas garante aqui).
    if ! command_exists unzip; then
        log_info "Instalando dependência: unzip"
        pkg_install unzip || log_warn "Não foi possível instalar unzip automaticamente."
    fi

    local ok=0
    local n
    for n in "${fonts[@]}"; do
        install_nerd_font "$n" && ok=$((ok + 1))
    done

    # Atualiza o cache de fontes do sistema para registrar os novos arquivos.
    log_info "Atualizando cache de fontes (fc-cache)..."
    run_sudo fc-cache -f "$FONT_DIR" 2>/dev/null || run_sudo fc-cache -f

    if [[ $ok -gt 0 ]]; then
        log_ok "$ok/${#fonts[@]} Nerd Font(s) instalada(s)."
        log_info "Para usar no terminal: defina a fonte 'Hack Nerd Font Mono'."
    else
        log_error "Nenhuma Nerd Font pôde ser instalada."
        return 1
    fi

    log_info "Log completo em: $QXDC_LOG"
}

main
