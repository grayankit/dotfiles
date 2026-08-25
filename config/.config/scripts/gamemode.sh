#!/usr/bin/env sh
# Toggle performance mode: disable animations + force solid windows on niri.

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "Gamemode" "$1"
  fi
}

is_niri() {
  [ "${XDG_CURRENT_DESKTOP:-}" = "niri" ] || pgrep -x niri >/dev/null 2>&1
}

niri_dir="${XDG_CONFIG_HOME:-$HOME/.config}/niri"
opacity_conf="$niri_dir/opacity.kdl"
game_conf="$niri_dir/gamemode.kdl"
game_flag="$niri_dir/.gamemode-on"
opaque_flag="$niri_dir/.opaque-on"

write_opacity_glass() {
  rm -f "$opaque_flag"
  cat >"$opacity_conf" <<'EOF'
// Written by ~/.config/scripts/opacity-toggle.sh and gamemode.sh
// Included last from config.kdl — global opacity + blur (glass mode).
window-rule {
    opacity 0.9
    background-effect {
        blur true
    }
}
EOF
}

write_opacity_solid() {
  touch "$opaque_flag"
  cat >"$opacity_conf" <<'EOF'
// Written by ~/.config/scripts/opacity-toggle.sh and gamemode.sh
// Included last from config.kdl — solid mode (no blur).
window-rule {
    opacity 1.0
}
EOF
}

niri_gamemode() {
  if [ -f "$game_flag" ]; then
    rm -f "$game_flag"
    cat >"$game_conf" <<'EOF'
// Written by ~/.config/scripts/gamemode.sh
// Empty (comments only) = normal animations. Included last from config.kdl.
EOF
    write_opacity_glass
    notify "Off (anim + glass + blur)"
  else
    touch "$game_flag"
    cat >"$game_conf" <<'EOF'
// gamemode ON — animations disabled
animations {
    off
}
EOF
    write_opacity_solid
    notify "On (no anim + solid)"
  fi
}

hypr_gamemode() {
  HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
  if [ "$HYPRGAMEMODE" = "true" ] || [ "$HYPRGAMEMODE" = "1" ]; then
    hyprctl eval "hl.config({
        animations = { enabled = false },
        decoration = {
            blur = { enabled = false },
            shadow = { enabled = false },
            active_opacity = 1.0,
            inactive_opacity = 1.0
        }
    })"
    notify "On"
    exit 0
  fi
  hyprctl reload
  notify "Off"
}

if is_niri; then
  niri_gamemode
else
  hypr_gamemode
fi
