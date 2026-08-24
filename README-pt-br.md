# QXDC — Quirino's XFCE Default Config

> Configuracao automatizada e opinativa de desktop XFCE para Debian, Alpine e Arch.
> Porque reinstalar o sistema nao deveria significar perder duas horas clicando em menus.

---

![Desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png)

## Por que

A gente ja tem mods e estilos de sobra pros nossos desktops. Mas eu geralmente preciso reinstalar e reinventar minhas opcoes de usabilidade do zero, e nao quero usar nenhuma das "Refisefuquis"<sup>1</sup> disponiveis por ai. O QXDC eh a minha resposta: um configurador de desktop reproduzivel, nao-interativo, que faz exatamente o que eu quero e nada mais.

## O que faz

QXDC transforma uma instalacao Linux fresca num desktop XFCE produtivo em poucos minutos. Sem assistente grafico, sem perguntas bobas, sem wallpapers de paisagem suica que ninguem pediu.

Instala pacotes, configura tema, ajusta paineis, aplica dotfiles, habilita servicos e remove o lixo que vem de brinde. Tudo via CLI, tudo reproduzivel, tudo versionado. Funciona em Debian, Alpine e Arch.

## Distribuicoes suportadas

| Familia | Distros | Gerenciador | Perfil |
|---------|---------|-------------|--------|
| Debian | Debian 12+, Ubuntu 22.04+, Mint, Pop | apt | `full`, `minimal`, `lab` |
| Alpine | Alpine 3.24+ | apk | `alpine-live` |
| Arch | Arch, Manjaro, EndeavourOS | pacman/yay | `arch-live` |

## Comeco rapido

### Instalador interativo (recomendado)

```bash
git clone https://github.com/luizfpq/QXDC.git
cd QXDC
./install.sh
```

O instalador detecta a distro, sugere o perfil correto e guia voce pelo processo. Mostra o que vai fazer antes de executar.

Flags:
- `./install.sh --auto` — pula perguntas, detecta tudo automaticamente
- `./install.sh --dry-run` — preview sem executar nada

### Alpine Linux (a partir de instalacao base)

```bash
apk add git bash
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
./install.sh
```

O perfil `alpine-live` instala a stack completa de desktop: Xorg, XFCE4, LightDM, Pipewire, NetworkManager, drivers, tema e apps. Leva o Alpine de um sistema base puro ate um desktop grafico completo.

### Arch Linux

```bash
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
./install.sh
```

### Debian (tradicional)

```bash
sudo apt install git
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
./install.sh
```

### Manual (avancado)

Rode modulos individuais:

```bash
./qxdc.sh packages install --profile full --yes
./qxdc.sh desktop theme --profile full --yes
./qxdc.sh system services --profile alpine-live --yes
./qxdc.sh apps browser --profile full --yes
```

Preview antes de rodar:

```bash
./qxdc.sh all install --profile alpine-live --dry-run
```

## Visual

