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

# Reload UI components to apply the new colors
# Reload Waybar
if pgrep -x waybar > /dev/null; then
    killall -SIGUSR2 waybar
fi

# Reload Dunst and ensure Mako doesn't hijack D-Bus
killall mako 2>/dev/null
killall dunst 2>/dev/null
dunst > /dev/null 2>&1 &

# Reload Hyprland to apply the new border colors
hyprctl reload
