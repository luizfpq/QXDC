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

| Desktop | Aplicacoes |
|---------|-----------|
| ![desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png) | ![apps](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-apps.png) |

| Chrome | LightDM |
|--------|---------|
| ![chrome](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-chrome.png) | ![lightdm](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-lightdm.png) |

## Comeco rapido

### Pre-requisitos

- Um sistema baseado em Debian (Debian 12+, Ubuntu 22.04+) com XFCE instalado
- `git` instalado (se nao tiver: `sudo apt install git`)
- Um usuario com privilegios `sudo`
- Conexao com a internet (pacotes serao baixados)

### Passo 1 — Baixar

Abra um terminal. Voce tem duas opcoes:

**Opcao A — Com git (recomendado):**

```bash
sudo apt install git    # pule se o git ja estiver instalado
git clone https://github.com/luizfpq/QXDC.git
cd QXDC
chmod +x qxdc.sh
```

**Opcao B — Sem git (baixar ZIP):**

Se voce nao tem git e nao quer instalar agora, baixe o ZIP direto:

```bash
wget https://github.com/luizfpq/QXDC/archive/refs/heads/v2.0.zip -O qxdc.zip
unzip qxdc.zip
cd QXDC-v2.0
chmod +x qxdc.sh
```

> Se o `wget` tambem nao estiver disponivel: abra o Firefox, va em https://github.com/luizfpq/QXDC, clique no botao verde "Code" e depois em "Download ZIP". Extraia e abra um terminal dentro da pasta.

### Passo 2 — Visualizar antes (opcional, mas recomendado)

Antes de mudar qualquer coisa, voce pode ver o que o QXDC faria. Isso eh seguro — nada eh instalado ou modificado:

```bash
./qxdc.sh packages install --profile full --dry-run
```

Voce vai ver uma lista de pacotes que seriam instalados. Se parecer bom, siga em frente.

### Passo 3 — Executar

Execute os modulos em ordem. Cada um cuida de uma parte diferente da configuracao:

```bash
# Instalar pacotes essenciais (editores, ferramentas, fontes, utilitarios)
./qxdc.sh packages install --profile full --yes

# Remover pacotes indesejados que vem com o Debian por padrao
./qxdc.sh packages purge --profile full --yes

# Aplicar o tema visual (Arc-Lighter + icones Papirus)
./qxdc.sh desktop theme --profile full --yes

# Configurar comportamento do desktop (workspaces, Thunar, paineis)
./qxdc.sh desktop settings --yes

# Definir o wallpaper (desktop + tela de login)
./qxdc.sh desktop wallpaper --yes

# Instalar Visual Studio Code
./qxdc.sh apps editor --yes

# Instalar navegador + integracao de tema
./qxdc.sh apps browser --profile full --yes

# Instalar fastfetch com logo ASCII customizado
./qxdc.sh apps fastfetch --yes
```

### Passo 4 — Aproveitar

Faca logout e login novamente (ou reinicie) pra ver todas as mudancas aplicadas. Pronto.

### Escolhendo um perfil

Nao sabe qual perfil usar? Versao curta:

- **`full`** — Voce quer um desktop completo e pronto pra trabalhar. Escolha esse na duvida.
- **`minimal`** — Voce so quer os pacotes essenciais, sem mudancas visuais.
- **`lab`** — Voce esta montando uma VM de teste e precisa de ferramentas de debug, nao de um desktop bonito.

## Visual

| Item | Valor | Fonte |
|------|-------|-------|
| GTK/WM Theme | Arc-Lighter | [jnsh/arc-theme](https://github.com/jnsh/arc-theme) |
| Icons | Papirus-Dark | [PapirusDevelopmentTeam/papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) |
| Cor das Pastas | paleorange | [PapirusDevelopmentTeam/papirus-folders](https://github.com/PapirusDevelopmentTeam/papirus-folders) |
| Cores do Terminal | Nighty-Lighter | Baseado no [Gogh-Co/Gogh — Nighty](https://github.com/Gogh-Co/Gogh/blob/master/themes/Nighty.yml) |
| System Fetch | fastfetch | [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Font | Noto Sans 10 | [Google Noto Fonts](https://fonts.google.com/noto) |
| Painel 2 | Dock com ~12% opacidade | — |
| Wallpaper | [QXDC-docs/main-wallpaper.jpg](https://github.com/luizfpq/QXDC-docs) | — |
| LightDM | Mesmo wallpaper + Arc-Lighter | — |

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
│   ├── apps/            # browser.sh, editor.sh, fastfetch.sh
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

## Diagnostico de erros

Quando um modulo falha, o QXDC mostra:

- O exit code do modulo
- As ultimas 5 linhas de stderr inline
- Um resumo final listando todos os modulos que falharam com seus erros

Exemplo de saida com falha:

```
[WARN] [3/9] desktop theme falhou (exit code: 1).

[ERRO] --- Erro em 'desktop theme' (ultimas 5 linhas) ---
  [ERRO] DBUS_SESSION_BUS_ADDRESS nao definido.
  [ERRO] Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus.
[ERRO] --- fim ---

:: Detalhes dos erros
[ERRO] [FALHA] desktop theme
  [ERRO] DBUS_SESSION_BUS_ADDRESS nao definido.
  [ERRO] Rode sem sudo ou com 'sudo -E' para preservar DISPLAY/D-Bus.
```

### Problemas comuns

| Sintoma | Causa | Solucao |
|---------|-------|---------|
| "DBUS_SESSION_BUS_ADDRESS nao definido" | `sudo` sem `-E` ou execucao fora da sessao XFCE | Rode sem sudo (o script pede quando precisa) ou use `sudo -E` |
| "DISPLAY nao definido" | Execucao via SSH ou TTY sem X | Rode dentro de um terminal grafico na sessao XFCE |
| "xfconfd nao esta rodando" | Sessao XFCE nao esta ativa | Faca login grafico no XFCE antes de executar |
| Modulos desktop falham mas packages funciona | Packages so precisa de apt/sudo; desktop precisa de sessao grafica | Normal — rode os modulos desktop depois de logar no XFCE |

### Log

Toda execucao grava em `/tmp/qxdc-YYYYMMDD-HHMMSS.log`. Quando executado via `all install`, todos os modulos compartilham o mesmo arquivo de log.

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
