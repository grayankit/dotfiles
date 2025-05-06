#!/bin/bash
set -e

echo "[*] Installing essential packages..."
sudo pacman -S --needed zsh neovim tmux waybar git stow

if [ -f "$HOME/dotfiles/pkglist.txt" ]; then
  echo "[*] Restoring additional packages from pkglist.txt..."
  sudo pacman -S --needed - < "$HOME/dotfiles/pkglist.txt"
fi
echo "[*] Installing tmux plugins..."

TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "  - TPM already installed."
fi

echo "[✓] Installation complete. Now run ./scripts/setup.sh"
