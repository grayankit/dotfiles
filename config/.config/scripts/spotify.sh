#!/bin/bash

# Check if Spotify is running
if ! pgrep -x "spotify" > /dev/null; then
    echo '{"text": "", "class": "no-spotify", "tooltip": "Spotify not running"}'
    exit 1
fi

# Get current track info
artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
title=$(playerctl --player=spotify metadata title 2>/dev/null)
album=$(playerctl --player=spotify metadata album 2>/dev/null)
status=$(playerctl --player=spotify status 2>/dev/null)

if [ -z "$artist" ] || [ -z "$title" ]; then
    echo '{"text": "No track", "class": "no-track", "tooltip": "No track playing"}'
    exit 1
fi

# Truncate long strings
max_length=25
if [ ${#title} -gt $max_length ]; then
    title="${title:0:$max_length}..."
fi
if [ ${#artist} -gt $max_length ]; then
    artist="${artist:0:$max_length}..."
fi

# Set class based on status
case "$status" in
    "Playing")
        class="playing"
        ;;
    "Paused")
        class="paused"
        ;;
    *)
        class="stopped"
        ;;
esac

# Create tooltip with full info
tooltip="$artist - $title"
if [ -n "$album" ]; then
    tooltip="$tooltip\nAlbum: $album"
fi
tooltip="$tooltip\nStatus: $status"

echo "{\"text\": \"$artist - $title\", \"class\": \"$class\", \"tooltip\": \"$tooltip\"}"
