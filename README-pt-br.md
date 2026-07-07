# QXDC — Quirino's XFCE Default Config

> Configuracao automatizada e opinativa de desktop XFCE para Debian.
> Porque reinstalar o sistema nao deveria significar perder duas horas clicando em menus.

---

![Desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png)

## Por que

A gente ja tem mods e estilos de sobra pros nossos desktops. Mas eu geralmente preciso reinstalar e reinventar minhas opcoes de usabilidade do zero, e nao quero usar nenhuma das "Refisefuquis"<sup>1</sup> disponiveis por ai. O QXDC eh a minha resposta: um configurador de desktop reproduzivel, nao-interativo, que faz exatamente o que eu quero e nada mais.

## O que faz

QXDC transforma um Debian recem-instalado com XFCE num desktop produtivo em poucos minutos. Sem assistente grafico, sem perguntas bobas, sem wallpapers de paisagem suica que ninguem pediu.

Instala pacotes, configura tema, ajusta paineis, aplica dotfiles e remove o lixo que vem de brinde — tudo via CLI, tudo reproduzivel, tudo versionado.

## Screenshots

| Desktop | Aplicacoes | Chrome | LightDM |
|---------|-----------|--------|---------|
| ![desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png) | ![apps](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-apps.png) | ![chrome](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-chrome.png) | ![lightdm](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-lightdm.png) |

## Comeco rapido

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
| GTK/WM Theme | Arc-Lighter |
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
│   ├── distro.sh        # Deteccao de distro e pkg manager
│   └── config.sh        # Parser de configuracao YAML-like
├── modules/             # Modulos independentes
│   ├── packages/        # install.sh, purge.sh
│   ├── desktop/         # theme.sh, settings.sh, wallpaper.sh
│   ├── apps/            # browser.sh, editor.sh
│   ├── dotfiles/        # files/ (configs prontas)
│   └── system/          # (futuro: sources, firmware)
├── config/
│   ├── defaults.yml     # Configuracao padrao
│   └── profiles/        # minimal, full, lab
└── tests/
    └── shellcheck.sh    # Lint
```

## Perfis

| Perfil | Pra que |
|--------|---------|
| `minimal` | O minimo pra nao sofrer. Pacotes essenciais e so. |
| `full` | Desktop produtivo completo com tudo configurado. |
| `lab` | VM de laboratorio — ferramentas de debug, sem frescura visual. |

## Flags

| Flag | O que faz |
|------|-----------|
| `--dry-run` | Mostra o que faria sem executar nada |
| `--yes` / `-y` | Pula confirmacoes (ideal pra scripts) |
| `--verbose` / `-v` | Saida detalhada |
| `--profile <p>` | Escolhe o perfil |

## Suporte

- **Primario:** Debian 12+, Debian 13 (trixie) — XFCE 4.20
- **Secundario:** Ubuntu 22.04+, derivados Debian
- **Best-effort:** Arch Linux

## Historico

O QXDC nasceu em 2021 como um script bash monolitico pra resolver um problema simples: eu reinstalo Debian com frequencia e toda vez perdia tempo configurando a mesma coisa. Ao longo dos anos ele cresceu, ficou baguncado, tentei migrar pra Ansible (ironqui), tentei separar assets (QXDC-docs), tentei fazer um kit de ferramentas separado (lftk). Nenhuma dessas tentativas resolveu o problema central.

A versao 2.0 eh uma reescrita do zero com a licao aprendida: **modular, declarativo, sem interatividade**. Cada modulo faz uma coisa, cada perfil define o que instalar, e `--dry-run` existe pra quando voce quer ver antes de fazer.

## Repositorios relacionados

| Repo | Status | Relacao |
|------|--------|---------|
| [QXDC-docs](https://github.com/luizfpq/QXDC-docs) | Ativo | Assets estaticos (wallpapers, screenshots) |
| [lftk](https://github.com/luizfpq/lftk) | Ativo | Kit de ferramentas complementar (server/infra) |
| [ironqui](https://github.com/luizfpq/ironqui) | Arquivado | Tentativa anterior com Ansible (absorvido pelo QXDC 2.0) |

## Licenca

MIT

---

<sup>1</sup> **Refisefuquis** — "Release de Fim de Semana e Fundo de Quintal". Em palavras simples: releases sem suporte, sem inovacao e sem proposito — apenas uma aventura caseira de um desenvolvedor com tempo e um computador disponivel. O QXDC eh orgulhosamente uma dessas, exceto que esse aqui funciona de verdade.
