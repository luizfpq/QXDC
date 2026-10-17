# Changelog

Todas as mudancas notaveis neste projeto estao documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versionamento segue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.6.1] - 2026-10-17

### Fixed
- `modules/all/install.sh`: captura de exit code dos módulos corrigida. A
  sequência `... | tee "$log" || exit_code=${PIPESTATUS[0]}` seguida de
  `exit_code=${PIPESTATUS[0]:-...}` lia o `PIPESTATUS` **após** o `||`, sempre 0 —
  módulos que falhavam (ex.: desktop sem sessão XFCE) eram reportados como
  "concluído". Agora captura `PIPESTATUS[0]` imediatamente após o pipe, com
  `set +e/-e` em volta para registrar a falha e seguir os demais módulos.
- `lib/common.sh` (`check_desktop_session`): se `xfconfd` não está rodando mas
  `DISPLAY`+`DBUS` estão presentes, tenta **ativá-lo via D-Bus** (serviço
  activatable) antes de falhar. Permite rodar os módulos de desktop via SSH
  (com ambiente exportado) sem um terminal aberto na sessão XFCE.
- `modules/desktop/settings.sh`: leitura de `plugin-ids` do painel usava
  `tr -d '[:space:]'`, que removia também as quebras de linha e concatenava os
  IDs num número gigante (ex.: `1,2,3` → `123`), estourando o range de `gint32`
  no `xfconf-query`. Troca por `sed` que remove só espaços/tabs laterais,
  preservando um ID por linha.
- `modules/dotfiles/deploy.sh`: adicionado mapa de destinos de sistema
  (`DOTFILE_MAP_SYSTEM`) com suporte a sudo. A regra polkit `10-udisks2.rules`
  (montagem de discos por `plugdev` sem senha) antes era pulada por "destino não
  mapeado"; agora é instalada em `/etc/polkit-1/rules.d/`.
- `lib/common.sh`: `log_info`/`log_ok`/`log_step` agora escrevem em **stderr**
  (antes stdout). Logs no stdout contaminavam funções que "retornam" valor via
  `echo` capturadas por `$(...)` — causava o `background=` do greeter receber
  `[INFO] Baixando: ...` junto do path e quebrar o parse do
  `lightdm-gtk-greeter.conf` (tela de login sem wallpaper / warning no boot).
- `desktop/wallpaper.sh`: `download_wallpaper` usa `printf` e documenta o
  contrato stdout-only; `apply_login_wallpaper` valida que o caminho é um
  arquivo único existente antes de gravar `background=` (blindagem do greeter).

### Added
- `system/nvidia.sh`: `ensure_nvidia_repo_enabled` detecta e reativa (com backup)
  a linha `deb` do repo CUDA caso tenha sido comentada — evita o driver "sumir"
  dos candidatos do apt e a instalação falhar silenciosamente.
- `system/nvidia.sh`: `check_xorg_conflict` detecta `/etc/X11/xorg.conf` legado
  (gerado por `nvidia-xconfig`: `ChipId 0x0`, `Driver "nv"`) que trava o X em
  "Cannot run in framebuffer mode" (tela preta) e o neutraliza com backup.
- `system/nvidia.sh`: `setup_nvidia_xorg` gera drop-in `10-nvidia.conf` correto
  para workstation/desktop com saída de vídeo na própria dGPU (BusID real
  convertido hex→decimal + `AllowEmptyInitialConfiguration`) e habilita
  `nvidia-drm modeset=1`. Dispensa o uso manual de `nvidia-xconfig`.

---

## [2.6.0] - 2026-10-08

### Added
- Módulo `desktop/fonts.sh`: instala Nerd Fonts (não existem nos repos) a partir
  dos releases do GitHub, system-wide em `/usr/share/fonts/nerd-fonts/`
- Chave de perfil `fonts.nerd_fonts` (lista de releases a instalar); default
  embutido: Hack + NerdFontsSymbolsOnly
- Hack Nerd Font como fonte mono principal; Symbols Nerd Font como fallback de
  `monospace` via fontconfig (`.conf` instalado em `/etc/fonts/conf.d/`)
- Etapa `desktop fonts` no fluxo `all install` (roda antes de `desktop theme`)

### Changed
- `monospace_font` dos perfis full (debian/arch/alpine): JetBrains Mono → Hack
  Nerd Font Mono (ícones em TUIs/prompts: monitor IronLAN, fastfetch, starship)
- dotfiles `xfce4-terminal/terminalrc`: FontName → Hack Nerd Font Mono 10

---

## [2.5.0] - 2026-08-24

