#!/usr/bin/bash

usage() {
    echo "Usage: sudo $0 -d <windows_disk> -m <target_mac>"
    echo ""
    echo "Description:"
    echo "  This script extracts the Bluetooth pairing key (Link Key) for a specific"
    echo "  Bluetooth device from a mounted Windows SYSTEM registry hive and injects it"
    echo "  into the corresponding Linux Bluetooth device info file."
    echo ""
    echo "Options:"
    echo "  -d <windows_disk>    Specify the disk partition containing the Windows OS (e.g., sda3)"
    echo "  -m <target_mac>      Target Bluetooth device MAC address (e.g., 80:99:E7:08:0C:92)"
    echo "  -h                   Show this help message and exit"
    echo ""
    echo "Example:"
    echo "  sudo $0 -d sda3 -m 80:99:E7:08:0C:92"
    echo ""
    echo "Note:"
    echo "  - This script must be run as root (sudo)"
    echo "  - After completion, restart Bluetooth service using:"
    echo "      systemctl restart bluetooth"
}


normalize_mac() {
    local input="$1"
    echo "$input" | tr -d ':' | tr 'A-F' 'a-f'
}

extract_hex_bytes() {
    local input="$1"
    echo "$input" | grep '^:00000' | cut -c9-56 | tr -d ' '
}

change_linkkey() {
    local file="$1"
    local new_key="$2"
    sed -i "/^\[LinkKey\]/,/^\[/{s/^Key=.*/Key=$new_key/}" "$file"
}

while getopts "hd:m:" opt; do 
    case $opt in
        h) 
            usage
            exit 0
            ;;
        d) 
            DISK="$OPTARG"
            ;;
        m)
            TARGETDEVICE="$OPTARG"
            ;;
    esac
done

if (( $EUID!=0 )); then
    echo "Need root privileges."
    exit 1
fi
echo -e "running in root privileges...\n"

if [ -z "$DISK" ] || [ -z "$TARGETDEVICE" ]; then
    echo "missing -d <arg> and -m <arg>"
    usage
    exit 1
fi
mkdir -p /mnt/windows
echo -e "made mount point at /mnt/windows\n"

mount -t ntfs-3g /dev/$DISK /mnt/windows
# Validate if mount was successful
if ! mountpoint -q /mnt/windows; then
    echo "Failed to mount /dev/$DISK. Check if it's the correct partition and accessible."
    exit 1
fi

cp /mnt/windows/Windows/System32/config/SYSTEM ~/SYSTEM.copy
# Validate SYSTEM file copy
if [ ! -f ~/SYSTEM.copy ]; then
    echo "Failed to copy SYSTEM registry file."
    exit 1
fi
echo -e "\n/mnt/windows/Windows/System32/config/SYSTEM registry copy created at ~/SYSTEM.copy\n"

outputCS=$(echo -e "cd Select\nls\nq" | chntpw -e ~/SYSTEM.copy)
controlset_num=$(echo "$outputCS" | grep '<Current>' | awk '{print $(NF-1)}')
# Validate ControlSet detection
if [ -z "$controlset_num" ]; then
    echo "Could not determine ControlSet from SYSTEM hive."
    exit 1
fi
printf -v cs "ControlSet%03d" "$controlset_num"
echo -e "accessing $cs\n"

btdriverlinux=$(ls /var/lib/bluetooth/)
btdriverwindows=$(normalize_mac "$btdriverlinux")

echo -e "accessing $cs\Services\BTHPORT\Parameters\Keys\\$btdriverwindows as bluetooth controller\n"

targetdevicewindows=$(normalize_mac "$TARGETDEVICE")
outputhex=$(echo -e "cd $cs\Services\BTHPORT\Parameters\Keys\\$btdriverwindows\nhex $targetdevicewindows\nq" | chntpw -e ~/SYSTEM.copy)
hex=$(extract_hex_bytes "$outputhex" )
# Validate target hex key
if [ -z "$hex" ]; then
    echo "Could not extract hex key. Is the target device already paired in Windows?"
    exit 1
fi
echo -e "hex key for target device: $hex\n"

# Validate destination info file
if [ ! -f "/var/lib/bluetooth/$btdriverlinux/$TARGETDEVICE/info" ]; then
    echo "Bluetooth info file not found: /var/lib/bluetooth/$btdriverlinux/$TARGETDEVICE/info"
    exit 1
fi
change_linkkey "/var/lib/bluetooth/$btdriverlinux/$TARGETDEVICE/info" "$hex"
echo  -e "updated the Key in the info file of Target Device $TARGETDEVICE\n"
echo -e "PLEASE RESTART BLUETOOTH SERVICE TO CONNECT THE DEVICE, USE THE BELOW COMMAND TO RESTART...\nsystemctl restart bluetooth"

# Unmounting after completion
umount /mnt/windows
rmdir /mnt/windows

exit 0

