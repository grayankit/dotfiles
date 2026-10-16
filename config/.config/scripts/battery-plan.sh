#!/usr/bin/env sh
# battery-plan.sh — power plans, including a max-battery option.
#
#   battery-plan.sh                 picker
#   battery-plan.sh max             longest runtime
#   battery-plan.sh balanced
#   battery-plan.sh performance
#   battery-plan.sh status
#
# Max battery:
#   - panel to 60 Hz
#   - backlight to 30% (only if it is currently brighter)
#   - Hyprland animations off, window opacity forced to 1
#   - TLP power-saver, plus the CPU cap in local/tlp/99-max-battery.conf
#     once that file is installed under /etc/tlp.d/
#
# Balanced / Performance restore the screen and lift the CPU cap
# (the cap only lifts after the TLP drop-in is installed).
# Plugging in AC switches TLP back to performance on its own, but does
# not restore 144 Hz or brightness — use this picker for that.

MON="eDP-1"
BRIGHTNESS_PCT=30
MAX_HZ=60
DROPIN_NAME="99-max-battery.conf"
DROPIN_DEST="/etc/tlp.d/${DROPIN_NAME}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/battery-plan"
STATE_FILE="${STATE_DIR}/saved"

notify() {
  title="$1"
  body="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u normal "$title" "$body"
  else
    printf '%s: %s\n' "$title" "$body"
  fi
}

script_dir() {
  cd -- "$(dirname -- "$0")" && pwd -P
}

dropin_src() {
  dir=$(script_dir)
  candidate="${dir}/../../../local/tlp/${DROPIN_NAME}"
  if [ -f "$candidate" ]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  if [ -f "$HOME/dotfiles/local/tlp/${DROPIN_NAME}" ]; then
    printf '%s\n' "$HOME/dotfiles/local/tlp/${DROPIN_NAME}"
    return 0
  fi
  return 1
}

state_get() {
  key="$1"
  [ -f "$STATE_FILE" ] || return 1
  sed -n "s/^${key}=//p" "$STATE_FILE" | head -n1
}

in_max() {
  [ "$(state_get active 2>/dev/null)" = "1" ]
}

save_state() {
  mkdir -p "$STATE_DIR"
  brightness="$1"
  rate="$2"
  position="$3"
  scale="$4"
  animations="$5"
  active_opacity="$6"
  inactive_opacity="$7"
  tmp="${STATE_FILE}.tmp"
  {
    printf 'active=1\n'
    printf 'brightness=%s\n' "$brightness"
    printf 'rate=%s\n' "$rate"
    printf 'position=%s\n' "$position"
    printf 'scale=%s\n' "$scale"
    printf 'animations=%s\n' "$animations"
    printf 'active_opacity=%s\n' "$active_opacity"
    printf 'inactive_opacity=%s\n' "$inactive_opacity"
  } >"$tmp"
  mv "$tmp" "$STATE_FILE"
}

clear_state() {
  rm -f "$STATE_FILE"
}

current_profile() {
  if command -v tlpctl >/dev/null 2>&1; then
    tlpctl get 2>/dev/null || printf 'unknown\n'
  else
    printf 'unknown\n'
  fi
}

monitor_block() {
  hyprctl monitors | awk -v m="$MON" '
    $0 ~ "Monitor " m { found=1; print; next }
    found {
      if ($0 ~ /^$/) exit
      print
    }'
}

panel_rate() {
  block="$1"
  mode=$(printf '%s\n' "$block" | grep -oE '[0-9]{2,5}x[0-9]{2,5}@[0-9]+(\.[0-9]+)?' | head -n1)
  printf '%s\n' "$mode" | cut -d@ -f2 | cut -d. -f1
}

set_panel_hz() {
  want="$1"
  block=$(monitor_block)
  if [ -z "$block" ]; then
    notify "Battery plan" "Monitor $MON not found."
    return 1
  fi

  position=$(printf '%s\n' "$block" | grep -oE 'at [0-9]+x[0-9]+' | head -n1 | sed 's/at //')
  scale=$(printf '%s\n' "$block" | grep -oE 'scale: [0-9.]+' | head -n1 | awk '{print $2}')
  current_mode=$(printf '%s\n' "$block" | grep -oE '[0-9]{2,5}x[0-9]{2,5}@[0-9]+(\.[0-9]+)?' | head -n1)
  res=$(printf '%s\n' "$current_mode" | cut -d@ -f1)
  [ -n "$position" ] || position="0x0"
  [ -n "$scale" ] || scale="1"

  exact=$(printf '%s\n' "$block" | grep -oE "${res}@[0-9]+(\.[0-9]+)?" | grep "@${want}" | head -n1)
  [ -n "$exact" ] || exact="${res}@${want}"

  result=$(hyprctl eval "hl.monitor({output=\"${MON}\",mode=\"${exact}\",position=\"${position}\",scale=${scale}})" 2>&1)
  if [ "$result" = "ok" ]; then
    return 0
  fi
  notify "Battery plan" "Could not set ${MON} to ${exact}."
  return 1
}