### Added
- Arc-Lighter theme shipped as pre-built asset (assets/themes/arc-lighter.tar.gz)
- XFCE dotfiles (xsettings, xfwm4, xfce4-desktop, thunar XMLs) for first-boot visual
- Polkit rule for udisks2: plugdev group mounts disks without password
- kernel_modules in profile: evdev, hid-generic, usbhid, i8042, atkbd, psmouse
- tweaks system: lightdm-no-check-graphical, udisks2-plugdev-mount
- gvfs, gvfs-fuse, udisks2, fuse3 in Alpine profile (disk management)

### Changed
- Alpine theme.sh extracts Arc-Lighter from asset (testing package is empty)
- dotfiles/deploy.sh now maps xfce4/ configs to ~/.config/xfce4/
- system/services.sh handles kernel_modules and tweaks sections from profile
- Alpine full profile is now a complete desktop-ready configuration

### Fixed
- Alpine: no /dev/input without evdev module loaded
- Alpine: LightDM CanGraphical=no (elogind seat tagging)
- Alpine: disk mount permission denied in Thunar (missing polkit rule)
- Alpine: arc-theme testing package is empty (use pre-built asset)

## [2.4.0] - 2026-08-24

### Added
- Barra de progresso visual durante instalacao ([####--] X/Y %)
- Saida em tempo real dos modulos (tee em vez de buffer)
- Perfis organizados por distro: `config/profiles/<familia>/<perfil>.yml`
- Cada distro tem full/minimal/lab com pacotes proprios
- Resolucao automatica de perfil por familia detectada
- Instalador interativo lista perfis da distro com descricoes

### Changed
- `load_profile` resolve `profiles/<distro_family>/<name>.yml` antes de generico
- `install.sh` lista apenas perfis da distro detectada

### Fixed
- Alpine: perfil full agora instala stack desktop completa (Xorg, XFCE, LightDM, Pipewire, NetworkManager, drivers)
- Alpine: testing repo habilitado automaticamente (arc-theme)
- Alpine: gtk-murrine-engine e gnome-themes-extra removidos (nao existem)
- Stremio/Heroic pulam graciosamente em non-debian

## [2.3.0] - 2026-08-24

### Added
- Instalador interativo (`install.sh`) com deteccao de distro e selecao de perfil
- Flags `--auto` e `--dry-run` no instalador
- Instrucoes pos-instalacao por familia de distro

## [2.2.0] - 2026-08-24

### Added
- Suporte a Arch Linux: perfil arch-live, mapeamento de pacotes
- `CONTRIBUTING.md`: guia para adicionar distros, perfis e modulos
- Modulos ja tinham cases Arch (theme, browser, editor, fastfetch)

## [2.1.0] - 2026-08-24

### Added
- Suporte a Alpine Linux (apk add/del/update)
- Alpine detectado como familia propria em `lib/distro.sh`
- Perfil alpine-live com pacotes nativos Alpine
- `enable_nonfree_repos` refatorado: dispatch por familia (community no Alpine)
- `is_installed` usa `apk info -e` no Alpine

### Changed
- `modules/desktop/theme.sh`: usa `pkg_install` com deps por familia
- `modules/apps/fastfetch.sh`: case Alpine
- `modules/apps/editor.sh`: skip graceful no Alpine
- `modules/apps/browser.sh`: firefox (sem -esr) no Alpine, chromium como fallback
- `modules/all/install.sh`: sanitize generico

### Fixed
- Removidas chamadas hardcoded a `apt-get` nos modulos

## [2.0.0] - 2026-07-17

### Added
- Reescrita completa: arquitetura modular
- CLI via `qxdc.sh` com modulos independentes
- Perfis declarativos (YAML-like): minimal, full, lab
- Sistema de flags: --dry-run, --yes, --verbose, --profile
- Deteccao de distro e pkg manager (Debian, Arch, Red Hat)
- Modulos: packages, desktop (theme/settings/wallpaper), apps (browser/editor/fastfetch/stremio/heroic), system (nvidia/hardware), dotfiles
- Log estruturado com cores e timestamps
- Diagnostico de erros com ultimas linhas de stderr

### Changed
- Substituiu script monolitico v0.x por arquitetura modular
- Absorveu funcionalidades do ironqui (Ansible) e lftk

---

[2.5.0]: https://github.com/luizfpq/QXDC/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/luizfpq/QXDC/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/luizfpq/QXDC/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/luizfpq/QXDC/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/luizfpq/QXDC/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/luizfpq/QXDC/releases/tag/v2.0.0
