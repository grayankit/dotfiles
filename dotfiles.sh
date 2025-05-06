#!/bin/bash

# Set variables
DOTFILES="$HOME/dotfiles"
CONFIG="$DOTFILES/config/.config"
APPS=("nvim" "hypr" "waybar")  # Add or remove app directories as needed

mkdir -p "$CONFIG"

for app in "${APPS[@]}"; do
  # Skip if it doesn't exist
  if [ -d "$HOME/.config/$app" ]; then
    echo "Moving ~/.config/$app → $CONFIG/$app"
    mv "$HOME/.config/$app" "$CONFIG/"
    ln -s "$CONFIG/$app" "$HOME/.config/$app"
  else
    echo "[!] Skipping: ~/.config/$app does not exist."
  fi
done

# Use GNU Stow to ensure everything is symlinked cleanly
cd "$DOTFILES" && stow config

echo "[✓] Done. Config files are now tracked and symlinked."

