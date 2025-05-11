# 📁 Dotfiles

This repository contains my personal configuration files for Arch Linux with Hyprland, Zsh, Tmux, Neovim, and more.

It uses [GNU Stow](https://www.gnu.org/software/stow/) to manage symlinks and includes setup scripts for quick system restoration and configuration.

---

### 🔧 Features

* 🧠 Symlink-based dotfile management via `stow`
* ⚡ Auto-installs Tmux plugins (TPM, Resurrect)
* 💠 Zsh configuration with `.zshrc` tracking
* 💻 Hyprland, Waybar, and Neovim config management
* 📦 Optional Arch package restoration via `pkglist.txt`

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
├── pkglist.txt          # Optional list of packages
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

* Installs basic packages (zsh, neovim, hyprland, etc.)
* Installs packages listed in `pkglist.txt` (if present)

---

### 3. Run Setup Script (Anytime)

```bash
./setup.sh
```

* Cleans conflicting files
* Moves unmanaged configs into the dotfiles repo
* Symlinks everything via `stow`
* Installs Tmux plugins automatically

---

## 🧹 Plugin Installers

### Tmux Plugins

Automatically installs:

* [`tmux-plugins/tpm`](https://github.com/tmux-plugins/tpm)
* [`tmux-plugins/tmux-resurrect`](https://github.com/tmux-plugins/tmux-resurrect)

Located at `~/.config/tmux/plugins/` and loaded via `.tmux.conf`.

---

## 📦 Arch Package Restore (Optional)

To dump current packages:

```bash
pacman -Qqen > pkglist.txt
```

This lets `install.sh` restore your packages on a new machine:

```bash
sudo pacman -S --needed - < pkglist.txt
```

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
A: To keep the repo clean and avoid embedded Git warnings. Plugins are installed via scripts.

**Q: What if I want to use submodules instead?**
A: You can — see `git submodule add <url>` and update the `setup.sh`.

---
