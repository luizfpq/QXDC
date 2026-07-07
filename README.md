# QXDC — Quirino's XFCE Default Config

> Configuração automatizada e opinativa de desktop XFCE para Debian.
> Porque reinstalar o sistema não deveria significar perder duas horas clicando em menus.

---

![Desktop limpo](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png)

## O que é

QXDC transforma um Debian recém-instalado com XFCE num desktop produtivo em poucos minutos. Sem assistente gráfico, sem perguntas bobas, sem wallpapers de paisagem suíça que ninguém pediu.

Instala pacotes, configura tema, ajusta painéis, aplica dotfiles e remove o lixo que vem de brinde — tudo via CLI, tudo reproduzível, tudo versionado.

## Screenshots

| Desktop | Aplicações | Chrome | LightDM |
|---------|-----------|--------|---------|
| ![desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png) | ![apps](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-apps.png) | ![chrome](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-chrome.png) | ![lightdm](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-lightdm.png) |

## Começo rápido

```bash
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
chmod +x qxdc.sh

# Ver o que seria feito (dry-run)
./qxdc.sh packages install --profile full --dry-run

# Executar de verdade
./qxdc.sh packages install --profile full --yes
./qxdc.sh desktop theme --profile full --yes
./qxdc.sh desktop settings --yes
./qxdc.sh desktop wallpaper --yes
./qxdc.sh apps editor --yes
./qxdc.sh apps browser --profile full --yes
```

## Visual

| Item | Valor |
|------|-------|
| GTK Theme | Arc-Lighter |
| WM Theme | Arc-Lighter |
| Icons | Papirus-Dark + papirus-folders (paleorange) |
| Terminal | Nighty-Lighter (fundo #e7e8eb, texto #2e3440) |
| Font | Noto Sans 10 |
| Wallpaper | [QXDC-docs/main-wallpaper.jpg](https://github.com/luizfpq/QXDC-docs) |
| LightDM | Mesmo wallpaper + Arc-Lighter |
| Painel 2 | Dock com ~12% opacidade |

## Estrutura

```
QXDC/
├── qxdc.sh              # Entrypoint (CLI)
├── lib/                 # Bibliotecas compartilhadas
│   ├── common.sh        # Log, cores, flags, dry-run
│   ├── distro.sh        # Detecção de distro e pkg manager
│   └── config.sh        # Parser de configuração YAML-like
├── modules/             # Módulos independentes
│   ├── packages/        # install.sh, purge.sh
│   ├── desktop/         # theme.sh, settings.sh, wallpaper.sh
│   ├── apps/            # browser.sh, editor.sh
│   ├── dotfiles/        # files/ (configs prontas)
│   └── system/          # (futuro: sources, firmware)
├── config/
│   ├── defaults.yml     # Configuração padrão
│   └── profiles/        # minimal, full, lab
└── tests/
    └── shellcheck.sh    # Lint
```

## Perfis

| Perfil | Pra que |
|--------|---------|
| `minimal` | O mínimo pra não sofrer. Pacotes essenciais e só. |
| `full` | Desktop produtivo completo com tudo configurado. |
| `lab` | VM de laboratório — ferramentas de debug, sem frescura visual. |

## Flags

| Flag | O que faz |
|------|-----------|
| `--dry-run` | Mostra o que faria sem executar nada |
| `--yes` / `-y` | Pula confirmações (ideal pra scripts) |
| `--verbose` / `-v` | Saída detalhada |
| `--profile <p>` | Escolhe o perfil |

## Suporte

- **Primário:** Debian 12+, Debian 13 (trixie) — XFCE 4.20
- **Secundário:** Ubuntu 22.04+, derivados Debian
- **Best-effort:** Arch Linux

## Histórico

O QXDC nasceu em 2021 como um script bash monolítico pra resolver um problema simples: eu reinstalo Debian com frequência e toda vez perdia tempo configurando a mesma coisa. Ao longo dos anos ele cresceu, ficou bagunçado, tentei migrar pra Ansible (ironqui), tentei separar assets (QXDC-docs), tentei fazer um kit de ferramentas separado (lftk). Nenhuma dessas tentativas resolveu o problema central.

A versão 2.0 é uma reescrita do zero com a lição aprendida: **modular, declarativo, sem interatividade**. Cada módulo faz uma coisa, cada perfil define o que instalar, e `--dry-run` existe pra quando você quer ver antes de fazer.

## Repositórios relacionados

| Repo | Status | Relação |
|------|--------|---------|
| [QXDC-docs](https://github.com/luizfpq/QXDC-docs) | Ativo | Assets estáticos (wallpapers, screenshots) |
| [lftk](https://github.com/luizfpq/lftk) | Ativo | Kit de ferramentas complementar (server/infra) |
| [ironqui](https://github.com/luizfpq/ironqui) | Arquivado | Tentativa anterior com Ansible (absorvido pelo QXDC 2.0) |

## Licença

MIT

---

# QXDC — Quirino's XFCE Default Config (English)

> Opinionated, automated XFCE desktop configuration for Debian.
> Because reinstalling your OS shouldn't mean spending two hours clicking through settings.

---

## What is this

QXDC turns a fresh Debian + XFCE install into a productive desktop in minutes. No GUI wizards, no dumb questions, no Swiss landscape wallpapers nobody asked for.

It installs packages, configures themes, adjusts panels, deploys dotfiles, and removes bloat — all via CLI, all reproducible, all versioned.

## Quick start

```bash
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
chmod +x qxdc.sh

# Dry-run first
./qxdc.sh packages install --profile full --dry-run

# Then for real
./qxdc.sh packages install --profile full --yes
./qxdc.sh desktop theme --profile full --yes
./qxdc.sh desktop settings --yes
./qxdc.sh desktop wallpaper --yes
./qxdc.sh apps editor --yes
./qxdc.sh apps browser --profile full --yes
```

## Look and feel

| Item | Value |
|------|-------|
| GTK/WM Theme | Arc-Lighter |
| Icons | Papirus-Dark + papirus-folders (paleorange) |
| Terminal | Nighty-Lighter (bg #e7e8eb, fg #2e3440) |
| Font | Noto Sans 10 |
| Panel 2 | Dock with ~12% opacity |

## Profiles

| Profile | Purpose |
|---------|---------|
| `minimal` | Bare minimum to not suffer |
| `full` | Full productive desktop |
| `lab` | Test VM — debug tools, no visual frills |

## Flags

| Flag | Effect |
|------|--------|
| `--dry-run` | Preview without executing |
| `--yes` / `-y` | Skip confirmations |
| `--verbose` / `-v` | Detailed output |
| `--profile <p>` | Select configuration profile |

## Supported systems

- **Primary:** Debian 12+, Debian 13 (trixie) — XFCE 4.20
- **Secondary:** Ubuntu 22.04+, Debian derivatives
- **Best-effort:** Arch Linux

## Background

QXDC started in 2021 as a monolithic bash script to solve a simple problem: I reinstall Debian often and waste time configuring the same stuff every time. Over the years it grew messy, I tried migrating to Ansible (ironqui), separating assets (QXDC-docs), and building a separate toolkit (lftk). None of those solved the core issue.

Version 2.0 is a ground-up rewrite with lessons learned: **modular, declarative, non-interactive**. Each module does one thing, each profile defines what to install, and `--dry-run` exists for when you want to look before you leap.

## License

MIT
