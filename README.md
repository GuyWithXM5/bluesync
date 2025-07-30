# 🌀 bluesync

`bluesync` is a simple Shell utility that syncs Bluetooth Link Keys between a Windows and Linux dual-boot setup. It extracts paired device keys from the Windows registry and applies them in your Linux environment, allowing seamless Bluetooth pairing without re-authentication.

---

## Features

* Extract Bluetooth Link Keys from Windows NTFS partitions
* Apply keys to Linux for seamless dual-boot pairing
* Clean, lightweight Shell implementation
* Supports MAC address normalization

---

## Requirements

Install the following dependencies:

* [`sh`](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html) — standard POSIX shell
* [`ntfs-3g`](https://wiki.archlinux.org/title/NTFS-3G) — to mount Windows drives
* [`chntpw`](https://wiki.archlinux.org/title/Chntpw) — to read Windows registry hives
* [`bluez`](https://archlinux.org/packages/extra/x86_64/bluez/) *(optional)* — for Bluetooth support and restarting the service

Install with:

```sh
sudo pacman -S ntfs-3g chntpw bluez
```

---

## Installation

### 🔹 Method 1: From AUR repository

```sh
yay -S bluesync
```

### 🔹 Method 2: Using makepkg from source

```sh
git clone https://github.com/anuvindap/bluesync.git
cd bluesync
makepkg -si
```

### 🔹 Method 3: Manual install

```sh
git clone https://github.com/anuvindap/bluesync.git
cd bluesync
sudo install -Dm755 bluesync /usr/bin/bluesync
```

### 🔹 Method 4: Download using cURL

```sh
curl -o bluesync https://bluesync.guywithxm5.in/bluesync
chmod +x bluesync
sudo install -Dm755 bluesync /usr/bin/bluesync
```

---

## Usage

Run the tool with:

```sh
sudo bluesync -d <windows-disk-name> -m <bluetooth-mac-address>
```

**Example:**

```sh
sudo bluesync -d sda3 -m 80:99:E7:08:0C:92
```

| Flag | Description                                                                           |
| ---- | ------------------------------------------------------------------------------------- |
| `-d` | Your Windows drive name (e.g., sda3, nvme0n1p4)                                       |
| `-m` | MAC address of the Bluetooth device you want to sync (format: XX\:XX\:XX\:XX\:XX\:XX) |

The script will:

* Mount the specified Windows partition
* Extract Bluetooth link keys from registry
* Apply them to your Linux Bluetooth config
* Optionally restart the Bluetooth service

---

## Uninstallation

**If installed manually:**

```sh
sudo rm /usr/bin/bluesync
```

**If installed via makepkg, use:**

```sh
sudo pacman -R bluesync
```

---

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3).

---

## Contributing & Feedback

Found a bug or want to suggest a feature? Open an issue or create a pull request. Contributions are always welcome!

---

## Credits

Created with ❤️ by **Anuvind A P**
