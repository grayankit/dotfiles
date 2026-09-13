# Neo Browser (NeoColab) Distrobox

Ubuntu 24.04 box for [Examly Neo Browser](https://lpucolab438.examly.io/) on Arch. Isolated from the host PID namespace and from CodeTantra’s `ubuntu22` box.

## Layout

| Path | Role |
|------|------|
| `local/.local/bin/neocolab-box` | Box helpers (`run`, `install`, `upgrade`, …) |
| `local/.local/bin/neo-browser` | App launcher (stowed to `~/.local/bin`) |
| `~/.local/share/distrobox/neocolab` | Isolated container home |
| `…/Applications/Neo-Browser.AppImage` | Symlink to the current versioned AppImage |
| `~/.local/share/applications/neo-browser.desktop` | Apps-menu entry (`Exec=neo-browser`) |

Container: **`neocolab`**, image `docker.io/library/ubuntu:24.04`, docker backend.

Flags: `--home` (isolated), `--unshare-ipc`, `--unshare-process`, `/dev/fuse`, `--shm-size=2g`. Host `/dev` is shared (camera / GPU).

## Launch

From the apps menu, or:

```bash
neo-browser
```

Prefer the menu / `gtk-launch neo-browser` over a shell. Neo can reject some parent process names (`zsh`, `timeout`, …).

The launcher forces X11 (`ELECTRON_OZONE_PLATFORM_HINT=x11`) so the window fills the screen, and uses host **Bibata-Modern-Classic** at 24px.

## First-time setup (this machine)

```bash
cd ~/dotfiles
stow local
neocolab-box install ~/Downloads/Neo-Browser-x.y.z.AppImage
```

Needs `distrobox` and a container runtime (`docker` or `podman`). The first enter runs Ubuntu init (a few minutes, little output). It is not stuck.

## Friend install (Arch, one shot)

Self-contained script — no clone/stow required. Copy `scripts/install-neocolab.sh` and the AppImage to their machine:

```bash
chmod +x install-neocolab.sh
./install-neocolab.sh ~/Downloads/Neo-Browser-x.y.z.AppImage
```

It will:

1. Install `distrobox`, `podman`, `fuse3`, `rsync`, `desktop-file-utils`, `xdg-utils`
2. Configure rootless Podman (`/etc/subuid` / `/etc/subgid`)
3. Write `~/.local/bin/neocolab-box` and `neo-browser`
4. Install a desktop entry
5. Create the `neocolab` box and install the AppImage

Re-run with a newer AppImage to upgrade.

## Upgrade

When a new AppImage is available:

```bash
neocolab-box upgrade ~/Downloads/Neo-Browser-x.y.z.AppImage
```

This copies it into the box `Applications/` dir, retargets `Neo-Browser.AppImage`, removes the previous versioned file, and re-checks AppImage apt deps. Isolated config (`~/.config/neo-browser` inside the box home) is kept.

## Commands

```text
neocolab-box                      # enter the box
neocolab-box run <cmd> [args…]    # run a command or AppImage
neocolab-box install <file|pkg>   # AppImage, .deb, or apt package
neocolab-box upgrade <file.AppImage>
neocolab-box apps
neocolab-box export <app>
neocolab-box sync
neocolab-box reset                # destroy container; isolated home is kept
```

If FUSE fails:

```bash
neocolab-box run Neo-Browser.AppImage --appimage-extract-and-run
```

## Reset

```bash
neocolab-box reset
neocolab-box install ~/Downloads/Neo-Browser-x.y.z.AppImage
```

`reset` only removes the container. AppImages and config in `~/.local/share/distrobox/neocolab` stay.

## Notes

- `ubuntu22` (CodeTantra) is unrelated; do not reuse it for Neo.
- Logs: `~/.local/share/distrobox/neocolab/.config/neo-browser/logs/`
