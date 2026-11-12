#!/bin/bash
# Remove the driver completely (run with sudo).
[ "$(id -u)" -eq 0 ] || { echo "Run with: sudo $0"; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pam-auth-update --disable fprintd
systemctl disable --now tudor-host-launcher 2>/dev/null
ninja -C "$HERE/work/synaTudor/build" uninstall
rm -rf /var/lib/tudor
udevadm control --reload
systemctl daemon-reload
systemctl restart fprintd 2>/dev/null
echo "Driver removed; password-only login restored."
