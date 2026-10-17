#!/bin/bash
# modules/dotfiles/deploy.sh — Aplica arquivos de configuração (dotfiles)
# Copia configs prontas de modules/dotfiles/files/ para os destinos corretos.
#
# Uso: ./modules/dotfiles/deploy.sh [--dry-run] [--yes] [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# --- Flags ---
parse_common_flags "$@"

# --- Mapeamento: pasta origem → destino ---
# Destinos de usuário (sem sudo), em $HOME.
declare -A DOTFILE_MAP=(
    ["xfce4-terminal"]="$HOME/.config/xfce4/terminal"
    ["xfce4"]="$HOME/.config/xfce4"
    ["fastfetch"]="$HOME/.config/fastfetch"
    ["autostart"]="$HOME/.config/autostart"
    ["htop"]="$HOME/.config/htop"
)

# Destinos de sistema (exigem sudo). Ex.: regras polkit do udisks2 que permitem
# usuários do grupo plugdev montarem discos sem senha.
declare -A DOTFILE_MAP_SYSTEM=(
    ["polkit"]="/etc/polkit-1/rules.d"
)

# --- Main ---
main() {
    log_step "Deploy de dotfiles"

    local files_dir="$SCRIPT_DIR/files"
    local deployed=0

    if [[ ! -d "$files_dir" ]]; then
        log_error "Diretório de dotfiles não encontrado: $files_dir"
        return 1
    fi

    for src_dir in "$files_dir"/*/; do
        local name
        name="$(basename "$src_dir")"
        local dest="${DOTFILE_MAP[$name]:-}"
        local sys_dest="${DOTFILE_MAP_SYSTEM[$name]:-}"

        # Destino de sistema (sudo) — ex.: polkit
        if [[ -n "$sys_dest" ]]; then
            if [[ "$QXDC_DRY_RUN" == "true" ]]; then
                log_info "[DRY-RUN] $name → $sys_dest (sistema/sudo)"
                continue
            fi
            run_sudo mkdir -p "$sys_dest"
            run_sudo cp -r "$src_dir"* "$sys_dest/"
            log_ok "$name → $sys_dest (sistema)"
            deployed=$((deployed + 1))
            continue
        fi

        if [[ -z "$dest" ]]; then
            log_warn "Destino não mapeado para: $name (pulando)"
            continue
        fi

        if [[ "$QXDC_DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] $name → $dest"
            continue
        fi

        mkdir -p "$dest"
        cp -r "$src_dir"* "$dest/"
        log_ok "$name → $dest"
        deployed=$((deployed + 1))
    done

    if [[ "$QXDC_DRY_RUN" != "true" ]]; then
        log_ok "$deployed dotfile(s) aplicado(s)."
    fi
}

main
