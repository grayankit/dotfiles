#!/usr/bin/env sh
# toggle-refresh.sh
# Toggle the refresh rate of a Hyprland monitor between 144 and 60 Hz.
# Default: the focused monitor. Override via MON="eDP-1" ./toggle-refresh.sh

notify() {
  title="$1"
  body="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "$title" "$body"
  else
    printf '%s: %s\n' "$title" "$body"
  fi
}

MON="${MON:-}"

# Determine monitor: prefer MON, otherwise the focused one, otherwise first monitor.
if [ -z "$MON" ]; then
  MON=$(hyprctl monitors | awk '
    /^Monitor / { name=$2 }
    /focused: yes/ { print name; exit }
  ')
  if [ -z "$MON" ]; then
    MON=$(hyprctl monitors | awk '/^Monitor / { print $2; exit }')
  fi
fi

if [ -z "$MON" ]; then
  notify "Toggle refresh" "Could not determine monitor name (hyprctl monitors failed)."
  exit 1
fi

# Extract the monitor block for MON
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
result=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${new_mode}\",position=\"0x0\",scale=1})" 2>&1)
if [ "$result" = "ok" ]; then
notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${rate_int} Hz</span> → <span color='lightgreen'>${new_rate} Hz</span>"
  printf 'Changed %s from %s Hz to %s Hz\n' "$MON" "$rate_int" "$new_rate"
  exit 0
else
  # Fallback: try with exact float rate string from availableModes
  exact_mode=$(printf '%s\n' "$monitor_block" | grep -oE "${res}@[0-9]+(\.[0-9]+)?" | grep "@${new_rate}" | head -n1)

  if [ -n "$exact_mode" ]; then
    result2=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${exact_mode}\",position=\"0x0\",scale=1})" 2>&1)
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
