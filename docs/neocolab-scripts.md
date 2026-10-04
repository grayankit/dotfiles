# NeoColab scripts

Installers and helpers for Examly **Neo Browser** in a Distrobox Ubuntu 24.04 box.

Gist (latest scripts): https://gist.github.com/grayankit/af3021bc19d12c32f2888b7e540555af

| Script | Where it runs |
|--------|----------------|
| `scripts/install-neocolab.sh` | Arch Linux |
| `scripts/install-neocolab.ps1` | Windows (calls WSL) |
| `scripts/install-neocolab-wsl.sh` | Ubuntu **inside** WSL2 |
| `scripts/fix-neocolab-shortcuts.ps1` | Windows, shortcuts only |
| `scripts/neocolab-kiosk.ahk` | Windows (AutoHotkey v2) |

Do **not** use Docker Desktop for GUI. WSL uses **Podman** inside Ubuntu.

---

## Arch

```bash
chmod +x install-neocolab.sh
./install-neocolab.sh ~/Downloads/Neo-Browser-x.y.z.AppImage
```

Or from the gist:

```bash
curl -fsSL https://gist.githubusercontent.com/grayankit/af3021bc19d12c32f2888b7e540555af/raw/install-neocolab.sh \
  | bash -s -- ~/Downloads/Neo-Browser-x.y.z.AppImage
```

Launch: apps menu **Neo Browser**, or `neo-browser`.

---

## Windows (WSL2)

Keep **both** files in the same folder as the AppImage:

- `install-neocolab.ps1`
- `install-neocolab-wsl.sh`

1. Optional wipe: `wsl --unregister Ubuntu`
2. Open **Ubuntu** from Start once and create the Linux user
3. PowerShell:

```powershell
.\install-neocolab.ps1 .\Neo-Browser-x.y.z.AppImage
```

First Distrobox init can take several minutes with little output.

Re-running the installer **rewrites** `~/.local/bin/neo-browser` and `~/.local/share/applications/neo-browser.desktop` (does not delete the box).

### Launch on Windows

- Start menu (under Ubuntu / penguin icon): **Neo Browser**
- Ubuntu terminal:

```bash
neocolab-box run Neo-Browser.AppImage
# or
~/.local/bin/neo-browser
```

Put an icon at `~/.icons/neo.png` if you want the desktop icon.

---

## After install (any OS)

```text
neocolab-box                         # enter the box
neocolab-box run Neo-Browser.AppImage
neocolab-box upgrade /path/to/Neo-Browser-x.y.z.AppImage
neocolab-box reset                   # destroy container; isolated home is kept
neocolab-chrome                      # Chrome in the same box (if installed)
```

Upgrade keeps isolated config (`~/.local/share/distrobox/neocolab/.config`).

---

## Windows kiosk (optional)

`neocolab-kiosk.ahk` needs [AutoHotkey v2](https://www.autohotkey.com/).

1. Run the script (tray icon)
2. Click the Neo or Chrome window
3. **Ctrl+Alt+L** — lock (always on top, Alt+Tab / Win / 3–4 finger gestures off)
4. **Ctrl+Alt+L** again — unlock

---

## Troubleshooting

| Symptom | What to do |
|---------|------------|
| `set: pipefail: invalid option name` | `.sh` has Windows CRLF. Use the `.ps1` (strips CR) or `tr -d '\r'` |
| `unable to find user … passwd` | Distrobox still initializing. Wait, then re-run install |
| Start menu does nothing | Launch from an Ubuntu terminal first; `Exec=` must be `~/.local/bin/neo-browser` |
| `wsl --update` 403 | Ignore. The installer no longer requires it |
| GPU / dbus errors in the terminal | Often harmless if the window still opens |

More detail: [neocolab.md](neocolab.md) (Arch) · [neocolab-wsl.md](neocolab-wsl.md) (Windows)
