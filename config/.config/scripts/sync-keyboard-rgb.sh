#!/bin/bash
# Fade MSI keyboard to wallust accent via OpenRGB SDK (~1.5s smoothstep).
# Needs: openrgb --server (niri startup) + local venv with openrgb-python.

set -u

SCRIPTS="${XDG_CONFIG_HOME:-$HOME/.config}/scripts"
VENV="${XDG_DATA_HOME:-$HOME/.local/share}/keyboard-rgb/venv"
PY="$VENV/bin/python"
SCRIPT="$SCRIPTS/sync-keyboard-rgb.py"
COLOR_FILE="$SCRIPTS/keyboard-color.txt"

command -v openrgb >/dev/null 2>&1 || exit 0
[[ -r "$COLOR_FILE" ]] || exit 0
[[ -f "$SCRIPT" ]] || exit 0

if [[ ! -x "$PY" ]]; then
  command -v python3 >/dev/null 2>&1 || exit 0
  mkdir -p "$(dirname "$VENV")"
  python3 -m venv "$VENV" || exit 0
  "$VENV/bin/pip" install -q --disable-pip-version-check openrgb-python || exit 0
fi

exec "$PY" "$SCRIPT"
