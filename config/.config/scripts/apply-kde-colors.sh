#!/bin/bash
# Activate the KDE color scheme DMS generates and force Qt apps (esp. Dolphin)
# to pick them up. DMS emits DankMatugenDark/Light.colors and *does* call
# plasma-apply-colorscheme, but it always passes the same scheme name — and
# plasma-apply-colorscheme no-ops when that name is already active. DMS's apply
# therefore only lands once, after which kdeglobals freezes and KDE apps stop
# following the wallpaper. Alternating DankMatugen1/DankMatugen2 around it forces
# each of DMS's applies to be a real name change, which is what unfreezes it.
#
# The base is the mode-correct DankMatugenDark/Light file (read from DMS's own
# dms-colors.json), not the generic DankMatugen.colors — those two differ in
# DecorationFocus, which would leave Dolphin's focus accent out of step with
# other KDE apps.
#
# This fires from a matugen post_hook, so whether DankMatugenDark/Light has been
# rewritten for the NEW wallpaper yet is a race — sometimes yes, sometimes it
# still holds the previous wallpaper. When it's the latter the copy below bakes
# stale colours into DankMatugen1/2, and whenever kdeglobals ends up on one of
# them every KDE app renders a wallpaper behind (observed: Dolphin stuck on
# #83D5C5 while kdeglobals said #BEC2FF). A one-shot delayed re-pass, scheduled
# below, re-copies once DMS is done and carries the Dolphin restart with it, so
# at rest 1/2 always match Dark and kdeglobals always holds current colours.

# Outside a full Plasma session Dolphin often ignores D-Bus palette notifies —
# restart it and restore open folders.

set -euo pipefail

if [ "${DANK_KDE_REFRESH:-}" != "1" ]; then
    # setsid detaches from matugen's process group so the pass survives its exit.
    if command -v setsid >/dev/null 2>&1; then
        setsid sh -c "sleep 6; DANK_KDE_REFRESH=1 '$0'" >/dev/null 2>&1 &
    else
        ( sleep 6; DANK_KDE_REFRESH=1 "$0" ) >/dev/null 2>&1 &
    fi
fi

SCHEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
STATE_COLORS="${XDG_STATE_HOME:-$HOME/.local/state}/DankMaterialShell/dms-colors.json"
CACHE_COLORS="${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json"

MODE="dark"
for f in "$STATE_COLORS" "$CACHE_COLORS"; do
    [ -f "$f" ] || continue
    MODE="$(sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$f" | head -1)"
    [ -n "$MODE" ] && break
done
case "$MODE" in
    light) BASE_SCHEME="$SCHEME_DIR/DankMatugenLight.colors" ;;
    *)     BASE_SCHEME="$SCHEME_DIR/DankMatugenDark.colors" ;;
esac
# Fall back to the generic scheme if the mode-specific one is not there yet.
[ -f "$BASE_SCHEME" ] || BASE_SCHEME="$SCHEME_DIR/DankMatugen.colors"

if [ ! -f "$BASE_SCHEME" ]; then
    exit 0
fi

if ! command -v plasma-apply-colorscheme >/dev/null 2>&1; then
    exit 0
fi

mkdir -p "$SCHEME_DIR"
# DMS names the scheme "Dank Matugen"; the alternating copies need matching
# Name=/ColorScheme= keys or plasma-apply-colorscheme silently rejects them.
sed -e 's/^Name=.*/Name=DankMatugen1/' \
    -e 's/^ColorScheme=.*/ColorScheme=DankMatugen1/' \
    "$BASE_SCHEME" >"$SCHEME_DIR/DankMatugen1.colors"
sed -e 's/^Name=.*/Name=DankMatugen2/' \
    -e 's/^ColorScheme=.*/ColorScheme=DankMatugen2/' \
    "$BASE_SCHEME" >"$SCHEME_DIR/DankMatugen2.colors"

CURRENT="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
if [ "$CURRENT" = "DankMatugen1" ]; then
    NEXT="DankMatugen2"
else
    NEXT="DankMatugen1"
fi

plasma-apply-colorscheme "$NEXT" >/dev/null 2>&1 || true

# Deliberately NOT pinning dolphinrc's [UiSettings] ColorScheme. That key sent
# Dolphin to DankMatugen1 while kdeglobals pointed at DankMatugenDark, and
# because of the ordering note above DankMatugen1 held the previous wallpaper's
# colours — Dolphin was the one app visibly a wallpaper behind (#83D5C5 vs
# #BEC2FF). It now follows kdeglobals like every other KDE app.

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

# Only the delayed pass restarts Dolphin: at first-pass time kdeglobals still
# holds the previous wallpaper's colours, so restarting here would reload the
# stale palette — the exact bug this is meant to fix.
if [ "${DANK_KDE_REFRESH:-}" = "1" ]; then
    restart_dolphin
fi
