#!/bin/bash
# Install cachemanager from the dotfiles submodule.
# Safe to re-run. Does not install the optional root helper (that needs sudo).
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SRC="$DOTFILES/cachemanager"
BIN_DIR="$HOME/.local/bin"
BIN="$BIN_DIR/cachemanager"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PLUGIN_DEST="$CONFIG_HOME/dms/plugins/cachemanager"
SHELL_DIR="${DMS_SHELL:-$HOME/.local/share/dms-shell}"

if [[ ! -f "$SRC/go.mod" ]]; then
  echo "[*] Fetching cachemanager submodule..."
  git -C "$DOTFILES" submodule update --init -- cachemanager
fi

if [[ ! -f "$SRC/go.mod" ]]; then
  echo "[!] cachemanager submodule is missing at $SRC" >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "[!] go is not installed. Run scripts/install.sh first (go is in pkglist-pacman.txt)." >&2
  exit 1
fi

echo "[*] Building cachemanager..."
mkdir -p "$BIN_DIR"
(
  cd "$SRC"
  go build -o "$BIN" ./cmd/cachemanager
)
chmod 755 "$BIN"

echo "[*] Linking the DankMaterialShell plugin..."
mkdir -p "$(dirname "$PLUGIN_DEST")"
if [[ -e "$PLUGIN_DEST" && ! -L "$PLUGIN_DEST" ]]; then
  echo "[!] $PLUGIN_DEST exists and is not a symlink; leaving it alone" >&2
  exit 1
fi
ln -sfn "$SRC/plugins/cachemanager" "$PLUGIN_DEST"

echo "[*] Enabling the plugin and the control-center tile..."
python3 - "$CONFIG_HOME/dms/plugin_settings.json" "$CONFIG_HOME/dms/settings.json" <<'PY'
import json
import sys
from pathlib import Path

plugin_path, settings_path = map(Path, sys.argv[1:])

if plugin_path.exists():
    plugin = json.loads(plugin_path.read_text())
else:
    plugin_path.parent.mkdir(parents=True, exist_ok=True)
    plugin = {}
entry = plugin.get("cachemanager")
if not isinstance(entry, dict):
    entry = {}
if entry.get("enabled") is not True:
    entry["enabled"] = True
    plugin["cachemanager"] = entry
    plugin_path.write_text(json.dumps(plugin, indent=2) + "\n")
    print("  - enabled cachemanager in plugin_settings.json")
else:
    print("  - plugin already enabled")

if not settings_path.exists():
    print("  - no settings.json yet; open DankMaterialShell once, then re-run")
    raise SystemExit(0)

settings = json.loads(settings_path.read_text())
widgets = settings.get("controlCenterWidgets")
if not isinstance(widgets, list):
    print("  - controlCenterWidgets missing; skipped the tile")
    raise SystemExit(0)
if any(isinstance(w, dict) and w.get("id") == "plugin_cachemanager" for w in widgets):
    print("  - control-center tile already present")
    raise SystemExit(0)
widgets.append({"id": "plugin_cachemanager", "enabled": True, "width": 50})
settings_path.write_text(json.dumps(settings, indent=2) + "\n")
print("  - added the control-center tile")
PY

if [[ -f "$SHELL_DIR/Common/SettingsTabs.qml" && -f "$SHELL_DIR/Modals/Settings/SettingsContent.qml" ]]; then
  echo "[*] Adding Storage under System (re-applied after a shell update)..."
  DMS_SHELL="$SHELL_DIR" "$SRC/scripts/install-settings-tab.sh"
else
  echo "[!] dms-shell not found at $SHELL_DIR — plugin is linked, System tab skipped"
fi

echo "[✓] cachemanager is installed from $SRC"
echo "    Binary: $BIN"
echo "    Plugin: $PLUGIN_DEST"
echo "    Reload: dms ipc call plugins reload cachemanager"
echo "    A shell update wipes the System tab. Re-run this script, then: dms restart"
echo "    Optional, passwordless pacman/journal/coredump cleans only:"
echo "    sudo $SRC/scripts/install-priv.sh"
