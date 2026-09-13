#!/usr/bin/env bash
# Install Neo Browser (NeoColab) on Arch via Distrobox.
#
# Usage:
#   ./install-neocolab.sh /path/to/Neo-Browser-x.y.z.AppImage
#
# Idempotent: re-running with a new AppImage upgrades in place.
set -euo pipefail

BOX_NAME="neocolab"
BOX_IMAGE="docker.io/library/ubuntu:24.04"
BOX_HOME="${HOME}/.local/share/distrobox/neocolab"
BIN_DIR="${HOME}/.local/bin"
APPS_DIR="${HOME}/.local/share/applications"
ICONS_DIR="${HOME}/.local/share/icons"

die() {
  echo "error: $*" >&2
  exit 1
}

need_rootless_ids() {
  local conf=$1
  local user=$2
  local uid=$3
  if [ ! -f "$conf" ] || ! grep -q "^${user}:" "$conf" 2>/dev/null; then
    echo "  configuring $(basename "$conf") for rootless containers..."
    echo "${user}:${uid}00000:65536" | sudo tee -a "$conf" >/dev/null
  fi
}

install_host_packages() {
  echo "[1/5] Installing host packages..."
  sudo pacman -S --needed --noconfirm \
    distrobox \
    podman \
    fuse3 \
    rsync \
    desktop-file-utils \
    xdg-utils

  need_rootless_ids /etc/subuid "$(id -un)" "$(id -u)"
  need_rootless_ids /etc/subgid "$(id -un)" "$(id -u)"

  # Prefer podman for rootless; distrobox auto-detects.
  if command -v podman >/dev/null 2>&1; then
    export DBX_CONTAINER_MANAGER=podman
  fi
}

