#!/bin/bash

WALLPAPER_DIR="$HOME/.config/ml4w/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Ensure awww-daemon is running, start it if not
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 1 # wait for daemon to initialize
fi

# Generate the list of files and attach the icon path to each
ENTRIES=""
for file in "$WALLPAPER_DIR"/*; do
    # Skip any stray symlinks like current_wallpaper if it exists
    if [ "$(basename "$file")" = "current_wallpaper" ]; then
        continue
    fi

    if [[ "$file" =~ \.(jpg|jpeg|png|gif)$ ]]; then
        filename=$(basename "$file")
        ENTRIES="${ENTRIES}${filename}\0icon\x1f${file}\n"
    fi
done

# Check if any entries were found
if [ -z "$ENTRIES" ]; then
    echo "No wallpapers found."
    exit 1
fi

# Pass the generated list to Rofi with your dedicated wallpaper theme
SELECTED=$(echo -e -n "$ENTRIES" | rofi -dmenu -i -show-icons -p "Wallpaper" \
    -theme "$HOME/.config/rofi/wallpaper-picker.rasi")

# Exit if no wallpaper was selected
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Absolute path of the selected real wallpaper file
REAL_WALLPAPER_PATH="$WALLPAPER_DIR/$SELECTED"

# Use awww to set the image with the 'wipe' transition
awww img "$REAL_WALLPAPER_PATH" --transition-type wipe

# Extract colors from the new wallpaper using Wallust (skipping terminal sequences)
wallust run -s -q "$REAL_WALLPAPER_PATH"

# Sync keyboard backlight to waybar text color (foreground)
"$HOME/.config/scripts/sync-keyboard-rgb.sh" &

# Reload UI components to apply the new colors
# Reload Waybar
if pgrep -x waybar > /dev/null; then
    killall -SIGUSR2 waybar
fi

pkill -USR2 cava 2>/dev/null || true

# Reload WezTerm colors (wallust scheme)
touch "$HOME/.wezterm.lua" 2>/dev/null || true

# Apply KDE/Qt colors (Dolphin). Outside full Plasma, live palette reload is
# unreliable — apply-kde-colors.sh alternates schemes, emits D-Bus notifies,
# and soft-restarts Dolphin while restoring open folders.
if [ -x "$HOME/.config/scripts/apply-kde-colors.sh" ]; then
    "$HOME/.config/scripts/apply-kde-colors.sh" || true
    # kde-gtk-config may overwrite GTK CSS — regenerate so adw-gtk3 wins
    wallust run -s -q "$REAL_WALLPAPER_PATH"
fi

# Nudge GTK apps to pick up new colors.css (GTK4 often needs app restart)
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
fi

# Reload Dunst and ensure Mako doesn't hijack D-Bus
killall mako 2>/dev/null
killall dunst 2>/dev/null
dunst > /dev/null 2>&1 &

# Reload Spotifast palette without interrupting playback
if command -v spotifast >/dev/null 2>&1; then
    spotifast reload-themes >/dev/null 2>&1 || true
fi

# Reload Hyprland to apply the new border colors
command -v hyprctl >/dev/null 2>&1 && hyprctl reload
