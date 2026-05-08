#!/usr/bin/env bash
# brightness-notify.sh – adjust brightness and show a nice notification
# Usage: brightness-notify.sh up|down

STEP="1%"                     # change step; edit if you want larger increments
NOTIFY_ID=9999  # static ID so new notifications replace the previous one
DIR=$1                        # expected values: up or down

# ---- 1. Validate argument -------------------------------------------------
if [[ "$DIR" != "up" && "$DIR" != "down" ]]; then
    echo "Usage: $0 up|down" >&2
    exit 1
fi

# ---- 2. Change brightness -------------------------------------------------
if [[ "$DIR" == "up" ]]; then
    brightnessctl set +${STEP}
else
    brightnessctl set ${STEP}-
fi

# ---- 3. Compute current percentage ----------------------------------------
cur=$(brightnessctl get)
max=$(brightnessctl max)
perc=$(( cur * 100 / max ))

# ---- 4. Send a progress‑style notification -----------------------------------------
# Use dunstify when dunst is running – it displays a small bar based on the value hint.
# Otherwise fall back to a plain notify‑send (no icon, simple text).
if pgrep dunst >/dev/null; then
    dunstify -r "$NOTIFY_ID" -h int:value:"$perc" -h string:hlcolor:#BA3444 "Brightness ${perc}%" -t 1500
else
    notify-send -r "$NOTIFY_ID" "Brightness ${perc}%" -t 1500
fi
exit 0
