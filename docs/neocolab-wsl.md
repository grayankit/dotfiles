# Neo Browser (NeoColab) on Windows (WSL2)

**How to run the installers:** [neocolab-scripts.md](neocolab-scripts.md)

The `ubuntu:24.04` image is portable. Distrobox is not — it needs a Linux host. On Windows that host is **WSL2 Ubuntu** with **Podman inside WSL**, not Docker Desktop.

```
Windows 11 (WSLg)
  └── WSL2 Ubuntu
        └── podman
              └── distrobox  neocolab  (ubuntu:24.04)
                    └── Neo-Browser.AppImage
```

## Fresh install (PowerShell)

Put **both** `install-neocolab.ps1` and `install-neocolab-wsl.sh` in the same folder as the AppImage.

1. Optional wipe: `wsl --unregister Ubuntu`
2. Open **Ubuntu** from Start once and create the Linux user
3. Then:

```powershell
.\install-neocolab.ps1 .\Neo-Browser-2.0.9.AppImage
```

The `.ps1` enables systemd, copies the `.sh` as LF, runs Distrobox/Podman setup, and writes Start Menu shortcuts that exec the Linux binaries directly (`wsl -d Ubuntu -e /home/USER/.local/bin/neo-browser`).

If Ubuntu was just installed, reboot when Windows asks, open Ubuntu once, then re-run the `.ps1`.

## Inside WSL only

```bash
./install-neocolab-wsl.sh ~/Downloads/Neo-Browser-2.0.9.AppImage
```

## What it installs

- `distrobox` + **podman** (not Docker Desktop)
- Isolated `neocolab` box (`--home`, `--unshare-ipc`, `--unshare-process`, FUSE, `shm-size=2g`)
- Waits until Distrobox init creates your user (avoids `unable to find user … passwd`)
- AppImage launcher uses `--appimage-extract-and-run` (FUSE is flaky in nested WSL)
- `neo-browser` and `neocolab-chrome` (Chrome in the same box)
- `.desktop` files so WSLg can put them in the Windows Start menu (under Ubuntu)

## Launch

Windows Start → **Ubuntu** → Neo Browser, or:

```powershell
wsl -d Ubuntu -e $HOME/.local/bin/neo-browser
```

(`$HOME` here is the Linux home, e.g. `/home/ssumi/.local/bin/neo-browser`.)

Logs: `~/.local/share/distrobox/neocolab/launch.log` inside WSL.

## What this does **not** do

- Windows processes are already absent from Linux `/proc`; this is not a way to hide the Windows desktop from screen share.
- WSLg remotes Linux windows onto the **Windows** desktop. A full-display capture can still show other Windows windows.
- Examly may still detect WSL/VM, extra monitors, or unusual parent processes. That is not worked around here.

## Requirements

- Windows 11 (or Windows 10 build 19044+) with WSLg (`wsl --update`)
- WSL **2** Ubuntu
- GPU driver from Intel/AMD/NVIDIA for WSLg acceleration
- Webcam (if the exam needs it): optional `usbipd-win` — not installed by this script
