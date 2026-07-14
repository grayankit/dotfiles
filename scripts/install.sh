#!/bin/bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
PACMAN_LIST="$DOTFILES/pkglist-pacman.txt"
AUR_LIST="$DOTFILES/pkglist-aur.txt"

echo "[*] Installing essential packages..."
sudo pacman -S --needed base-devel git stow zsh neovim tmux waybar

if [[ -f "$PACMAN_LIST" ]]; then
  echo "[*] Restoring official packages from pkglist-pacman.txt..."
  sudo pacman -S --needed - < "$PACMAN_LIST"
else
  echo "[!] Missing $PACMAN_LIST — skipping official package restore"
fi

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    echo "  - yay already installed"
    return
  fi
  echo "[*] Installing yay (AUR helper)..."
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

if [[ -f "$AUR_LIST" ]]; then
  install_yay
  echo "[*] Restoring AUR packages from pkglist-aur.txt..."
  # Skip yay itself (bootstrapped above)
  mapfile -t aur_pkgs < <(grep -vE '^(yay|#|$)' "$AUR_LIST" || true)
  if ((${#aur_pkgs[@]})); then
    yay -S --needed --noconfirm -- "${aur_pkgs[@]}"
  else
    echo "  - no AUR packages to install"
  fi
else
  echo "[!] Missing $AUR_LIST — skipping AUR package restore"
fi

echo "[*] Ensuring tmux plugin manager (if not using git submodules)..."
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
  echo "  - TPM already present"
fi

RESURRECT_DIR="$HOME/.config/tmux/plugins/tmux-resurrect"
if [[ ! -d "$RESURRECT_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tmux-resurrect "$RESURRECT_DIR"
else
  echo "  - tmux-resurrect already present"
fi

echo "[✓] Installation complete. Now run: $DOTFILES/scripts/setup.sh"
