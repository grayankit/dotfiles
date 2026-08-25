#!/usr/bin/env sh
# Global solid ↔ glass toggle for niri (rewrites opacity.kdl, hot-reloaded).

conf="${XDG_CONFIG_HOME:-$HOME/.config}/niri/opacity.kdl"
flag="${XDG_CONFIG_HOME:-$HOME/.config}/niri/.opaque-on"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u low "Opacity" "$1"
  fi
}

if [ -f "$flag" ]; then
  rm -f "$flag"
  cat >"$conf" <<'EOF'
// Written by ~/.config/scripts/opacity-toggle.sh and gamemode.sh
// Included last from config.kdl — global opacity + blur (glass mode).
window-rule {
    opacity 0.9
    background-effect {
        blur true
    }
}
EOF
  notify "Glass + blur"
else
  touch "$flag"
  cat >"$conf" <<'EOF'
// Written by ~/.config/scripts/opacity-toggle.sh and gamemode.sh
// Included last from config.kdl — solid mode (no blur).
window-rule {
    opacity 1.0
}
EOF
  notify "Solid (no blur)"
fi
