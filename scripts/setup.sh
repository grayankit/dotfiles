#!/bin/bash
set -e

echo "[*] Cleaning up ~/.config for stow..."

CONFIG_APPS=(hypr nvim waybar alacritty tmux wlogout ml4w rofi scripts niri)

for app in "${CONFIG_APPS[@]}"; do
  if [ -L "$HOME/.config/$app" ]; then
    echo "  - Removing symlink: $app"
    rm "$HOME/.config/$app"
  elif [ -d "$HOME/.config/$app" ]; then
    echo "  - Moving folder: $app"
    mv "$HOME/.config/$app" "$HOME/dotfiles/config/.config/"
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

echo "[✓] Setup complete."
