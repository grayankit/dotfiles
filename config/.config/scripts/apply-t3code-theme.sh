#!/bin/bash
# Publish the matugen palette as a T3 Code environment theme.
#
# The template is a material-token dump (both modes). This maps those tokens
# onto T3 Code's theme roles the same way the rest of the rice uses them:
# surface for the window, surface_container_high for panels, primary for the
# accent. Both appearances live in one file, so T3's system/light/dark toggle
# stays on the palette instead of falling back to stock.
#
# The themes directory is watched. Write to a temp file in that directory and
# rename into place so a client never reads a partial theme.

set -euo pipefail

src="${XDG_CACHE_HOME:-$HOME/.cache}/matugen/t3code.json"
dest_dir="${T3CODE_HOME:-$HOME/.t3}/userdata/themes"
dest="$dest_dir/matugen.json"
t3="${HOME}/.t3/bin/t3"

[ -f "$src" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
mkdir -p "$dest_dir"

python3 - "$src" "$dest" <<'PY'
import json
import os
import sys
import tempfile

src, dest = sys.argv[1], sys.argv[2]
with open(src) as fh:
    tokens = json.load(fh)

needed = (
    "surface",
    "surface_container_lowest",
    "surface_container_high",
    "surface_container_highest",
    "surface_bright",
    "surface_dim",
    "on_surface",
    "on_surface_variant",
    "primary",
    "on_primary",
    "primary_container",
    "on_primary_container",
    "primary_hover",
    "secondary_container",
    "on_secondary_container",
    "tertiary",
    "on_tertiary",
    "tertiary_container",
    "on_tertiary_container",
    "error",
    "error_container",
    "on_error_container",
    "outline",
    "outline_variant",
)


def roles(colors, appearance):
    missing = [key for key in needed if not colors.get(key)]
    if missing:
        raise SystemExit(f"t3code theme missing tokens: {', '.join(missing)}")
    # Recessed fills go darker than the window. In dark mode that is the
    # lowest container; in light mode surface_dim is the shaded step
    # (lowest is white, which would lift the field instead).
    recessed = (
        colors["surface_container_lowest"]
        if appearance == "dark"
        else colors["surface_dim"]
    )
    # Popovers need to separate from the window. surface_bright does that in
    # dark mode; in light mode it is the window itself, so use the white step.
    overlay = (
        colors["surface_bright"]
        if appearance == "dark"
        else colors["surface_container_lowest"]
    )
    text = colors["on_surface"]
    muted = colors["on_surface_variant"]
    return {
        "canvas": colors["surface"],
        "chrome": colors["surface"],
        "toolbar": colors["surface"],
        "toolbarForeground": text,
        "toolbarBorder": colors["outline_variant"],
        "toolbarControl": colors["surface_container_high"],
        "toolbarControlForeground": text,
        "toolbarControlHover": colors["surface_container_highest"],
        "surface": colors["surface_container_high"],
        "surfaceRaised": colors["surface_container_highest"],
        "surfaceOverlay": overlay,
        "text": text,
        "textMuted": muted,
        "border": colors["outline_variant"],
        "input": recessed,
        "focus": colors["primary"],
        "accent": colors["primary"],
        "accentForeground": colors["on_primary"],
        "secondary": colors["secondary_container"],
        "secondaryForeground": colors["on_secondary_container"],
        "muted": colors["surface_container_high"],
        "mutedForeground": muted,
        "placeholder": muted,
        "secondaryLabel": muted,
        "iconMuted": muted,
        "error": colors["error"],
        "errorForeground": colors["on_error_container"],
        "errorSurface": colors["error_container"],
        "update": colors["primary"],
        "updateForeground": colors["on_primary_container"],
        "updateSurface": colors["primary_container"],
        "accentSurface": colors["primary_container"],
        "accentSurfaceForeground": colors["on_primary_container"],
        "messageSurface": colors["primary_container"],
        "messageForeground": colors["on_primary_container"],
        "messageAction": colors["primary"],
        "messageActionForeground": colors["on_primary"],
        "messageActionHover": colors["primary_hover"],
        "codeBackground": recessed,
        "codeForeground": text,
        "searchMatchBackground": colors["tertiary_container"],
        "searchMatchForeground": colors["on_tertiary_container"],
        "searchMatchActiveBackground": colors["tertiary"],
        "searchMatchActiveForeground": colors["on_tertiary"],
        "sidebar": colors["surface_container_high"],
        "sidebarForeground": text,
        "sidebarMutedForeground": muted,
        "sidebarControlSurface": colors["surface_container_highest"],
        "sidebarRowHover": colors["surface_container_highest"],
        "sidebarRowActive": colors["surface_bright"],
        "sidebarRowSelected": colors["primary_container"],
        "sidebarBorder": colors["outline_variant"],
        "terminalBackground": colors["surface"],
        "terminalForeground": text,
        "terminalCursor": colors["primary"],
        "terminalSelection": colors["primary_container"],
        "terminalScrollbar": colors["outline"],
        "terminalScrollbarHover": muted,
    }


theme = {
    "name": "Matugen",
    "appearance": "dark",
    "colors": roles(tokens["dark"], "dark"),
    "variants": {"light": roles(tokens["light"], "light")},
}
fd, tmp = tempfile.mkstemp(prefix=".matugen.", suffix=".json", dir=os.path.dirname(dest))
try:
    with os.fdopen(fd, "w") as out:
        json.dump(theme, out, indent=2)
        out.write("\n")
    os.chmod(tmp, 0o644)
    os.replace(tmp, dest)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
PY

if [ -x "$t3" ]; then
    "$t3" theme set matugen >/dev/null 2>&1 || true
fi
