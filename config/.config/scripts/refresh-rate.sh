#!/usr/bin/env sh
# Toggle eDP-1 refresh rate between high (~144) and low (~60) Hz.

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
NIRI_EDP_KDL="${XDG_CONFIG_HOME:-$HOME/.config}/niri/output-edp.kdl"

is_niri() {
  [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ] || pgrep -x niri >/dev/null 2>&1
}

# Format millihertz integer -> Hz string niri accepts (e.g. 144003 -> 144.003)
mhz_to_hz() {
  mhz=$1
  whole=$((mhz / 1000))
  frac=$((mhz % 1000))
  printf '%d.%03d' "$whole" "$frac"
}

write_edp_kdl() {
  mode_str=$1
  cat >"$NIRI_EDP_KDL" <<EOF
// Written by ~/.config/scripts/refresh-rate.sh — exact Hz required by niri
output "$MON" {
    mode "$mode_str"
    scale 1
    position x=0 y=0
}
EOF
}

toggle_niri() {
  if ! command -v niri >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    notify "Toggle refresh" "niri/jq not available."
    return 1
  fi

  out=$(niri msg --json outputs 2>/dev/null)
  if [ -z "$out" ]; then
    notify "Toggle refresh" "Could not query niri outputs (is niri running?)."
    return 1
  fi

  # JSON: modes[].refresh_rate is millihertz; current_mode is index
  parsed=$(printf '%s' "$out" | jq -r --arg m "$MON" '
    .[$m] // empty |
    . as $o |
    ($o.modes[$o.current_mode] // empty) as $cur |
    if $cur == null then empty
    else
      ($o.modes
        | to_entries
        | map(select(.value.width == $cur.width and .value.height == $cur.height))
        | sort_by(.value.refresh_rate)
      ) as $same |
      {
        w: $cur.width,
        h: $cur.height,
        cur_mHz: $cur.refresh_rate,
        low_mHz: ($same[0].value.refresh_rate),
        high_mHz: ($same[-1].value.refresh_rate)
      }
      | "\(.w) \(.h) \(.cur_mHz) \(.low_mHz) \(.high_mHz)"
    end
  ' 2>/dev/null)

  if [ -z "$parsed" ]; then
    notify "Toggle refresh" "Could not parse modes for $MON."
    return 1
  fi

  set -- $parsed
  w=$1 h=$2 cur_mhz=$3 low_mhz=$4 high_mhz=$5

  if [ "$low_mhz" = "$high_mhz" ]; then
    notify "Toggle refresh" "Only one mode for ${w}x${h} on $MON."
    return 1
  fi

  # If at/near high, go low; otherwise go high
  # Midpoint avoids float compare issues
  mid=$(( (low_mhz + high_mhz) / 2 ))
  if [ "$cur_mhz" -ge "$mid" ]; then
    new_mhz=$low_mhz
  else
    new_mhz=$high_mhz
  fi

  cur_hz=$(mhz_to_hz "$cur_mhz")
  new_hz=$(mhz_to_hz "$new_mhz")
  target="${w}x${h}@${new_hz}"

  err=$(niri msg output "$MON" mode "$target" 2>&1)
  status=$?
  if [ "$status" -ne 0 ]; then
    notify "Refresh rate failed" "Set $MON to ${target}: ${err:-exit $status}"
    return 1
  fi

  # Persist so config reloads (opacity/gamemode) keep the mode
  write_edp_kdl "$target"

  cur_int=$(printf '%s' "$cur_hz" | cut -d. -f1)
  new_int=$(printf '%s' "$new_hz" | cut -d. -f1)
  notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${cur_int} Hz</span> → <span color='lightgreen'>${new_int} Hz</span>
(${target})"
  printf 'Changed %s from %s Hz to %s (%s)\n' "$MON" "$cur_hz" "$new_hz" "$target"
  return 0
}

toggle_hypr() {
  monitor_block=$(hyprctl monitors | awk -v m="$MON" '
    $0 ~ "Monitor " m { found=1; print; next }
    found {
      if ($0 ~ /^$/) exit
      print
    }')

  if [ -z "$monitor_block" ]; then
    notify "Toggle refresh" "Monitor block for '$MON' not found."
    return 1
  fi

  position=$(printf '%s\n' "$monitor_block" | grep -oE 'at [0-9]+x[0-9]+' | head -n1 | sed 's/at //')
  scale=$(printf '%s\n' "$monitor_block" | grep -oE 'scale: [0-9.]+' | head -n1 | awk '{print $2}')
  current_mode=$(printf '%s\n' "$monitor_block" | grep -oE '[0-9]{2,5}x[0-9]{2,5}@[0-9]+(\.[0-9]+)?' | head -n1)

  if [ -z "$current_mode" ]; then
    notify "Toggle refresh" "Could not parse current mode for monitor $MON."
    return 1
  fi

  res=$(printf '%s\n' "$current_mode" | cut -d@ -f1)
  rate_full=$(printf '%s\n' "$current_mode" | cut -d@ -f2)
  rate_int=$(printf '%s\n' "$rate_full" | cut -d. -f1)

  if [ "$rate_int" = "144" ]; then
    new_rate=60
  else
    new_rate=144
  fi

  new_mode="${res}@${new_rate}"

  result=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${new_mode}\",position=\"${position}\",scale=${scale}})" 2>&1)
  if [ "$result" = "ok" ]; then
    notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${rate_int} Hz</span> → <span color='lightgreen'>${new_rate} Hz</span>"
    printf 'Changed %s from %s Hz to %s Hz\n' "$MON" "$rate_int" "$new_rate"
    return 0
  fi

  exact_mode=$(printf '%s\n' "$monitor_block" | grep -oE "${res}@[0-9]+(\.[0-9]+)?" | grep "@${new_rate}" | head -n1)

  if [ -n "$exact_mode" ]; then
    result2=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${exact_mode}\",position=\"${position}\",scale=${scale}})" 2>&1)
    if [ "$result2" = "ok" ]; then
      notify "Refresh Rate Changed" "<b>${MON}</b><br>
<span color='lightblue'>${rate_int} Hz</span> → <span color='lightgreen'>${new_rate} Hz</span>"
      printf 'Changed %s from %s Hz to %s Hz\n' "$MON" "$rate_int" "${exact_mode#*@}"
      return 0
    fi
  fi

  notify "Refresh rate failed" "Failed to set $MON to ${new_mode}."
  return 1
}

if is_niri; then
  toggle_niri
else
  toggle_hypr
fi
