# Changelog

Todas as mudancas notaveis neste projeto estao documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versionamento segue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
