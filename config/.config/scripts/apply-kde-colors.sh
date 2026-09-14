#!/bin/bash
# Apply wallust KDE colors and force Qt apps (esp. Dolphin) to pick them up.
# plasma-apply-colorscheme no-ops when the same scheme name is already active,
# so we alternate Wallust1/Wallust2. Outside a full Plasma session Dolphin
# often ignores D-Bus palette notifies — restart it and restore open folders.

set -euo pipefail

SCHEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
BASE_SCHEME="$SCHEME_DIR/Wallust.colors"

if [ ! -f "$BASE_SCHEME" ]; then
    exit 0
fi

if ! command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    exit 0
fi

mkdir -p "$SCHEME_DIR"
sed -e 's/^Name=Wallust$/Name=Wallust1/' \
    -e 's/^ColorScheme=Wallust$/ColorScheme=Wallust1/' \
    "$BASE_SCHEME" >"$SCHEME_DIR/Wallust1.colors"
sed -e 's/^Name=Wallust$/Name=Wallust2/' \
    -e 's/^ColorScheme=Wallust$/ColorScheme=Wallust2/' \
    "$BASE_SCHEME" >"$SCHEME_DIR/Wallust2.colors"

CURRENT="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
if [ "$CURRENT" = "Wallust1" ]; then
    NEXT="Wallust2"
else
    NEXT="Wallust1"
fi

plasma-apply-colorscheme "$NEXT" >/dev/null 2>&1 || true

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme "$NEXT"
fi

# Extra notifies for Qt / KF apps (helps some clients outside Plasma)
python3 - "$NEXT" <<'PY' 2>/dev/null || true
import sys
import subprocess

try:
    import dbus
except ImportError:
    sys.exit(0)

scheme = sys.argv[1]
bus = dbus.SessionBus()

def keys(*names):
    return dbus.Array([dbus.ByteArray(n.encode()) for n in names], signature="ay")

msg = dbus.lowlevel.SignalMessage("/kdeglobals", "org.kde.kconfig.notify", "ConfigChanged")
body = dbus.Dictionary(
    {
        "General": keys("ColorScheme", "ColorSchemeHash"),
        "Colors:View": keys(
            "BackgroundNormal", "ForegroundNormal", "BackgroundAlternate",
            "DecorationFocus", "DecorationHover",
        ),
        "Colors:Window": keys(
            "BackgroundNormal", "ForegroundNormal", "BackgroundAlternate",
            "DecorationFocus", "DecorationHover",
        ),
        "Colors:Button": keys(
            "BackgroundNormal", "ForegroundNormal", "BackgroundAlternate",
            "DecorationFocus", "DecorationHover",
        ),
        "Colors:Selection": keys("BackgroundNormal", "ForegroundNormal"),
        "Colors:Header": keys("BackgroundNormal", "ForegroundNormal"),
        "Colors:Tooltip": keys("BackgroundNormal", "ForegroundNormal"),
        "Colors:Complementary": keys("BackgroundNormal", "ForegroundNormal"),
        "WM": keys(
            "activeBackground", "activeForeground",
            "inactiveBackground", "inactiveForeground",
        ),
        "KDE": keys("widgetStyle"),
    },
    signature="saay",
)
msg.append(body, signature="a{saay}")
bus.send_message(msg)

for iface in (
    "org.freedesktop.portal.Settings",
    "org.freedesktop.impl.portal.Settings",
):
    m = dbus.lowlevel.SignalMessage(
        "/org/freedesktop/portal/desktop", iface, "SettingChanged"
    )
    m.append("org.kde.kdeglobals.General", signature="s")
    m.append("ColorScheme", signature="s")
    m.append(dbus.String(scheme), signature="v")
    bus.send_message(m)

# 0=Palette, 2=Style, 3=Settings
for t in (0, 2, 3):
    subprocess.run(
        [
            "dbus-send",
            "--session",
            "--type=signal",
            "/KGlobalSettings",
            "org.kde.KGlobalSettings.notifyChange",
            f"int32:{t}",
            "int32:0",
        ],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
PY

# Soft-restart Dolphin so it reloads the palette; restore open folders via hyprctl titles
restart_dolphin() {
    command -v dolphin >/dev/null 2>&1 || return 0
    pgrep -x dolphin >/dev/null 2>&1 || return 0

    local dirs=()
    if command -v hyprctl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
        mapfile -t dirs < <(python3 - <<'PY'
import json, os, re, subprocess
try:
    raw = subprocess.check_output(["hyprctl", "clients", "-j"], text=True)
    clients = json.loads(raw)
except Exception:
    raise SystemExit(0)
home = os.path.expanduser("~")
seen = set()
for c in clients:
    cls = f'{c.get("class") or ""} {c.get("initialClass") or ""}'.lower()
    if "dolphin" not in cls:
        continue
    title = c.get("title") or ""
    # Titles look like "/home/user — Dolphin" or "trash:/ — Dolphin"
    title = re.sub(r"\s*[—\-–]\s*Dolphin.*$", "", title, flags=re.I).strip()
    if not title or title.lower() in ("dolphin", "home"):
        path = home
    elif title.startswith("/") or "://" in title or title.endswith(":/"):
        path = title
    elif title.startswith("~"):
        path = os.path.expanduser(title)
    else:
        continue
    # Allow real dirs and dolphin URLs (trash:/, timeline:/, …)
    ok = os.path.isdir(path) or (":" in path and not path.startswith("/"))
    if ok and path not in seen:
        seen.add(path)
        print(path)
PY
)
    fi

    # Quit all dolphin instances cleanly
    if command -v qdbus6 >/dev/null 2>&1; then
        while read -r svc; do
            [ -n "$svc" ] || continue
            qdbus6 "$svc" /MainApplication quit 2>/dev/null \
                || qdbus6 "$svc" /dolphin/Dolphin_1 org.kde.dolphin.MainWindow.quit 2>/dev/null \
                || true
        done < <(qdbus6 2>/dev/null | grep -E '^ org\.kde\.dolphin' || true)
    fi
    # Fallback if still running
    sleep 0.2
    if pgrep -x dolphin >/dev/null 2>&1; then
        killall -TERM dolphin 2>/dev/null || true
        sleep 0.3
    fi

    if [ "${#dirs[@]}" -eq 0 ]; then
        dirs=("$HOME")
    fi

    # Relaunch one window per restored directory
    for d in "${dirs[@]}"; do
        dolphin --new-window "$d" >/dev/null 2>&1 &
    done
}

restart_dolphin
