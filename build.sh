#!/bin/bash
# Build synaTudor with 06cb:00da support (run as a normal user, NOT root).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$HERE/work"
TUDOR_COMMIT="31dfdb0"
DRIVER_URL="https://download.lenovo.com/pccbbs/mobiles/r16sf12w.exe"
DRIVER_SHA256="77a2ae51978038462b6891551d45bd237e27aeb8b56b656a9a17f7b92399c653"

[ "$(id -u)" -ne 0 ] || { echo "Run this as a normal user (only install.sh needs sudo)."; exit 1; }

for cmd in git meson ninja pkg-config innoextract wget sha256sum gcc; do
    command -v "$cmd" >/dev/null || { echo "Missing '$cmd'. On Ubuntu/Debian run:"; \
        echo "  sudo apt install build-essential meson ninja-build pkgconf innoextract wget libfprint-2-tod-dev libusb-1.0-0-dev libssl-dev libglib2.0-dev libgusb-dev libjson-glib-dev libcap-dev libseccomp-dev libdbus-1-dev libudev-dev"; exit 1; }
done

mkdir -p "$WORK"
cd "$WORK"

echo "[1/4] Fetching synaTudor @ $TUDOR_COMMIT"
if [ ! -d synaTudor/.git ]; then
    git clone -q https://github.com/Popax21/synaTudor.git
fi
git -C synaTudor checkout -q -f "$TUDOR_COMMIT"
git -C synaTudor clean -fdq

echo "[2/4] Applying 06cb:00da patch"
git -C synaTudor apply "$HERE/patches/00da-ubuntu.patch"

echo "[3/4] Downloading Lenovo driver r16sf12w.exe (v108, lists 06CB:00DA)"
if [ ! -f r16sf12w.exe ] || ! echo "$DRIVER_SHA256  r16sf12w.exe" | sha256sum -c --status; then
    wget -q --show-progress "$DRIVER_URL" -O r16sf12w.exe || {
        echo "Download failed. Get r16sf12w.exe from Lenovo support (DS541506) in a browser and put it in: $WORK"; exit 1; }
fi
echo "$DRIVER_SHA256  r16sf12w.exe" | sha256sum -c

echo "[4/4] Building"
# Some Ubuntu installs lack udev.pc (package systemd-dev); provide a minimal one if needed.
if ! pkg-config --exists udev; then
    mkdir -p "$WORK/pkgconfig"
    printf 'udevdir=/usr/lib/udev\nName: udev\nDescription: udev\nVersion: 255\n' > "$WORK/pkgconfig/udev.pc"
    export PKG_CONFIG_PATH="$WORK/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
fi
rm -rf synaTudor/build
meson setup synaTudor/build synaTudor -Dprefix=/usr >/dev/null
ninja -C synaTudor/build

echo
echo "Build OK. Optional test (no system change):"
echo "  sudo $WORK/synaTudor/build/cli/tudor_cli /tmp/tudor-test.db -P0x00da"
echo "Then install with:  sudo ./install.sh"
