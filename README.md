# Synaptics 06cb:00da fingerprint reader on Ubuntu (ThinkPad E14 / E15)

Working fingerprint support for the **Synaptics `06cb:00da`** sensor found in the ThinkPad E14 / E15 (Gen 1 and Gen 2), using [synaTudor](https://github.com/Popax21/synaTudor) — which runs Lenovo's Windows driver inside a sandboxed Win32 shim — plus the patches needed for this sensor.

**Tested on:** ThinkPad E14 Gen 1 (20RA), Ubuntu 26.04 LTS, GNOME 50, libfprint `1:1.95.1+tod1-0ubuntu2`, fprintd `1.94.5`.
Enroll, verify, `sudo` and the GNOME lock screen work through the standard fprintd stack.

## What this adds on top of synaTudor (`31dfdb0`)

`patches/00da-ubuntu.patch` combines:

- the 06cb:00da support from [francescomcrtl/synaptics-00da-linux](https://github.com/francescomcrtl/synaptics-00da-linux) (udev rule, device ID, `user32.c` stubs, registry/module/WDF fixes);
- the fixes from [issue #4](https://github.com/francescomcrtl/synaptics-00da-linux/issues/4) of that project: use the **v108** Lenovo driver `r16sf12w.exe` (the one whose INF lists `PID_00DA`, SHA‑256 checked) and a `CallNtPowerInformation` stub;
- the two shutdown use‑after‑free fixes from [synaTudor#65](https://github.com/Popax21/synaTudor/issues/65), also applied to `FreeLibraryAndExitThread`.

Nothing here is new reverse engineering — all credit goes to Popax21, francescomcrtl and xxmarkxx8. This repo just packages the combination that works on Ubuntu.

## Install

```bash
# 1. Build dependencies (Ubuntu / Debian)
sudo apt install build-essential meson ninja-build pkgconf innoextract wget \
  libfprint-2-tod-dev libusb-1.0-0-dev libssl-dev libglib2.0-dev libgusb-dev \
  libjson-glib-dev libcap-dev libseccomp-dev libdbus-1-dev libudev-dev

# 2. Build as your normal user (downloads synaTudor + the Lenovo driver, checks its hash)
./build.sh

# 3. Optional: test the sensor without touching the system
#    (e = enroll, v = verify, s = quit)
sudo ./work/synaTudor/build/cli/tudor_cli /tmp/tudor-test.db -P0x00da

# 4. Install, enroll, enable for login/sudo
sudo ./install.sh
fprintd-enroll
fprintd-verify
sudo pam-auth-update --enable fprintd
```

Your password keeps working as a fallback. Do **not** copy the Arch-specific PAM files from other guides onto Ubuntu — `pam-auth-update` is the safe way.

## Uninstall

```bash
sudo ./uninstall.sh
```

## Notes

- If Lenovo blocks the scripted download, get `r16sf12w.exe` from Lenovo support page **DS541506** in a browser and drop it into `work/` before running `./build.sh`.
- `udev.pc` missing on your system (no `systemd-dev`)? `build.sh` provides a minimal one automatically.
- Use at your own risk, same as synaTudor: it runs a proprietary Windows driver (sandboxed) and pairs with the sensor.

## License

LGPL‑2.1, same as synaTudor (see `LICENSE`).
