# QXDC — Quirino's XFCE Default Config

> Opinionated, automated XFCE desktop configuration for Debian.
> Because reinstalling your OS shouldn't mean spending two hours clicking through settings.

**Versao em portugues brasileiro disponivel em [README-pt-br.md](README-pt-br.md)**

---

![Desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png)

## Why

We already have plenty of mods and styles for our desktops. But I usually need to reinstall and reinvent my usability choices from scratch, and I don't want to use any of the available "Refisefuquis"<sup>1</sup> out there. QXDC is my answer: a reproducible, non-interactive desktop configurator that does exactly what I want and nothing else.

## What it does

QXDC turns a fresh Debian + XFCE install into a productive desktop in minutes. No GUI wizards, no dumb questions, no Swiss landscape wallpapers nobody asked for.

It installs packages, configures themes, adjusts panels, deploys dotfiles, and removes bloat — all via CLI, all reproducible, all versioned.

## Screenshots

| Desktop | Apps |
|---------|------|
| ![desktop](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-desktop.png) | ![apps](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-apps.png) |

| Chrome | LightDM |
|--------|---------|
| ![chrome](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-chrome.png) | ![lightdm](https://raw.githubusercontent.com/luizfpq/QXDC-docs/main/screenshot-lightdm.png) |

## Quick start

### Prerequisites

- A Debian-based system (Debian 12+, Ubuntu 22.04+) with XFCE installed
- `git` installed (if not: `sudo apt install git`)
- A user with `sudo` privileges
- Internet connection (packages will be downloaded)

### Step 1 — Download

Open a terminal and clone this repository:

```bash
git clone https://github.com/luizfpq/QXDC.git
cd QXDC
chmod +x qxdc.sh
```

### Step 2 — Preview (optional but recommended)

Before changing anything, you can preview what QXDC would do. This is safe — nothing gets installed or modified:

```bash
./qxdc.sh packages install --profile full --dry-run
```

You'll see a list of packages that would be installed. If it looks good, proceed.

### Step 3 — Run it

Execute the modules in order. Each one handles a different part of the setup:

```bash
# Install essential packages (editors, tools, fonts, utilities)
./qxdc.sh packages install --profile full --yes

# Remove unwanted packages that come with Debian by default
./qxdc.sh packages purge --profile full --yes

# Apply the visual theme (Arc-Lighter + Papirus icons)
./qxdc.sh desktop theme --profile full --yes

# Configure desktop behavior (workspaces, Thunar, panels)
./qxdc.sh desktop settings --yes

# Set the wallpaper (desktop + login screen)
./qxdc.sh desktop wallpaper --yes

# Install Visual Studio Code
./qxdc.sh apps editor --yes

# Install browser + theme integration
./qxdc.sh apps browser --profile full --yes

# Install fastfetch with custom ASCII logo
./qxdc.sh apps fastfetch --yes
```

### Step 4 — Enjoy

Log out and back in (or reboot) to see all changes applied. That's it.

### Choosing a profile

Not sure which profile to use? Here's the short version:

- **`full`** — You want a complete, ready-to-work desktop. Pick this if in doubt.
- **`minimal`** — You want just the essential packages, no visual changes.
- **`lab`** — You're setting up a test VM and need debug tools, not a pretty desktop.

## Look and feel

| Item | Value |
|------|-------|
| GTK/WM Theme | Arc-Lighter |
| Icons | Papirus-Dark + papirus-folders (paleorange) |
| Terminal | Nighty-Lighter (bg #e7e8eb, fg #2e3440) |
| Font | Noto Sans 10 |
| Panel 2 | Dock with ~12% opacity |
| Wallpaper | [QXDC-docs/main-wallpaper.jpg](https://github.com/luizfpq/QXDC-docs) |
| LightDM | Same wallpaper + Arc-Lighter |

## Structure

```
QXDC/
├── qxdc.sh              # Entrypoint (CLI)
├── lib/                 # Shared libraries
│   ├── common.sh        # Logging, colors, flags, dry-run
│   ├── distro.sh        # Distro detection & pkg manager
│   └── config.sh        # YAML-like config parser
├── modules/             # Independent modules
│   ├── packages/        # install.sh, purge.sh
│   ├── desktop/         # theme.sh, settings.sh, wallpaper.sh
│   ├── apps/            # browser.sh, editor.sh
│   ├── dotfiles/        # files/ (ready-made configs)
│   └── system/          # (future: sources, firmware)
├── config/
│   ├── defaults.yml     # Default configuration
│   └── profiles/        # minimal, full, lab
└── tests/
    └── shellcheck.sh    # Lint
```

## Profiles

| Profile | Purpose |
|---------|---------|
| `minimal` | Bare minimum to not suffer |
| `full` | Full productive desktop, everything configured |
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

## Related repositories

| Repo | Status | Role |
|------|--------|------|
| [QXDC-docs](https://github.com/luizfpq/QXDC-docs) | Active | Static assets (wallpapers, screenshots) |
| [lftk](https://github.com/luizfpq/lftk) | Active | Complementary toolkit (server/infra) |
| [ironqui](https://github.com/luizfpq/ironqui) | Archived | Previous Ansible attempt (absorbed into QXDC 2.0) |

## License

MIT

---

<sup>1</sup> **Refisefuquis** — "Release de Fim de Semana e Fundo de Quintal". Literal translation: "Weekend and Backyard Release". In simple words: releases with no support, no innovation, and no purpose — just a homemade adventure from a developer with time and a computer available. QXDC is proudly one of those, except it actually works.