dim_backlight() {
  command -v brightnessctl >/dev/null 2>&1 || return 0
  current=$(brightnessctl -d intel_backlight get 2>/dev/null) || return 0
  max=$(brightnessctl -d intel_backlight max 2>/dev/null) || return 0
  target=$((max * BRIGHTNESS_PCT / 100))
  if [ "$current" -gt "$target" ]; then
    brightnessctl -d intel_backlight set "$target" >/dev/null
  fi
}

restore_backlight() {
  saved="$1"
  [ -n "$saved" ] || return 0
  command -v brightnessctl >/dev/null 2>&1 || return 0
  brightnessctl -d intel_backlight set "$saved" >/dev/null
}

hypr_opt() {
  hyprctl getoption "$1" 2>/dev/null | awk 'NR==1{print $2}'
}

disable_hypr_effects() {
  hyprctl eval 'hl.config({
    animations = { enabled = false },
    decoration = {
      active_opacity = 1.0,
      inactive_opacity = 1.0
    }
  })' >/dev/null
}

restore_hypr_effects() {
  anim="${1:-1}"
  active="${2:-0.9}"
  inactive="${3:-0.9}"
  case "$anim" in
    1|true) anim_lua=true ;;
    *) anim_lua=false ;;
  esac
  hyprctl eval "hl.config({
    animations = { enabled = ${anim_lua} },
    decoration = {
      active_opacity = ${active},
      inactive_opacity = ${inactive}
    }
  })" >/dev/null
}

cpu_cap_installed() {
  [ -f "$DROPIN_DEST" ]
}

install_cpu_cap() {
  src=$(dropin_src) || return 1
  if [ -f "$DROPIN_DEST" ] && cmp -s "$src" "$DROPIN_DEST"; then
    return 0
  fi
  if sudo -n install -m 644 "$src" "$DROPIN_DEST" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

apply_profile() {
  profile="$1"
  if ! command -v tlpctl >/dev/null 2>&1; then
    notify "Battery plan" "tlpctl is not installed."
    return 1
  fi
  tlpctl set "$profile" >/dev/null
}

apply_max() {
  block=$(monitor_block)
  rate=$(panel_rate "$block")
  position=$(printf '%s\n' "$block" | grep -oE 'at [0-9]+x[0-9]+' | head -n1 | sed 's/at //')
  scale=$(printf '%s\n' "$block" | grep -oE 'scale: [0-9.]+' | head -n1 | awk '{print $2}')
  brightness=""
  if command -v brightnessctl >/dev/null 2>&1; then
    brightness=$(brightnessctl -d intel_backlight get 2>/dev/null || true)
  fi
  animations=$(hypr_opt animations:enabled)
  active_opacity=$(hypr_opt decoration:active_opacity)
  inactive_opacity=$(hypr_opt decoration:inactive_opacity)
  case "$animations" in
    true|1) animations=1 ;;
    *) animations=0 ;;
  esac

  if ! in_max; then
    save_state "$brightness" "$rate" "$position" "$scale" "$animations" "$active_opacity" "$inactive_opacity"
  fi

  cap_note=""
  if install_cpu_cap; then
    cap_note="CPU turbo off, capped at 40%."
  else
    cap_note="CPU cap still needs one admin install (see the terminal, or the notification)."
  fi

  apply_profile power-saver || true
  set_panel_hz "$MAX_HZ" || true
  dim_backlight || true
  disable_hypr_effects || true

  src=$(dropin_src 2>/dev/null || true)
  if ! cpu_cap_installed && [ -n "$src" ]; then
    notify "Max battery" "Panel ${MAX_HZ} Hz, backlight ${BRIGHTNESS_PCT}%, animations off, windows opaque.

CPU is not capped yet. Run once:
sudo install -m 644 ${src} ${DROPIN_DEST} && tlpctl set power-saver

