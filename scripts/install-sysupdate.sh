#!/bin/bash
# Replace the DankMaterialShell System Updater tab with sysupdate.
# Safe to re-run after a shell update.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SRC="$DOTFILES/sysupdate"
BIN="$HOME/.local/bin/sysupdate"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PLUGIN_DEST="$CONFIG_HOME/dms/plugins/sysupdate"
PAGE="$PLUGIN_DEST/UpdatesTab.qml"
SHELL_DIR="${DMS_SHELL:-$HOME/.local/share/dms-shell}"
TABS="$SHELL_DIR/Common/SettingsTabs.qml"
CONTENT="$SHELL_DIR/Modals/Settings/SettingsContent.qml"

if [[ ! -x "$SRC/sysupdate" || ! -f "$SRC/UpdatesTab.qml" ]]; then
  echo "missing $SRC" >&2
  exit 1
fi

echo "[*] Linking sysupdate..."
mkdir -p "$HOME/.local/bin" "$PLUGIN_DEST"
if [[ -e "$BIN" && ! -L "$BIN" ]]; then
  echo "[!] $BIN exists and is not a symlink" >&2
  exit 1
fi
ln -sfn "$SRC/sysupdate" "$BIN"
ln -sfn "$SRC/UpdatesTab.qml" "$PAGE"
chmod +x "$SRC/sysupdate"

if [[ ! -f "$TABS" || ! -f "$CONTENT" ]]; then
  echo "[!] dms-shell not found at $SHELL_DIR — binary is linked, tab skipped"
  exit 0
fi

echo "[*] Replacing the System Updater tab..."
python3 - "$TABS" "$CONTENT" "$PAGE" <<'PY'
import sys
from pathlib import Path

tabs_path, content_path, page = sys.argv[1:]
tabs = Path(tabs_path).read_text()
old = '''                {
                    "id": "updater",
                    "text": I18n.tr("System Updater"),
                    "icon": "refresh",
                    "tabIndex": 20,
                    "updaterOnly": true
                },'''
new = '''                {
                    "id": "updater",
                    "text": I18n.tr("Updates"),
                    "icon": "system_update",
                    "tabIndex": 20
                },'''
if old in tabs:
    tabs = tabs.replace(old, new, 1)
    print("  - renamed the sidebar entry and removed the built-in gate")
elif '"id": "updater"' in tabs and "updaterOnly" not in tabs.split('"id": "updater"')[1][:400]:
    print("  - sidebar entry already replaced")
else:
    raise SystemExit("could not find the System Updater entry in SettingsTabs.qml")
Path(tabs_path).write_text(tabs)

content = Path(content_path).read_text()
source_line = f'            source: "{page}"\n'
old_source = "            sourceComponent: SystemUpdaterTab {}\n"
if old_source in content:
    content = content.replace(old_source, source_line, 1)
    print("  - pointed the updater page at UpdatesTab.qml")
elif "UpdatesTab.qml" in content:
    # Keep the path current if the home directory or plugin path changed.
    import re
    content2, n = re.subn(
        r'            source: ".*UpdatesTab\.qml"\n',
        source_line,
        content,
        count=1,
    )
    if n != 1:
        raise SystemExit("updater page marker found, but the source line did not match")
    content = content2
    print("  - updater page path already set")
else:
    raise SystemExit("could not find the system updater loader in SettingsContent.qml")
Path(content_path).write_text(content)
PY

echo "[✓] sysupdate is installed"
echo "    Binary: $BIN"
echo "    Page:   $PAGE"
echo "    Restart the shell: dms restart"
