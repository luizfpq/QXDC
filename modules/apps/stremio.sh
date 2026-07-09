#!/bin/bash
# modules/apps/stremio.sh — Instala Stremio (media center/streaming)
# Método: .deb oficial + dependências manuais + pacote virtual libmpv1
#
# O .deb do Stremio (v4.4.168) declara dependências que precisam de tratamento:
#   - Pacotes QML (Qt5), nodejs, libfdk-aac2 → disponíveis nos repos Debian 13
#   - libmpv1 → NÃO existe no Debian 13 (tem libmpv2, ABI compatível)
#   - libssl1.1 → NÃO existe nos repos (Debian 13 usa OpenSSL 3)
#
# Estratégia:
#   1. Instalar equivs (para criar pacote virtual)
#   2. Instalar todas as dependências que existem nos repos (QML, nodejs, etc.)
#   3. Instalar libssl1.1 de fonte externa (Ubuntu mirrors)
#   4. Instalar libmpv2 + criar symlink libmpv.so.1 → libmpv.so.2
#   5. Criar e instalar pacote virtual libmpv1 (equivs) → satisfaz dpkg/apt
#   6. Instalar stremio.deb normalmente via apt (dependências resolvidas)
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
    equivs
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

# --- Limpar instalação quebrada anterior ---
cleanup_broken_stremio() {
    # Se stremio está instalado mas libmpv1 não está satisfeita, o apt trava.
    # O dpkg marca como 'ii' mesmo com --force-depends, mas o apt detecta o problema.
    if is_installed stremio 2>/dev/null; then
        if ! is_installed libmpv1 2>/dev/null; then
            log_warn "Stremio instalado mas libmpv1 não satisfeita. Removendo para reinstalar limpo..."
            run_sudo dpkg --purge --force-depends stremio
            run_sudo dpkg --configure -a
            run_sudo apt --fix-broken install -y
            log_ok "Instalação anterior do Stremio removida. Apt limpo."
        fi
    else
        # Stremio não instalado — garantir que o apt está saudável
        check_apt_health || return 1
    fi
}

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

    if ! run_sudo apt-get install -qq -y "${to_install[@]}"; then
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

    local tmp_deb="${QXDC_TMPDIR}/libssl1.1.deb"

    download_file "$LIBSSL_URL" "$tmp_deb" || return 1

    log_info "Instalando libssl1.1..."
    run_sudo apt-get install -qq -y "$tmp_deb"

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

# --- Criar pacote virtual libmpv1 via equivs ---
# Isso satisfaz a dependência do Stremio no dpkg/apt sem poluir o sistema.
create_libmpv1_virtual() {
    log_step "Criando pacote virtual libmpv1 (equivs)"

    if is_installed libmpv1 2>/dev/null; then
        log_info "libmpv1 já satisfeito (pacote virtual ou real)."
        return 0
    fi

    local workdir="/tmp/qxdc-equivs-libmpv1"
    run rm -rf "$workdir"
    run mkdir -p "$workdir"

    cat > "$workdir/libmpv1-compat" <<'CTRL'
Section: libs
Priority: optional
Standards-Version: 3.9.2
Package: libmpv1
Version: 0.99.0~compat
Provides: libmpv1
Depends: libmpv2
Architecture: amd64
Description: Compatibility shim for libmpv1 (QXDC)
 Debian 13 ships libmpv2. This virtual package satisfies packages that
 depend on libmpv1 while the ABI-compatible symlink is in place.
CTRL

    log_info "Construindo pacote virtual..."
    run bash -c "cd '$workdir' && equivs-build libmpv1-compat"

    local built_deb
    built_deb="$(find "$workdir" -name 'libmpv1_*.deb' -type f | head -1)"

    if [[ -z "$built_deb" ]]; then
        log_error "equivs-build falhou. Verifique se equivs está instalado."
        run rm -rf "$workdir"
        return 1
    fi

    log_info "Instalando pacote virtual libmpv1..."
    run_sudo apt-get install -qq -y "$built_deb"

    run rm -rf "$workdir"
    log_ok "Pacote virtual libmpv1 instalado — dependência satisfeita."
}

# --- Instalar Stremio via .deb ---
install_stremio() {
    log_step "Instalando Stremio"

    if command_exists stremio || is_installed stremio 2>/dev/null; then
        log_info "Stremio já instalado."
        return 0
    fi

    local tmp_deb="${QXDC_TMPDIR}/stremio.deb"

    download_file "$STREMIO_DEB_URL" "$tmp_deb" || return 1

    # Com o pacote virtual libmpv1 instalado, apt resolve tudo limpo
    log_info "Instalando Stremio..."
    run_sudo apt-get install -qq -y "$tmp_deb"

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
        log_info "[DRY-RUN] Stremio — método: deb + pacote virtual libmpv1 (equivs)"
        log_info "[DRY-RUN] Deps repos: ${REPO_DEPS[*]}"
        log_info "[DRY-RUN] Deps externas: libssl1.1 + symlink libmpv.so.1→2 + equivs libmpv1"
        log_info "[DRY-RUN] URL: $STREMIO_DEB_URL"
        return 0
    fi

    cleanup_broken_stremio
    install_repo_dependencies || exit 1
    install_libssl || exit 1
    fix_libmpv_symlink || exit 1
    create_libmpv1_virtual || exit 1
    install_stremio
}

main
