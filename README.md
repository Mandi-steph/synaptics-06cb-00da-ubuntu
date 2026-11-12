# Lenovo ThinkPad E14 / E15 fingerprint reader on Linux (Ubuntu) — Synaptics 06cb:00da driver

**Fingerprint sensor not working on your Lenovo ThinkPad E14 Gen 1 / E15 under Linux?** This makes the **Synaptics `06cb:00da`** fingerprint reader work on Ubuntu: enroll your finger, unlock the screen and use `sudo` with your fingerprint, just like on Windows.

> 🇫🇷 **Lecteur d'empreinte du Lenovo ThinkPad E14 Gen 1 qui ne marche pas sous Linux / Ubuntu ?** Ce pilote le fait fonctionner. Voir [la section en français](#en-français) plus bas.

**Tested on:** ThinkPad E14 Gen 1 (20RA), Ubuntu 26.04 LTS, GNOME 50, libfprint `1:1.95.1+tod1-0ubuntu2`, fprintd `1.94.5`.
Enroll, verify, `sudo` and the GNOME lock screen work through the standard fprintd stack.

## Is this for me?

You have this sensor if this command prints a line:

```bash
lsusb | grep -i 06cb:00da
# Bus 001 Device 003: ID 06cb:00da Synaptics, Inc.
```

Typical symptoms without this driver:

- `fprintd-enroll` / `fprintd-list` → **`No devices available`**
- GNOME Settings shows no "Fingerprint Login" option
- libfprint lists `06cb:00da` as an *unsupported device*

Laptops reported with this sensor: **ThinkPad E14 Gen 1 (20RA)** — tested here, **ThinkPad E15 Gen 1 (20RD)**, **ThinkPad E15 Gen 2**. Other ThinkPad E14 / E15 models (Gen 1 / Gen 2) covered by Lenovo's Windows driver package DS541506 may have it too — check with `lsusb`.

## How it works

It uses [synaTudor](https://github.com/Popax21/synaTudor), which runs Lenovo's official Windows driver inside a sandboxed Win32 shim and exposes it to the normal Linux fingerprint stack (libfprint-tod / fprintd), plus the patches needed for this sensor.

## What this adds on top of synaTudor (`31dfdb0`)

`patches/00da-ubuntu.patch` combines:

- the 06cb:00da support from [francescomcrtl/synaptics-00da-linux](https://github.com/francescomcrtl/synaptics-00da-linux) (udev rule, device ID, `user32.c` stubs, registry/module/WDF fixes);
- the fixes from [issue #4](https://github.com/francescomcrtl/synaptics-00da-linux/issues/4) of that project: use the **v108** Lenovo driver `r16sf12w.exe` (the one whose INF lists `PID_00DA`, SHA‑256 checked) and a `CallNtPowerInformation` stub;
- the two shutdown use‑after‑free fixes from [synaTudor#65](https://github.com/Popax21/synaTudor/issues/65), also applied to `FreeLibraryAndExitThread`.

Nothing here is new reverse engineering — all credit goes to Popax21, francescomcrtl and xxmarkxx8. This repo just packages the combination that works on Ubuntu.

## Install

```bash
# 0. Get this repository
git clone https://github.com/Mandi-steph/synaptics-06cb-00da-ubuntu.git
cd synaptics-06cb-00da-ubuntu

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

To add another finger: `fprintd-enroll -f left-index-finger` (see `man fprintd-enroll` for finger names).

Your password keeps working as a fallback. Do **not** copy the Arch-specific PAM files from other guides onto Ubuntu — `pam-auth-update` is the safe way.

## Uninstall

```bash
sudo ./uninstall.sh
```

## Notes

- If Lenovo blocks the scripted download, get `r16sf12w.exe` from Lenovo support page **DS541506** in a browser and drop it into `work/` before running `./build.sh`.
- `udev.pc` missing on your system (no `systemd-dev`)? `build.sh` provides a minimal one automatically.
- Use at your own risk, same as synaTudor: it runs a proprietary Windows driver (sandboxed) and pairs with the sensor.

## En français

**Pilote du lecteur d'empreinte digitale pour Lenovo ThinkPad E14 Gen 1 (et E15) sous Linux / Ubuntu.**

Sous Linux, le lecteur d'empreinte Synaptics `06cb:00da` de ces ordinateurs n'est pas reconnu (`fprintd` affiche « No devices available », aucune option « Connexion par empreinte » dans les Paramètres). Ce dépôt le fait fonctionner : enregistrement du doigt, déverrouillage de l'écran et `sudo` par empreinte. Le mot de passe reste toujours accepté.

Vérifier que vous avez ce lecteur : `lsusb | grep -i 06cb:00da`

Installation (Ubuntu) :

```bash
git clone https://github.com/Mandi-steph/synaptics-06cb-00da-ubuntu.git
cd synaptics-06cb-00da-ubuntu
sudo apt install build-essential meson ninja-build pkgconf innoextract wget \
  libfprint-2-tod-dev libusb-1.0-0-dev libssl-dev libglib2.0-dev libgusb-dev \
  libjson-glib-dev libcap-dev libseccomp-dev libdbus-1-dev libudev-dev
./build.sh                               # compilation (sans sudo)
sudo ./install.sh                        # installation
fprintd-enroll                           # enregistrer un doigt
sudo pam-auth-update --enable fprintd    # activer pour la connexion et sudo
```

Désinstaller : `sudo ./uninstall.sh`

Testé sur ThinkPad E14 Gen 1 (20RA), Ubuntu 26.04 LTS.

## License

LGPL‑2.1, same as synaTudor (see `LICENSE`).
