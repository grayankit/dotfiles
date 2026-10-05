#!/bin/bash
set -e

echo "[*] Cleaning up ~/.config for stow..."

CONFIG_APPS=(hypr nvim alacritty tmux ml4w rofi scripts yazi beets nmtui matugen systemd)

for app in "${CONFIG_APPS[@]}"; do
  if [ -L "$HOME/.config/$app" ]; then
    echo "  - Removing symlink: $app"
    rm "$HOME/.config/$app"
  elif [ -d "$HOME/.config/$app" ]; then
    if [ -e "$HOME/dotfiles/config/.config/$app" ]; then
      # Never `mv` a dir onto an existing repo dir: mv would nest it as
      # <dest>/<app>/ instead of replacing, silently corrupting the repo.
      echo "  - Skipping $app (already present in dotfiles)"
    else
      echo "  - Moving folder: $app"
      mv "$HOME/.config/$app" "$HOME/dotfiles/config/.config/"
    fi
  fi
done

echo "[*] Symlinking with stow..."
cd "$HOME/dotfiles"
stow config

echo "[*] Linking Zsh config..."

if [ -L "$HOME/.zshrc" ]; then
  echo "  - Removing symlink: .zshrc"
  rm "$HOME/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
  echo "  - Moving existing .zshrc to dotfiles"
  mkdir -p "$HOME/dotfiles/zsh"
  mv "$HOME/.zshrc" "$HOME/dotfiles/zsh/.zshrc"
fi

stow zsh

echo "[*] Cleaning up flag files before stowing..."

FLAGS=(spotify-flags.conf code-flags.conf)
for flag in "${FLAGS[@]}"; do
  SRC="$HOME/.config/$flag"
  DEST="$HOME/dotfiles/flags/$flag"

  if [ -L "$SRC" ]; then
    echo "  - Removing symlink: $flag"
    rm "$SRC"
  elif [ -f "$SRC" ]; then
    echo "  - Moving existing file: $flag"
    mkdir -p "$(dirname "$DEST")"
    mv "$SRC" "$DEST"
  fi
done

echo "[*] Stowing flags..."
stow flags

echo "[*] Linking WezTerm config..."

if [ -L "$HOME/.wezterm.lua" ]; then
  echo "  - Removing symlink: .wezterm.lua"
  rm "$HOME/.wezterm.lua"
elif [ -f "$HOME/.wezterm.lua" ]; then
  echo "  - Moving existing .wezterm.lua to dotfiles"
  mkdir -p "$HOME/dotfiles/wezterm"
  mv "$HOME/.wezterm.lua" "$HOME/dotfiles/wezterm/.wezterm.lua"
fi

stow wezterm

echo "[*] Linking Zen profile chrome..."

ZEN_CHROME="$HOME/.zen/wsnnxa2d.Default (release)/chrome"
ZEN_PKG="$HOME/dotfiles/zen/.zen/wsnnxa2d.Default (release)/chrome"

for f in userChrome.css userContent.css custom.css; do
  SRC="$ZEN_CHROME/$f"
  if [ -L "$SRC" ]; then
    echo "  - Removing symlink: $f"
    rm "$SRC"
  elif [ -f "$SRC" ]; then
    echo "  - Moving existing $f to dotfiles"
    mkdir -p "$ZEN_PKG"
    mv "$SRC" "$ZEN_PKG/$f"
  fi
done

stow zen

echo "[*] Linking Ghostty config..."

if [ -L "$HOME/.config/ghostty/config" ]; then
  echo "  - Removing symlink: ghostty/config"
  rm "$HOME/.config/ghostty/config"
elif [ -f "$HOME/.config/ghostty/config" ]; then
  echo "  - Moving existing ghostty/config to dotfiles"
  mkdir -p "$HOME/dotfiles/ghostty"
  mv "$HOME/.config/ghostty/config" "$HOME/dotfiles/ghostty/config"
elif [ -d "$HOME/.config/ghostty" ]; then
  echo "  - Moving existing ghostty directory to dotfiles"
  rm -rf "$HOME/dotfiles/ghostty"
  mv "$HOME/.config/ghostty" "$HOME/dotfiles/ghostty"
fi

stow -t "$HOME/.config" ghostty

echo "[*] Linking local bin helpers..."

mkdir -p "$HOME/.local/bin"
for bin in neo-browser neocolab-box neocolab-chrome; do
  SRC="$HOME/.local/bin/$bin"
  if [ -L "$SRC" ]; then
    echo "  - Removing symlink: $bin"
    rm "$SRC"
  elif [ -f "$SRC" ]; then
    echo "  - Replacing existing file: $bin"
    rm "$SRC"
  fi
done

stow local

echo "[✓] Setup complete."