write_helpers() {
  echo "[2/5] Installing launchers to ${BIN_DIR}..."
  mkdir -p "$BIN_DIR"

  cat > "${BIN_DIR}/neocolab-box" <<'NEOCOLAB_BOX'
#!/usr/bin/env bash
set -eu

BOX_NAME="neocolab"
BOX_IMAGE="docker.io/library/ubuntu:24.04"
BOX_HOME="${HOME}/.local/share/distrobox/neocolab"
BOX_APPS="${BOX_HOME}/Applications"
NEO_APPIMAGE="Neo-Browser.AppImage"
HOST_APPS="${HOME}/.local/share/applications"
HOST_ICONS="${HOME}/.local/share/icons"
DISTROBOX="${DISTROBOX:-/usr/bin/distrobox}"

APPIMAGE_DEPS=(
  fuse3
  libfuse2t64
  libglib2.0-0t64
  libgtk-3-0t64
  libnss3
  libnspr4
  libdbus-1-3
  libatk1.0-0t64
  libatk-bridge2.0-0t64
  libcups2t64
  libpango-1.0-0
  libcairo2
  libx11-6
  libxcomposite1
  libxdamage1
  libxext6
  libxfixes3
  libxrandr2
  libgbm1
  libexpat1
  libxkbcommon0
  libudev1
  libasound2t64
  libatspi2.0-0t64
  libxcb1
  libglib2.0-bin
  gsettings-desktop-schemas
  dconf-gsettings-backend
  mutter-common
  gnome-shell-common
  gnome-settings-daemon-common
  dbus
  dbus-x11
  xdg-utils
)

box_enter() {
  "$DISTROBOX" enter "$BOX_NAME" -- "$@"
}

ensure_binfmt() {
  box_enter sh -c '
    if [ -e /proc/sys/fs/binfmt_misc/appimage_type_2 ] ||
       [ ! -e /proc/sys/fs/binfmt_misc/register ]
    then
      sudo mount -t binfmt_misc none /proc/sys/fs/binfmt_misc
    fi
  ' >/dev/null 2>&1 || true
}

ensure_dbus() {
  box_enter sudo sh -c '
    mkdir -p /run/dbus
    [ -S /run/dbus/system_bus_socket ] ||
      dbus-daemon --system --fork
  ' >/dev/null 2>&1 || true
}

ensure_appimage_deps() {
  box_enter sh -c '
    missing=""
    for p in '"${APPIMAGE_DEPS[*]}"'; do
      dpkg -s "$p" >/dev/null 2>&1 || missing="$missing $p"
    done
    if [ -n "$missing" ]; then
      sudo apt-get update
      sudo apt-get install -y $missing
    fi
  ' || true
}

ensure_cursor() {
  local theme="${XCURSOR_THEME:-}"
  local size="${XCURSOR_SIZE:-24}"
  local host_theme=""

  mkdir -p "$BOX_HOME/.icons/default" "$BOX_HOME/.config/gtk-3.0"

  if [ -n "$theme" ]; then
    for d in \
      "/run/host/usr/share/icons/${theme}" \
      "/run/host${HOME}/.local/share/icons/${theme}" \
      "/run/host${HOME}/.icons/${theme}"
    do
      if [ -d "$d" ] || [ -L "$d" ]; then
        host_theme=$d
        break
      fi
    done
  fi

  if [ -n "$host_theme" ]; then
    ln -sfn "$host_theme" "$BOX_HOME/.icons/${theme}"
    cat > "$BOX_HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=${theme}
EOF
    cat > "$BOX_HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-cursor-theme-name=${theme}
gtk-cursor-theme-size=${size}
EOF
  fi
}

ensure_box() {
  mkdir -p "$BOX_HOME"
  ensure_cursor

  if ! "$DISTROBOX" list 2>/dev/null |
    awk 'NR > 1 { print $3 }' |
    grep -Fxq "$BOX_NAME"
  then
    echo "Creating '${BOX_NAME}' box from ${BOX_IMAGE}..."
    echo "The first command that enters the box runs a one-time setup"
    echo "that pulls its base packages. That takes a few minutes and"
    echo "prints nothing — it is not stuck."
    "$DISTROBOX" create \
      --name "$BOX_NAME" \
      --image "$BOX_IMAGE" \
      --yes \
      --home "$BOX_HOME" \
      --unshare-ipc \
      --unshare-process \
      --additional-flags "--device /dev/fuse --shm-size=2g"
  fi

  ensure_binfmt
  ensure_dbus
}

sync_launchers() {
  mkdir -p "$HOST_APPS" "$HOST_ICONS"

  if [ -d "${BOX_HOME}/.local/share/applications" ]; then
    rsync -rlpt --no-owner --no-group \
      "${BOX_HOME}/.local/share/applications/" \
      "${HOST_APPS}/" || true
  fi

  if [ -d "${BOX_HOME}/.local/share/icons" ]; then
    rsync -rlpt --no-owner --no-group \
      "${BOX_HOME}/.local/share/icons/" \
      "${HOST_ICONS}/" || true
  fi

  update-desktop-database "$HOST_APPS" 2>/dev/null || true
}

cmd_run() {
  if [ "$#" -eq 0 ]; then
    echo "usage: neocolab-box run <command> [args...]" >&2
    exit 2
  fi

  ensure_box

  local target=$1
  shift

  case "$target" in
    "~/"*)
      target="${BOX_HOME}/${target#\~/}"
      ;;
    */*) ;;
    *)
      if [ -e "${BOX_APPS}/${target}" ]; then
        target="${BOX_APPS}/${target}"
      fi
      ;;
  esac

  exec "$DISTROBOX" enter "$BOX_NAME" -- "$target" "$@"
}

install_neo_appimage() {
  local abs=$1
  local base
  base=$(basename "$abs")

  mkdir -p "$BOX_APPS"
  cp -f "$abs" "${BOX_APPS}/${base}"
  chmod +x "${BOX_APPS}/${base}"

  case "$base" in
    Neo-Browser*.AppImage | Neo-Browser*.appimage | *.AppImage | *.appimage)
      ln -sfn "$base" "${BOX_APPS}/${NEO_APPIMAGE}"
      ;;
  esac

  echo
  echo "Installed:"
  echo "  ${BOX_APPS}/${base}"
  echo
  echo "Run:"
  echo "  neo-browser"
  echo "  neocolab-box run ${NEO_APPIMAGE}"
  echo
  echo "If FUSE fails:"
  echo "  neocolab-box run ${NEO_APPIMAGE} --appimage-extract-and-run"
}

remove_old_neo_appimages() {
  local keep=$1
  local f
  for f in "${BOX_APPS}"/Neo-Browser*.AppImage "${BOX_APPS}"/Neo-Browser*.appimage; do
    [ -e "$f" ] || continue
    [ -L "$f" ] && continue
    [ "$(basename "$f")" = "$keep" ] && continue
    echo "Removing old $(basename "$f")"
    rm -f "$f"
  done
}

cmd_upgrade() {
  if [ "$#" -ne 1 ]; then
    echo "usage: neocolab-box upgrade <file.AppImage>" >&2
    exit 2
  fi

  local item=$1
  case "$item" in
    *.AppImage | *.appimage) ;;
    *)
      echo "not an AppImage: $item" >&2
      exit 2
      ;;
  esac

  if [ ! -f "$item" ]; then
    echo "no such file: $item" >&2
    exit 1
  fi

  ensure_box

  local abs base
  abs=$(readlink -f "$item")
  base=$(basename "$abs")

  echo "Upgrading Neo Browser to $base..."
  ensure_appimage_deps
  install_neo_appimage "$abs"
  remove_old_neo_appimages "$base"
  echo
  echo "Done."
}

cmd_install() {
  if [ "$#" -eq 0 ]; then
    echo "usage: neocolab-box install <file.AppImage|file.deb|apt-package>..." >&2
    exit 2
  fi

  ensure_box

  local item abs base
  for item in "$@"; do
    case "$item" in
      *.AppImage | *.appimage)
        if [ ! -f "$item" ]; then
          echo "no such file: $item" >&2
          exit 1
        fi

        abs=$(readlink -f "$item")
        base=$(basename "$abs")

        echo "Installing AppImage $base into '${BOX_NAME}'..."
        ensure_appimage_deps
        install_neo_appimage "$abs"
        ;;
      *.deb)
        if [ ! -f "$item" ]; then
          echo "no such file: $item" >&2
          exit 1
        fi
        abs=$(readlink -f "$item")
        echo "Installing $abs..."
        box_enter sudo apt-get update
        box_enter sudo apt-get install -y "$abs"
        ;;
      *)
        echo "Installing apt package: $item..."
        box_enter sudo apt-get update
        box_enter sudo apt-get install -y "$item"
        ;;
    esac
  done

  echo
  echo "Done."
}

cmd_apps() {
  ensure_box
  echo "Installed desktop applications:"
  box_enter sh -c '
    find \
      /usr/share/applications \
      "$HOME/.local/share/applications" \
      -maxdepth 1 \
      -type f \
      -name "*.desktop" \
      -printf "%f\n" \
      2>/dev/null |
    sed "s/\.desktop$//" |
    sort -u
  '
}

cmd_export() {
  if [ "$#" -eq 0 ]; then
    echo "usage: neocolab-box export <app-name>..." >&2
    exit 2
  fi

  ensure_box

  local app
  for app in "$@"; do
    echo "Exporting $app..."
    box_enter distrobox-export --app "$app"
  done

  sync_launchers
  echo
  echo "Exported to the host launcher."
}

cmd_sync() {
  ensure_box
  sync_launchers
  echo "Box '${BOX_NAME}' is in sync."
}

cmd_reset() {
  echo
  echo "WARNING:"
  echo "This destroys the '${BOX_NAME}' container."
  echo "All packages installed inside the container are removed."
  echo "The isolated home is kept:"
  echo "  ${BOX_HOME}"
  echo
  printf 'Continue? [y/N] '
  read -r reply
  case "$reply" in
    y | Y) ;;
    *)
      echo "Aborted."
      exit 1
      ;;
  esac

  "$DISTROBOX" rm --force "$BOX_NAME" 2>/dev/null || true
  ensure_box
  echo
  echo "Recreated '${BOX_NAME}'."
  echo
  echo "Reinstall the AppImage dependencies with:"
  echo "  neocolab-box install <file.AppImage>"
}

cmd_enter() {
  ensure_box
  if [ "$#" -eq 0 ]; then
    exec "$DISTROBOX" enter "$BOX_NAME"
  fi
  exec "$DISTROBOX" enter "$BOX_NAME" -- "$@"
}

usage() {
  cat <<EOF
usage: neocolab-box [command]

  (no args)              Enter the ${BOX_NAME} box
  run <cmd> [args...]    Run a command or AppImage inside the box
  install <file|pkg>...  Install an AppImage, .deb, or apt package
  upgrade <file.AppImage>  Replace Neo Browser with a new AppImage
  apps                   List desktop applications in the box
  export <app>...        Export a desktop app to the host launcher
  sync                   Sync exported launchers to the host
  reset                  Destroy and recreate the container
  -h, --help             Show this help

Any other arguments are passed to: distrobox enter ${BOX_NAME} --
EOF
}

main() {
  if [ "$#" -eq 0 ]; then
    cmd_enter
  fi

  case "$1" in
    run)
      shift
      cmd_run "$@"
      ;;
    install)
      shift
      cmd_install "$@"
      ;;
    upgrade)
      shift
      cmd_upgrade "$@"
      ;;
    apps)
      shift
      cmd_apps "$@"
      ;;
    export)
      shift
      cmd_export "$@"
      ;;
    sync)
      shift
      cmd_sync "$@"
      ;;
    reset)
      shift
      cmd_reset "$@"
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      cmd_enter "$@"
      ;;
  esac
}

main "$@"
NEOCOLAB_BOX

  cat > "${BIN_DIR}/neo-browser" <<'NEO_BROWSER'
#!/usr/bin/env bash
set -eu
export ELECTRON_OZONE_PLATFORM_HINT=x11
export OZONE_PLATFORM=x11
export GDK_BACKEND=x11
export XCURSOR_THEME="${XCURSOR_THEME:-Bibata-Modern-Classic}"
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"
export XCURSOR_PATH="${XCURSOR_PATH:-/run/host/usr/share/icons:/run/host${HOME}/.local/share/icons}"
exec "$(dirname "$0")/neocolab-box" run Neo-Browser.AppImage "$@"
NEO_BROWSER

  chmod +x "${BIN_DIR}/neocolab-box" "${BIN_DIR}/neo-browser"

  # Ensure ~/.local/bin is on PATH for this and future shells.
  case ":${PATH}:" in
    *":${BIN_DIR}:"*) ;;
    *)
      export PATH="${BIN_DIR}:${PATH}"
      if [ -f "${HOME}/.zshrc" ] && ! grep -q '\.local/bin' "${HOME}/.zshrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
      fi
      if [ -f "${HOME}/.bashrc" ] && ! grep -q '\.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
      fi
      ;;
  esac
}

write_desktop() {
  echo "[3/5] Installing desktop entry..."
  mkdir -p "$APPS_DIR" "$ICONS_DIR"

  # Prefer an icon from the box Applications dir if present later; fallback generic.
  local icon="web-browser"
  if [ -f "${HOME}/.local/share/icons/neo-browser.png" ]; then
    icon="${HOME}/.local/share/icons/neo-browser.png"
  fi

  cat > "${APPS_DIR}/neo-browser.desktop" <<EOF
[Desktop Entry]
Name=Neo Browser
Comment=Secure browser for online examinations (NeoColab)
Exec=${BIN_DIR}/neo-browser %U
Icon=${icon}
Type=Application
Categories=Utility;Education;Network;
Terminal=false
StartupNotify=false
StartupWMClass=neo-browser
MimeType=x-scheme-handler/neoexam;
EOF

  update-desktop-database "$APPS_DIR" 2>/dev/null || true
}

install_appimage() {
  local appimage=$1
  echo "[4/5] Creating box and installing AppImage (first enter can take several minutes)..."
  echo "      This is not stuck — Ubuntu base packages are being installed silently."

  export DBX_CONTAINER_MANAGER="${DBX_CONTAINER_MANAGER:-podman}"
  "${BIN_DIR}/neocolab-box" install "$appimage"
}

finish() {
  echo "[5/5] Done."
  echo
  echo "Launch Neo Browser from your app menu, or run:"
  echo "  neo-browser"
  echo
  echo "Later upgrades:"
  echo "  neocolab-box upgrade /path/to/Neo-Browser-x.y.z.AppImage"
  echo
  echo "If the menu does not show it yet, log out/in or run:"
  echo "  update-desktop-database ${APPS_DIR}"
}

main() {
  if [ "$#" -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "usage: $0 /path/to/Neo-Browser-x.y.z.AppImage" >&2
    exit 2
  fi

  local appimage
  appimage=$(readlink -f "$1") || die "cannot resolve path: $1"
  [ -f "$appimage" ] || die "no such file: $appimage"
  case "$appimage" in
    *.AppImage | *.appimage) ;;
    *) die "expected an .AppImage file, got: $appimage" ;;
  esac

  echo "NeoColab installer (Arch + Distrobox)"
  echo "AppImage: $appimage"
  echo

  install_host_packages
  write_helpers
  write_desktop
  install_appimage "$appimage"
  finish
}

main "$@"
