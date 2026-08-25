#!/usr/bin/env python3
"""Fade MSI keyboard to wallust accent (waybar color2) via OpenRGB SDK."""

from __future__ import annotations

import fcntl
import os
import subprocess
import sys
import time
from pathlib import Path

DURATION_S = float(os.environ.get("KEYBOARD_RGB_FADE_MS", "1500")) / 1000.0
STEPS = int(os.environ.get("KEYBOARD_RGB_FADE_STEPS", "30"))
HOST = os.environ.get("OPENRGB_HOST", "127.0.0.1")
PORT = int(os.environ.get("OPENRGB_PORT", "6742"))

SCRIPTS = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "scripts"
COLOR_FILE = SCRIPTS / "keyboard-color.txt"
PREV_FILE = SCRIPTS / "keyboard-color.prev"
LOCK_PATH = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "sync-keyboard-rgb.lock"


def read_hex(path: Path) -> str | None:
    try:
        raw = path.read_text(encoding="utf-8").strip().lstrip("#")
    except OSError:
        return None
    if len(raw) != 6:
        return None
    try:
        int(raw, 16)
    except ValueError:
        return None
    return raw.upper()


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def smoothstep(t: float) -> float:
    t = 0.0 if t < 0 else 1.0 if t > 1 else t
    return t * t * (3.0 - 2.0 * t)


def lerp(a: int, b: int, t: float) -> int:
    return max(0, min(255, int(a + (b - a) * t + 0.5)))


def find_device(cli):
    for dev in cli.devices:
        name = (dev.name or "").upper()
        if "MSI" in name or "MYSTIC" in name:
            return dev
    return cli.devices[0] if cli.devices else None


def ensure_static(dev) -> None:
    static_idx = next(
        (i for i, m in enumerate(dev.modes) if (m.name or "").lower() == "static"),
        None,
    )
    if static_idx is None:
        return
    if getattr(dev, "active_mode", None) != static_idx:
        dev.set_mode(static_idx)


def set_color(dev, r: int, g: int, b: int) -> None:
    from openrgb.utils import RGBColor

    ensure_static(dev)
    dev.set_color(RGBColor(r, g, b))


def cli_oneshot(hex_color: str) -> bool:
    """Slow fallback when SDK server is down."""
    for args in (
        ["openrgb", "--noautoconnect", "-d", "MSI", "-m", "static", "-c", hex_color],
        ["openrgb", "--noautoconnect", "-d", "0", "-m", "static", "-c", hex_color],
    ):
        try:
            r = subprocess.run(args, capture_output=True, timeout=15)
            if r.returncode == 0:
                return True
        except (FileNotFoundError, subprocess.TimeoutExpired):
            continue
    return False


def main() -> int:
    new = read_hex(COLOR_FILE)
    if not new:
        return 0

    lock_f = open(LOCK_PATH, "a+", encoding="utf-8")
    try:
        fcntl.flock(lock_f.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return 0

    cli = None
    try:
        try:
            from openrgb import OpenRGBClient
        except ImportError:
            if cli_oneshot(new):
                PREV_FILE.write_text(new + "\n", encoding="utf-8")
            return 0

        try:
            cli = OpenRGBClient(name="wallust-keyboard", address=HOST, port=PORT)
        except Exception:
            cli = None

        if cli is None or not cli.devices:
            if cli_oneshot(new):
                PREV_FILE.write_text(new + "\n", encoding="utf-8")
            return 0

        dev = find_device(cli)
        if dev is None:
            return 0

        old = read_hex(PREV_FILE)
        nr, ng, nb = hex_to_rgb(new)

        if not old or old == new or STEPS < 2 or DURATION_S <= 0:
            set_color(dev, nr, ng, nb)
            PREV_FILE.write_text(new + "\n", encoding="utf-8")
            return 0

        or_, og, ob = hex_to_rgb(old)
        steps = max(2, STEPS)
        interval = DURATION_S / steps

        ensure_static(dev)
        for i in range(1, steps + 1):
            t = smoothstep(i / steps)
            set_color(
                dev,
                lerp(or_, nr, t),
                lerp(og, ng, t),
                lerp(ob, nb, t),
            )
            if i < steps:
                time.sleep(interval)

        PREV_FILE.write_text(new + "\n", encoding="utf-8")
        return 0
    finally:
        if cli is not None:
            try:
                cli.disconnect()
            except Exception:
                pass
        try:
            fcntl.flock(lock_f.fileno(), fcntl.LOCK_UN)
        except Exception:
            pass
        lock_f.close()


if __name__ == "__main__":
    sys.exit(main())
