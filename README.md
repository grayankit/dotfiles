# 📁 Dotfiles

This repository contains my personal configuration files for Arch Linux with Hyprland, Zsh, Tmux, Neovim, and more.

It uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks and includes setup scripts for quick system restoration and configuration.

---

### 🔧 Features

* 🧠 Symlink-based dotfile management via `stow`
* ⚡ Auto-installs Tmux plugins (TPM, Resurrect)
* 💠 Zsh configuration with `.zshrc` tracking
* 💻 Hyprland, Waybar, and Neovim config management
* 📦 Official + AUR package restore via split package lists

---

## 🛠 Directory Structure

```
dotfiles/
├── config/              # ~/.config/* files (Hypr, Neovim, etc.)
│   └── .config/
│       ├── hypr/
│       ├── nvim/
│       └── waybar/
├── flags/               # flags for mostly native wayland
├── zsh/                 # Zsh config
│   └── .zshrc
├── scripts/             # Setup scripts
│   ├── install.sh       # One-time system setup
│   └── setup.sh         # Safe to run any time
├── pkglist-pacman.txt   # Explicit official (repo) packages
├── pkglist-aur.txt      # Explicit AUR packages
└── README.md
```

---

## 🚀 Getting Started

### 1. Clone This Repo

```bash
git clone --recursive https://github.com/grayankit/dotfiles.git ~/dotfiles
```

> Use `--recursive` if you later add submodules.

---

### 2. Run System Install Script (Once per Machine)

```bash
cd ~/dotfiles/scripts
./install.sh
```

* Installs base tools (zsh, neovim, tmux, waybar, stow, git)
* Restores official packages from `pkglist-pacman.txt`
* Bootstraps `yay` if needed, then restores AUR packages from `pkglist-aur.txt`

---

### 3. Run Setup Script (Anytime)

```bash
./setup.sh
```

* Cleans conflicting files
* Moves unmanaged configs into the dotfiles repo
* Symlinks everything via `stow`

---

## 🧹 Plugin Installers

### Tmux Plugins

Automatically installs:

* [`tmux-plugins/tpm`](https://github.com/tmux-plugins/tpm)
* [`tmux-plugins/tmux-resurrect`](https://github.com/tmux-plugins/tmux-resurrect)

Located at `~/.config/tmux/plugins/` and loaded via `.tmux.conf`. Prefer cloning with `--recursive` so other tmux plugin submodules are present too.

---

## 📦 Arch Package Lists

Split so official and AUR packages restore correctly:

| File | Source command | Install |
|------|----------------|---------|
| `pkglist-pacman.txt` | `pacman -Qqen` | `sudo pacman -S --needed - < pkglist-pacman.txt` |
| `pkglist-aur.txt` | `pacman -Qqem` | `yay -S --needed - < pkglist-aur.txt` |

### Refresh lists (after installing packages)

```bash
cd ~/dotfiles
pacman -Qqen | sort > pkglist-pacman.txt
pacman -Qqem | sort > pkglist-aur.txt
```

`install.sh` runs both restores and installs `yay` from the AUR if it is missing.

---

## 🧼 Reset Everything (Carefully)

If you ever need to re-stow after a wipe or config change:

```bash
cd ~/dotfiles/scripts
./setup.sh
```

---

## 🤛 FAQ

**Q: Why not track plugin repos directly in Git?**
A: Some are git submodules under `config/.config/tmux/plugins/`; others can still be installed via scripts.

**Q: What if I want to use more submodules?**
A: Use `git submodule add <url>` and clone with `--recursive`.

---
[![wakatime](https://wakatime.com/badge/github/grayankit/dotfiles.svg)](https://wakatime.com/badge/github/grayankit/dotfiles)
