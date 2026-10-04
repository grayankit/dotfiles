#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
	exec sudo "$0" "$@"
fi

cat >/etc/udev/hwdb.d/90-msi-cyborg-keyboard.hwdb <<'EOF'
evdev:atkbd:dmi:bvn*:bvr*:bd*:svnMicro-Star*:pnCyborg15*:*
 KEYBOARD_KEY_e057=bluetooth
EOF

systemd-hwdb update
setkeycodes e057 237
udevadm trigger --subsystem-match=input
