#!/bin/bash
# modules/apps/stremio.sh — Instala Stremio (media center/streaming)
# Método: .deb oficial + dependências manuais
#
# O .deb do Stremio (v4.4.168) declara dependências que precisam de tratamento:
#   - Pacotes QML (Qt5), nodejs, libfdk-aac2 → disponíveis nos repos Debian 13
#   - libmpv1 → NÃO existe no Debian 13 (tem libmpv2, ABI compatível)
#   - libssl1.1 → NÃO existe nos repos (Debian 13 usa OpenSSL 3)
#
# Estratégia:
#   1. Instalar todas as dependências que existem nos repos (QML, nodejs, etc.)
#   2. Instalar libssl1.1 de fonte externa (Ubuntu mirrors)
#   3. Instalar libmpv2 + criar symlink libmpv.so.1 → libmpv.so.2
#   4. Instalar stremio.deb via dpkg --force-depends (só libmpv1 fica pendente)
#   5. Marcar a dependência libmpv1 como satisfeita (equivs ou hold)
#
# Uso: ./modules/apps/stremio.sh [--dry-run] [--yes] [--verbose] [--profile <nome>]

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

# --- URLs ---
STREMIO_DEB_URL="https://dl.strem.io/shell-linux/v4.4.168/stremio_4.4.168-1_amd64.deb"
LIBSSL_URL="http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"

# Dependências que existem nos repos Debian 13
REPO_DEPS=(
    nodejs
    libmpv2
    libfdk-aac2t64
    qml-module-qt-labs-platform
    qml-module-qtquick-controls
    qml-module-qtquick-dialogs
    qml-module-qtwebchannel
    qml-module-qtwebengine
    qml-module-qt-labs-folderlistmodel
    qml-module-qt-labs-settings
)

# --- Instalar dependências dos repositórios ---
install_repo_dependencies() {
    log_step "Instalando dependências do Stremio (repositórios Debian)"

    local to_install=()

    for pkg in "${REPO_DEPS[@]}"; do
        if ! is_installed "$pkg" 2>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log_info "Todas as dependências dos repos já instaladas."
        return 0
    fi

    log_info "Pacotes a instalar: ${to_install[*]}"
    run_sudo apt-get install -qq -y "${to_install[@]}"

    if [[ $? -ne 0 ]]; then
        log_error "Falha ao instalar dependências dos repos."
        return 1
    fi

    log_ok "Dependências dos repos instaladas."
}

# --- Instalar libssl1.1 (externa) ---
install_libssl() {
    log_step "Instalando libssl1.1 (externa)"

    if is_installed libssl1.1 2>/dev/null; then
        log_info "libssl1.1 já instalado."
        return 0
    fi

    local tmp_deb="/tmp/libssl1.1.deb"

    log_info "Baixando libssl1.1..."
    run wget -q -O "$tmp_deb" "$LIBSSL_URL"

    log_info "Instalando libssl1.1..."
    run_sudo apt-get install -qq -y "$tmp_deb"

    run rm -f "$tmp_deb"
    log_ok "libssl1.1 instalado."
}

# --- Criar symlink de compatibilidade libmpv ---
fix_libmpv_symlink() {
    log_step "Criando symlink de compatibilidade libmpv.so.1"

    local libdir="/usr/lib/x86_64-linux-gnu"

    # Se já existe, nada a fazer
    if [[ -e "$libdir/libmpv.so.1" ]]; then
        log_info "libmpv.so.1 já existe."
        return 0
    fi

    local target
    target="$(find "$libdir" -name 'libmpv.so.2*' -type f 2>/dev/null | head -1)"

    if [[ -z "$target" ]]; then
        target="$(find /usr/lib -name 'libmpv.so.2*' -type f 2>/dev/null | head -1)"
    fi

    if [[ -n "$target" ]]; then
        log_info "Symlink: libmpv.so.1 → $(basename "$target")"
        run_sudo ln -sf "$target" "$libdir/libmpv.so.1"
        run_sudo ldconfig
        log_ok "Symlink criado."
    else
        log_error "libmpv.so.2 não encontrada. Instale libmpv2 primeiro."
        return 1
    fi
}

# --- Instalar Stremio via .deb ---
install_stremio() {
    log_step "Instalando Stremio"

    if command_exists stremio || is_installed stremio 2>/dev/null; then
        log_info "Stremio já instalado."
        return 0
    fi

    local tmp_deb="/tmp/stremio.deb"

    log_info "Baixando Stremio .deb..."
    run wget -q -O "$tmp_deb" "$STREMIO_DEB_URL"

    # dpkg --force-depends: a única dependência não resolvível é libmpv1,
    # que é satisfeita pelo symlink libmpv.so.1 → libmpv.so.2
    log_info "Instalando Stremio (dpkg --force-depends para libmpv1)..."
    run_sudo dpkg --force-depends -i "$tmp_deb"

    run rm -f "$tmp_deb"

    # Verificar se o binário está acessível
    if command_exists stremio; then
        log_ok "Stremio instalado com sucesso."
    elif [[ -x /opt/stremio/stremio ]]; then
        log_ok "Stremio instalado em /opt/stremio/stremio."
    else
        log_warn "Stremio instalado mas binário não localizado."
        log_info "Procure em: /opt/stremio/ ou /usr/bin/"
    fi
}

# --- Main ---
main() {
    log_step "Instalação do Stremio — perfil: $PROFILE"

    load_profile "$PROFILE"

    if [[ "$QXDC_DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Stremio — método: deb + dpkg --force-depends"
        log_info "[DRY-RUN] Deps repos: ${REPO_DEPS[*]}"
        log_info "[DRY-RUN] Deps externas: libssl1.1 + symlink libmpv.so.1→2"
        log_info "[DRY-RUN] URL: $STREMIO_DEB_URL"
        return 0
    fi

    install_repo_dependencies || exit 1
    install_libssl || exit 1
    fix_libmpv_symlink || exit 1
    install_stremio
}

main
