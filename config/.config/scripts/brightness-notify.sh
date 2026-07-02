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

# ---- 4. Sync external monitor brightness ----------------------------------
# Write the target percentage to a file.
echo "$perc" > /tmp/target_brightness
(
    # Try to acquire the lock. If busy, another instance is already processing
    # updates in the background, so we can just exit this subshell.
    if flock -n 9; then
        while true; do
            target=$(cat /tmp/target_brightness)
            current=$(cat /tmp/current_brightness 2>/dev/null || echo "-1")

            if [ "$current" != "$target" ]; then
                # Apply the brightness via ddcutil (this takes ~1-2s)
                ddcutil --display=1 setvcp 10 "$target" 2>/dev/null
                echo "$target" > /tmp/current_brightness
            else
                # We are up to date!
                break
            fi
        done
    fi
) 9>/tmp/ddcutil_sync.lock &

# ---- 5. Send a progress‑style notification -----------------------------------------
# Use dunstify when dunst is running – it displays a small bar based on the value hint.
# Otherwise fall back to a plain notify‑send (no icon, simple text).
if pgrep dunst >/dev/null; then
    dunstify -r "$NOTIFY_ID" -h int:value:"$perc" -h string:hlcolor:#BA3444 "Brightness ${perc}%" -t 1500
else
    notify-send -r "$NOTIFY_ID" "Brightness ${perc}%" -t 1500
fi
exit 0
