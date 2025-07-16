#!/bin/bash

# Check if Spotify is running
if ! pgrep -x "spotify" > /dev/null; then
    echo '{"text": "No Spotify", "class": "no-spotify"}'
    exit 1
fi

# Get current track info
artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
title=$(playerctl --player=spotify metadata title 2>/dev/null)
status=$(playerctl --player=spotify status 2>/dev/null)

if [ -z "$artist" ] || [ -z "$title" ]; then
    echo '{"text": "No track", "class": "no-track"}'
    exit 1
fi

# Truncate long strings
max_length=30
if [ ${#title} -gt $max_length ]; then
    title="${title:0:$max_length}..."
fi
if [ ${#artist} -gt $max_length ]; then
    artist="${artist:0:$max_length}..."
fi

# Set icon based on status
if [ "$status" = "Playing" ]; then
    icon=""
    class="playing"
else
    icon=""
    class="paused"
fi

echo "{\"text\": \"$artist - $title\", \"class\": \"$class\", \"alt\": \"$status\"}"
