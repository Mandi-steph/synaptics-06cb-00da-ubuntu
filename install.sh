#!/bin/bash
# Install the built driver (run with sudo after ./build.sh).
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with: sudo $0"; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD="$HERE/work/synaTudor/build"
[ -d "$BUILD" ] || { echo "Run ./build.sh first (as a normal user)."; exit 1; }

ninja -C "$BUILD" install
udevadm control --reload
udevadm trigger --subsystem-match=usb --attr-match=idVendor=06cb
systemctl daemon-reload
systemctl enable --now tudor-host-launcher
systemctl restart fprintd 2>/dev/null || true

echo
echo "Installed. Next steps (as your user):"
echo "  fprintd-enroll        # enroll a finger"
echo "  fprintd-verify        # check it"
echo "  sudo pam-auth-update --enable fprintd   # use it for login/sudo (password still works)"
