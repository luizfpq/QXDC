# Contribuindo com o QXDC

> Guia para quem quer adicionar suporte a novas distros, criar perfis, ou melhorar módulos existentes.

---

## Estrutura do projeto

```
QXDC/
├── qxdc.sh                    # Entrypoint CLI
├── lib/
│   ├── common.sh              # Logging, flags, is_installed, run()
│   ├── distro.sh              # Detecção de distro, pkg_install/remove/update
│   └── config.sh              # Parser YAML-like
├── modules/
│   ├── packages/              # install.sh, purge.sh
│   ├── desktop/               # theme.sh, settings.sh, wallpaper.sh
│   ├── apps/                  # browser.sh, editor.sh, fastfetch.sh, ...
│   ├── dotfiles/              # deploy.sh + files/
│   └── system/                # hardware.sh, nvidia.sh
├── config/
│   ├── defaults.yml           # Configuração base
│   ├── profiles/              # minimal, full, lab, alpine-live, arch-live
│   └── packages-map/          # Mapeamento Debian → Alpine/Arch (referência)
└── tests/
    └── shellcheck.sh
```

---

## Adicionando suporte a uma nova distro

### 1. Detecção em lib/distro.sh

Adicione o ID da distro no `detect_distro()`:

```bash
case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|pop|elementary|zorin)
        DISTRO_FAMILY="debian"
        ;;
    alpine)
        DISTRO_FAMILY="alpine"
        ;;
    arch|manjaro|endeavouros|garuda)
        DISTRO_FAMILY="arch"
        ;;
    sua-distro)
        DISTRO_FAMILY="sua-familia"
        ;;
esac
```

### 2. Comandos de pacote

Adicione cases nas funções `pkg_install_cmd`, `pkg_remove_cmd` e `pkg_update`:

```bash
sua-familia)
    _arr=(seu-pkg-manager install -y)
    ;;
```

### 3. is_installed em lib/common.sh

Adicione um case para verificar se um pacote está instalado:

```bash
sua-familia)
    seu-pkg-manager query "$1" &>/dev/null
    ;;
```

### 4. Perfil de pacotes

Crie `config/profiles/sua-distro-live.yml` com os nomes corretos dos pacotes na sua distro. O perfil deve ser autocontido (não depender de resolução de nomes em runtime).

### 5. Mapeamento de referência

Crie `config/packages-map/sua-distro.yml` documentando a correspondência entre nomes Debian e sua distro. Isso serve como referência para outros contribuidores.

### 6. Ajustes em módulos

Se um módulo tem lógica específica por família (ex: instalar de `.deb`, usar AUR), adicione um case:

```bash
case "$DISTRO_FAMILY" in
    debian) ... ;;
    alpine) ... ;;
    arch)   ... ;;
    sua-familia) ... ;;
    *) log_error "Não suportado em $DISTRO_FAMILY." ;;
esac
```

---

## Criando um novo perfil

Perfis ficam em `config/profiles/`. Copie um existente e ajuste:

```yaml
# Perfil: meu-perfil
packages:
  install:
    - pacote1
    - pacote2
  purge:
    - lixo1

desktop:
  gtk_theme: Arc-Lighter
  icons: Papirus-Dark
  # ...

apps:
  browser: firefox
  editor: mousepad
```

Use com `./qxdc.sh all install --profile meu-perfil --yes`.

---

## Criando um novo módulo

1. Crie `modules/categoria/acao.sh`
2. Siga o template:

```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/distro.sh"
source "$SCRIPT_DIR/../../lib/config.sh"

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

main() {
    log_step "Meu módulo"
    load_profile "$PROFILE"

    # Sua lógica aqui
    # Use pkg_install, run, run_sudo, log_ok, log_error
}

main
```

3. O módulo será automaticamente acessível via `./qxdc.sh categoria acao`

---

## Convenções

- Use `pkg_install` / `pkg_remove` em vez de chamar apt/pacman/apk diretamente
- Use `run` e `run_sudo` para execução controlada (respeita --dry-run)
- Use `log_info`, `log_ok`, `log_warn`, `log_error` para output
- Teste com `--dry-run` antes de rodar de verdade
- Rode `shellcheck` nos scripts antes de commitar: `bash tests/shellcheck.sh`

---

## Fluxo de contribuição

1. Fork o repositório
2. Crie um branch descritivo: `feature/suporte-void`, `fix/tema-arc-xfwm`
3. Faça suas mudanças seguindo as convenções acima
4. Teste com `--dry-run` e, se possível, numa VM com a distro alvo
5. Abra um Pull Request descrevendo o que foi feito e testado

---

## Distros com suporte atual

| Família | Distros | Gerenciador | Profile |
|---------|---------|-------------|---------|
| debian | Debian 12+, Ubuntu 22.04+, Mint, Pop | apt | full, minimal, lab |
| alpine | Alpine 3.24+ | apk | alpine-live |
| arch | Arch, Manjaro, EndeavourOS | pacman/yay/paru | arch-live |

---

## Links

- [Issues](https://github.com/luizfpq/QXDC/issues)
- [Pull Requests](https://github.com/luizfpq/QXDC/pulls)
- [Wiki do Alpine Linux](https://wiki.alpinelinux.org/)
- [Arch Wiki](https://wiki.archlinux.org/)
