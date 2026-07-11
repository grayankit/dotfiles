#!/usr/bin/env sh
# toggle-refresh.sh
# Toggle the refresh rate of eDP-1 between 144 and 60 Hz.

notify() {
  title="$1"
  body="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "$title" "$body"
  else
    printf '%s: %s\n' "$title" "$body"
  fi
}

MON="eDP-1"

# Extract the monitor block for eDP-1
monitor_block=$(hyprctl monitors | awk -v m="$MON" '
  $0 ~ "Monitor " m { found=1; print; next }
  found {
    if ($0 ~ /^$/) exit
    print
  }')

if [ -z "$monitor_block" ]; then
  notify "Toggle refresh" "Monitor block for '$MON' not found."
  exit 1
fi

# Parse current position and scale so we only change the mode
position=$(printf '%s\n' "$monitor_block" | grep -oE 'at [0-9]+x[0-9]+' | head -n1 | sed 's/at //')
scale=$(printf '%s\n' "$monitor_block" | grep -oE 'scale: [0-9.]+' | head -n1 | awk '{print $2}')

# Find the current resolution@rate (first mode-like line)
current_mode=$(printf '%s\n' "$monitor_block" | grep -oE '[0-9]{2,5}x[0-9]{2,5}@[0-9]+(\.[0-9]+)?' | head -n1)

if [ -z "$current_mode" ]; then
  notify "Toggle refresh" "Could not parse current mode for monitor $MON."
  exit 1
fi

res=$(printf '%s\n' "$current_mode" | cut -d@ -f1)
rate_full=$(printf '%s\n' "$current_mode" | cut -d@ -f2)
rate_int=$(printf '%s\n' "$rate_full" | cut -d. -f1)

# Toggle target rate
if [ "$rate_int" = "144" ]; then
  new_rate=60
else
  new_rate=144
fi

new_mode="${res}@${new_rate}"

# Apply new mode using hyprctl eval (Hyprland 0.55+ Lua API)
result=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${new_mode}\",position=\"${position}\",scale=${scale}})" 2>&1)
if [ "$result" = "ok" ]; then
notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${rate_int} Hz</span> → <span color='lightgreen'>${new_rate} Hz</span>"
  printf 'Changed %s from %s Hz to %s Hz\n' "$MON" "$rate_int" "$new_rate"
  exit 0
else
  # Fallback: try with exact float rate string from availableModes
  exact_mode=$(printf '%s\n' "$monitor_block" | grep -oE "${res}@[0-9]+(\.[0-9]+)?" | grep "@${new_rate}" | head -n1)

  if [ -n "$exact_mode" ]; then
    result2=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${exact_mode}\",position=\"${position}\",scale=${scale}})" 2>&1)
    if [ "$result2" = "ok" ]; then
notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${rate_int} Hz</span> → <span color='lightgreen'>${new_rate} Hz</span>"
      printf 'Changed %s from %s Hz to %s Hz\n' "$MON" "$rate_int" "${exact_mode#*@}"
      exit 0
    fi
  fi

  notify "Refresh rate failed" "Failed to set $MON to ${new_mode}. You may need to use an exact availableModes value."
  printf 'Failed to set %s to %s\n' "$MON" "$new_mode"
  exit 1
fi
