#!/bin/bash
set -e

echo "[*] Cleaning up ~/.config for stow..."

CONFIG_APPS=(hypr nvim waybar alacritty tmux wlogout)

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
echo "[✓] Setup complete."