| Item | Valor | Fonte |
|------|-------|-------|
| GTK/WM Theme | Arc-Lighter | [jnsh/arc-theme](https://github.com/jnsh/arc-theme) |
| Icons | Papirus-Dark | [PapirusDevelopmentTeam/papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) |
| Cor das Pastas | paleorange | [PapirusDevelopmentTeam/papirus-folders](https://github.com/PapirusDevelopmentTeam/papirus-folders) |
| Cores do Terminal | Nighty-Lighter | Baseado no [Gogh-Co/Gogh](https://github.com/Gogh-Co/Gogh/blob/master/themes/Nighty.yml) |
| System Fetch | fastfetch | [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Font | Noto Sans 10 | [Google Noto Fonts](https://fonts.google.com/noto) |
| Painel 2 | Dock com ~12% opacidade | |
| Wallpaper | [QXDC-docs/main-wallpaper.jpg](https://github.com/luizfpq/QXDC-docs) | |
| LightDM | Mesmo wallpaper + Arc-Lighter | |

## Estrutura

```
QXDC/
├── install.sh               # Instalador interativo (v2.3+)
├── qxdc.sh                  # Entrypoint CLI (uso avancado)
├── lib/
│   ├── common.sh            # Log, cores, flags, run(), run_sudo()
│   ├── distro.sh            # Deteccao de distro, pkg_install/remove/update
│   └── config.sh            # Parser de configuracao YAML-like
├── modules/
│   ├── packages/            # install.sh, purge.sh
│   ├── desktop/             # theme.sh, settings.sh, wallpaper.sh
│   ├── apps/                # browser.sh, editor.sh, fastfetch.sh, ...
│   ├── dotfiles/            # files/ (configs prontas)
│   └── system/              # services.sh, hardware.sh, nvidia.sh
├── config/
│   ├── defaults.yml         # Configuracao padrao (Debian)
│   ├── profiles/            # minimal, full, lab, alpine-live, arch-live
│   └── packages-map/        # Mapeamento Debian->Alpine/Arch (referencia)
├── CONTRIBUTING.md          # Guia para contribuidores
└── tests/
    └── shellcheck.sh        # Lint
```

## Perfis

| Perfil | Alvo | O que faz |
|--------|------|-----------|
| `full` | Debian com XFCE | Desktop produtivo completo, tudo configurado |
| `minimal` | Debian com XFCE | Pacotes essenciais, sem mudancas visuais |
| `lab` | Debian VM | Ferramentas de debug, sem frescura visual |
| `alpine-live` | Alpine (base) | Stack completa: Xorg + XFCE + LightDM + drivers + servicos + apps |
| `arch-live` | Arch (base) | Stack completa: mesmo que alpine-live com nomes pacman |

## Suporte multi-distro

O QXDC detecta a distro rodando e se adapta:

- **Gerenciador de pacotes:** apt (Debian), apk (Alpine), pacman/yay (Arch)
- **Elevacao de privilegio:** sudo (Debian/Arch), doas (Alpine), ou nenhum se ja root
- **Gerenciador de servicos:** systemd (Debian/Arch), OpenRC (Alpine)
- **Repositorios:** habilita contrib+non-free (Debian), community+testing (Alpine)
- **Modulos Debian-only:** stremio, heroic pulam graciosamente em outras distros

## Flags

| Flag | O que faz |
|------|-----------| 
| `--dry-run` | Mostra o que faria sem executar nada |
| `--yes` / `-y` | Pula confirmacoes (ideal pra scripts) |
| `--verbose` / `-v` | Saida detalhada |
| `--profile <p>` | Escolhe o perfil |

## Diagnostico de erros

Quando um modulo falha, o QXDC mostra:
- O exit code do modulo
- As ultimas 5 linhas de stderr inline
- Um resumo final com todos os modulos que falharam

Logs sao escritos em `/tmp/qxdc-YYYYMMDD-HHMMSS.log`. Logs por modulo ficam em `/tmp/qxdc-modules/`.

### Problemas comuns

| Sintoma | Causa | Solucao |
|---------|-------|---------|
| "DBUS_SESSION_BUS_ADDRESS not defined" | Rodando fora de sessao XFCE | Rode modulos desktop depois de logar no XFCE |
| "sudo/doas: command not found" | Nenhum instalado | Instale um deles, ou rode como root |
| "doas: a tty is required" | Sessao nao-interativa com `persist` | Use `permit nopass :wheel` no doas.conf ou rode como root |
| Modulos desktop falham mas packages funciona | Sem sessao grafica | Esperado. Pacotes instalam primeiro, tema aplica depois do login |
| "no such package" no Alpine | Falta repo testing | QXDC habilita automaticamente via `enable_nonfree_repos` |

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md) pra instrucoes sobre como adicionar suporte a novas distros, criar perfis e escrever modulos.

## Historico

O QXDC comecou em 2021 como um script bash monolitico. A versao 2.0 foi uma reescrita do zero: **modular, declarativo, sem interatividade**. A partir da v2.1, expandiu pra Alpine e Arch, tornando-se um configurador de desktop verdadeiramente agnostico de distro.

## Repositorios relacionados

| Repo | Status | Relacao |
|------|--------|---------|
| [QXDC-docs](https://github.com/luizfpq/QXDC-docs) | Ativo | Assets estaticos (wallpapers, screenshots) |
| [lftk](https://github.com/luizfpq/lftk) | Ativo | Kit de ferramentas complementar (server/infra) |
| [ironqui](https://github.com/luizfpq/ironqui) | Arquivado | Tentativa anterior com Ansible (absorvido pelo QXDC 2.0) |

## Licenca

MIT

---

<sup>1</sup> **Refisefuquis** — "Release de Fim de Semana e Fundo de Quintal". Em palavras simples: releases sem suporte, sem inovacao e sem proposito. O QXDC eh orgulhosamente uma dessas, exceto que esse aqui funciona de verdade.
