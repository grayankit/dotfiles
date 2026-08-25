#!/bin/env bash

current_output=$(pactl get-default-sink)

pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && notify-send -h string:wf-recorder:record -t 1000 "Finished Recording" && exit 0

list_monitors() {
    if [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ] || pgrep -x niri >/dev/null 2>&1; then
        if niri msg --json outputs >/dev/null 2>&1; then
            niri msg --json outputs | jq -r 'keys[]'
            return
        fi
        niri msg outputs 2>/dev/null | awk '/^Output / {print $2}' | tr -d ':'
        return
    fi
    hyprctl monitors -j | jq -r '.[].name'
}

monitors=$(list_monitors)
selected_monitor=$(echo "$monitors" | rofi -dmenu -p "Record Monitor" -lines 3)

if [ -z "$selected_monitor" ]; then
    exit 0
fi

notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>3</b></i></span>"

sleep 1

notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>2</b></i></span>"

sleep 1

notify-send -h string:wf-recorder:record -t 950 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>1</b></i></span>"

sleep 1

dateTime=$(date +%m-%d-%Y-%H:%M:%S)
mkdir -p "$HOME/Videos"
wf-recorder --bframes max_b_frames -f "$HOME/Videos/$dateTime.mp4" -o "$selected_monitor" --audio="${current_output}".monitor
