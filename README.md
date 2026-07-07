# QXDC — Quirino's XFCE Default Config

> Configurador modular de desktop XFCE para Debian/derivados.

---

## Visão Geral

O QXDC automatiza a configuração de um desktop XFCE do zero: instalação de pacotes, temas, ícones, painéis, dotfiles e aplicativos. Projetado para ser executável sem interatividade (CI-friendly) e com suporte a perfis de configuração.

## Início Rápido

```bash
git clone https://github.com/luizfpq/QXDC.git && cd QXDC
chmod +x qxdc.sh

# Dry-run — ver o que seria feito
./qxdc.sh packages install --profile minimal --dry-run

# Executar de verdade
./qxdc.sh packages install --profile minimal --yes
```

## Estrutura

```
QXDC/
├── qxdc.sh              # Entrypoint (CLI)
├── lib/                 # Bibliotecas compartilhadas
│   ├── common.sh        # Log, cores, flags, verificações
│   ├── distro.sh        # Detecção de distro e pkg manager
│   └── config.sh        # Parser de configuração YAML-like
├── modules/             # Módulos independentes
│   ├── packages/        # install.sh, purge.sh
│   ├── desktop/         # theme.sh, panel.sh, wallpaper.sh
│   ├── apps/            # browser.sh, editor.sh
│   ├── dotfiles/        # deploy.sh + files/
│   └── system/          # sources.sh, firmware.sh
├── config/
│   ├── defaults.yml     # Configuração padrão
│   └── profiles/        # Perfis: minimal, full, lab
└── tests/               # Lint e testes
```

## Perfis

| Perfil | Descrição |
|--------|-----------|
| `minimal` | Apenas o essencial para desktop funcional |
| `full` | Desktop produtivo com ferramentas dev e multimídia |
| `lab` | VM de laboratório — ferramentas de debug/dev, sem extras visuais |

## Flags Globais

| Flag | Descrição |
|------|-----------|
| `--dry-run` | Mostra o que faria sem executar |
| `--yes` / `-y` | Pula confirmações |
| `--verbose` / `-v` | Saída detalhada |
| `--profile <p>` | Seleciona perfil (minimal, full, lab) |

## Suporte

- **Primário:** Debian 12+, Debian 13 (trixie)
- **Secundário:** Ubuntu 22.04+, derivados Debian
- **Best-effort:** Arch Linux

## Licença

MIT