Then pick Max again, or that command is enough for the CPU cap.
Pick Balanced or Performance to restore the screen and effects."
    printf 'CPU cap is not installed. Run once:\n  sudo install -m 644 %s %s && tlpctl set power-saver\n' "$src" "$DROPIN_DEST"
  else
    notify "Max battery" "Panel ${MAX_HZ} Hz, backlight ${BRIGHTNESS_PCT}%, animations off, windows opaque. ${cap_note}
Pick Balanced or Performance to restore the screen and effects. Plugging in does not."
    printf 'Max battery on: %s Hz, backlight %s%%, effects off. %s\n' "$MAX_HZ" "$BRIGHTNESS_PCT" "$cap_note"
  fi
}

leave_max() {
  profile="$1"
  saved_brightness=$(state_get brightness 2>/dev/null || true)
  saved_rate=$(state_get rate 2>/dev/null || true)
  saved_animations=$(state_get animations 2>/dev/null || true)
  saved_active_opacity=$(state_get active_opacity 2>/dev/null || true)
  saved_inactive_opacity=$(state_get inactive_opacity 2>/dev/null || true)
  [ -n "$saved_animations" ] || saved_animations=1
  [ -n "$saved_active_opacity" ] || saved_active_opacity=0.9
  [ -n "$saved_inactive_opacity" ] || saved_inactive_opacity=0.9

  apply_profile "$profile" || true

  if in_max; then
    if [ -n "$saved_rate" ]; then
      set_panel_hz "$saved_rate" || true
    fi
    restore_backlight "$saved_brightness" || true
    restore_hypr_effects "$saved_animations" "$saved_active_opacity" "$saved_inactive_opacity" || true
    clear_state
  fi

  label="$profile"
  case "$profile" in
    balanced) label="Balanced" ;;
    performance) label="Performance" ;;
  esac
  notify "$label" "TLP profile set to ${profile}."
  printf '%s\n' "$label"
}

show_status() {
  profile=$(current_profile)
  block=$(monitor_block)
  rate=$(panel_rate "$block")
  bright="n/a"
  if command -v brightnessctl >/dev/null 2>&1; then
    bright=$(brightnessctl -d intel_backlight -m 2>/dev/null | cut -d, -f4 || true)
  fi
  mode="normal"
  in_max && mode="max battery"
  cap="not installed"
  cpu_cap_installed && cap="installed"
  printf 'mode:       %s\n' "$mode"
  printf 'tlp:        %s\n' "$profile"
  printf 'panel:      %s Hz\n' "${rate:-unknown}"
  printf 'backlight:  %s\n' "${bright:-unknown}"
  printf 'cpu cap:    %s (%s)\n' "$cap" "$DROPIN_DEST"
}

pick() {
  if command -v fuzzel >/dev/null 2>&1; then
    printf '%s\n' "$@" | fuzzel --dmenu \
      --prompt "Power plan " \
      --mesg "Max battery: 60 Hz, dim to ${BRIGHTNESS_PCT}%, no animations or window opacity" \
      --width 46 \
      --lines 3 \
      --minimal-lines \
      -I
    return $?
  fi
  if command -v rofi >/dev/null 2>&1; then
    printf '%s\n' "$@" | rofi -dmenu -p "Power plan" -i
    return $?
  fi
  echo "No fuzzel or rofi. Use: battery-plan.sh max|balanced|performance" >&2
  return 1
}

menu() {
  profile=$(current_profile)
  max_label="Max battery"
  bal_label="Balanced"
  perf_label="Performance"
  if in_max; then
    max_label="● Max battery"
  else
    case "$profile" in
      balanced) bal_label="● Balanced" ;;
      performance) perf_label="● Performance" ;;
      power-saver) max_label="Max battery  (tlp: power-saver)" ;;
    esac
  fi

  choice=$(pick "$max_label" "$bal_label" "$perf_label") || exit 0
  case "$choice" in
    *Max\ battery*) apply_max ;;
    *Balanced*) leave_max balanced ;;
    *Performance*) leave_max performance ;;
    *) exit 0 ;;
  esac
}

cmd="${1:-menu}"
case "$cmd" in
  menu) menu ;;
  max|battery|power-saver|saver) apply_max ;;
  balanced|bal) leave_max balanced ;;
  performance|perf|ac) leave_max performance ;;
  status) show_status ;;
  *)
    echo "Usage: battery-plan.sh [max|balanced|performance|status]" >&2
    exit 2
    ;;
esac
