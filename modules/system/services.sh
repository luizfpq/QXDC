#!/bin/bash
# modules/system/services.sh — Habilita serviços do sistema conforme perfil
# Alpine: rc-update add <service> default
# Debian: systemctl enable <service>
#
# Lê a lista de serviços de packages.services no perfil.
# Uso: ./modules/system/services.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- Habilitar serviço ---
enable_service() {
    local svc="$1"

    case "$DISTRO_FAMILY" in
        alpine)
            if run_sudo rc-update add "$svc" default 2>/dev/null; then
                log_ok "Serviço $svc habilitado (OpenRC)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        debian)
            if run_sudo systemctl enable "$svc" 2>/dev/null; then
                log_ok "Serviço $svc habilitado (systemd)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        arch)
            if run_sudo systemctl enable "$svc" 2>/dev/null; then
                log_ok "Serviço $svc habilitado (systemd)."
            else
                log_warn "Serviço $svc não encontrado ou já habilitado."
            fi
            ;;
        *)
            log_warn "Habilitação de serviços não implementada para $DISTRO_FAMILY."
            return 0
            ;;
    esac
}

# --- Iniciar serviço agora ---
start_service() {
    local svc="$1"

    case "$DISTRO_FAMILY" in
        alpine)
            run_sudo rc-service "$svc" start 2>/dev/null || true
            ;;
        debian|arch)
            run_sudo systemctl start "$svc" 2>/dev/null || true
            ;;
    esac
}

# --- Main ---
main() {
    log_step "Habilitação de serviços — perfil: $PROFILE"
    log_info "Distro: $DISTRO_ID $DISTRO_VERSION ($DISTRO_FAMILY)"

    load_profile "$PROFILE"

    # --- Serviços ---
    mapfile -t services < <(config_get_list "packages.services" "$QXDC_CONFIG")

    if [[ ${#services[@]} -gt 0 ]]; then
        log_info "${#services[@]} serviço(s) a habilitar."

        if [[ "$QXDC_DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Serviços que seriam habilitados:"
            printf "  - %s\n" "${services[@]}"
        else
            for svc in "${services[@]}"; do
                enable_service "$svc"
                start_service "$svc"
            done
        fi
    fi

    # --- Módulos de kernel (Alpine /etc/modules) ---
    mapfile -t kmods < <(config_get_list "packages.kernel_modules" "$QXDC_CONFIG")

    if [[ ${#kmods[@]} -gt 0 ]]; then
        log_step "Módulos de kernel a carregar no boot"

        if [[ "$QXDC_DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] Módulos que seriam adicionados a /etc/modules:"
            printf "  - %s\n" "${kmods[@]}"
        else
            for mod in "${kmods[@]}"; do
                if ! grep -qxF "$mod" /etc/modules 2>/dev/null; then
                    echo "$mod" | run_sudo tee -a /etc/modules > /dev/null
                    log_ok "Módulo $mod adicionado."
                else
                    [[ "$QXDC_VERBOSE" == "true" ]] && log_info "$mod já em /etc/modules."
                fi
            done
        fi
    fi

    # --- Tweaks pós-instalação ---
    mapfile -t tweaks < <(config_get_list "packages.tweaks" "$QXDC_CONFIG")

    if [[ ${#tweaks[@]} -gt 0 ]]; then
        log_step "Aplicando tweaks de sistema"

        for tweak in "${tweaks[@]}"; do
            case "$tweak" in
                lightdm-no-check-graphical)
                    # Alpine: elogind não taga seats como gráficos corretamente
                    local ldm_conf="/etc/lightdm/lightdm.conf"
                    if [[ -f "$ldm_conf" ]]; then
                        if grep -q "^logind-check-graphical=false" "$ldm_conf" 2>/dev/null; then
                            [[ "$QXDC_VERBOSE" == "true" ]] && log_info "lightdm-no-check-graphical já aplicado."
                        elif [[ "$QXDC_DRY_RUN" == "true" ]]; then
                            log_info "[DRY-RUN] Seria setado logind-check-graphical=false em $ldm_conf"
                        else
                            run_sudo sed -i 's/^#*logind-check-graphical=.*/logind-check-graphical=false/' "$ldm_conf"
                            log_ok "LightDM: logind-check-graphical=false"
                        fi
                    fi
                    ;;
                udisks2-plugdev-mount)
                    # Permite grupo plugdev montar discos sem senha via polkit
                    local polkit_rule="/etc/polkit-1/rules.d/10-udisks2.rules"
                    local src_rule="$QXDC_ROOT/modules/dotfiles/files/polkit/10-udisks2.rules"
                    if [[ -f "$polkit_rule" ]]; then
                        [[ "$QXDC_VERBOSE" == "true" ]] && log_info "Regra udisks2 polkit já existe."
                    elif [[ "$QXDC_DRY_RUN" == "true" ]]; then
                        log_info "[DRY-RUN] Seria copiado $src_rule para $polkit_rule"
                    else
                        run_sudo cp "$src_rule" "$polkit_rule"
                        log_ok "Polkit: plugdev pode montar discos sem senha"
                    fi
                    ;;
                *)
                    log_warn "Tweak desconhecido: $tweak"
                    ;;
            esac
        done
    fi

    log_ok "Serviços e sistema configurados."
}

main
