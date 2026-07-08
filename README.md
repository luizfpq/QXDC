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

Open a terminal. You have two options:

**Option A — With git (recommended):**

```bash
sudo apt install git    # skip if git is already installed
git clone https://github.com/luizfpq/QXDC.git
cd QXDC
chmod +x qxdc.sh
```

**Option B — Without git (download ZIP):**

If you don't have git and don't want to install it yet, download the ZIP directly:

```bash
wget https://github.com/luizfpq/QXDC/archive/refs/heads/v2.0.zip -O qxdc.zip
unzip qxdc.zip
cd QXDC-v2.0
chmod +x qxdc.sh
```

> If `wget` is also missing: open Firefox, go to https://github.com/luizfpq/QXDC, click the green "Code" button, then "Download ZIP". Extract it and open a terminal inside the folder.

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

| Item | Value | Source |
|------|-------|--------|
| GTK/WM Theme | Arc-Lighter | [jnsh/arc-theme](https://github.com/jnsh/arc-theme) |
| Icons | Papirus-Dark | [PapirusDevelopmentTeam/papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) |
| Folder Colors | paleorange | [PapirusDevelopmentTeam/papirus-folders](https://github.com/PapirusDevelopmentTeam/papirus-folders) |
| Terminal Colors | Nighty-Lighter | Based on [Gogh-Co/Gogh — Nighty](https://github.com/Gogh-Co/Gogh/blob/master/themes/Nighty.yml) |
| System Fetch | fastfetch | [fastfetch-cli/fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| Font | Noto Sans 10 | [Google Noto Fonts](https://fonts.google.com/noto) |
| Panel 2 | Dock with ~12% opacity | — |
| Wallpaper | [QXDC-docs/main-wallpaper.jpg](https://github.com/luizfpq/QXDC-docs) | — |
| LightDM | Same wallpaper + Arc-Lighter | — |

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
│   ├── apps/            # browser.sh, editor.sh, fastfetch.sh
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

## Error diagnostics

When a module fails, QXDC shows:

- The module's exit code
- The last 5 lines of stderr inline
- A final summary listing all failed modules with their errors

Example output on failure:

```
[WARN] [3/9] desktop theme failed (exit code: 1).

[ERRO] --- Error in 'desktop theme' (last 5 lines) ---
  [ERRO] DBUS_SESSION_BUS_ADDRESS not defined.
  [ERRO] Run without sudo or with 'sudo -E' to preserve DISPLAY/D-Bus.
[ERRO] --- end ---

:: Error details
[ERRO] [FAIL] desktop theme
  [ERRO] DBUS_SESSION_BUS_ADDRESS not defined.
  [ERRO] Run without sudo or with 'sudo -E' to preserve DISPLAY/D-Bus.
```

### Common issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| "DBUS_SESSION_BUS_ADDRESS not defined" | `sudo` without `-E` or running outside XFCE session | Run without sudo (the script asks when needed) or use `sudo -E` |
| "DISPLAY not defined" | Running via SSH or TTY without X | Run inside a graphical terminal in the XFCE session |
| "xfconfd is not running" | XFCE session not active | Log in to the XFCE desktop before running |
| Desktop modules fail but packages works | Packages only needs apt/sudo; desktop needs a graphical session | Expected — run desktop modules after logging into XFCE |

### Log

Every execution writes to `/tmp/qxdc-YYYYMMDD-HHMMSS.log`. When running via `all install`, all modules share the same log file.

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
