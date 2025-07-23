#!/usr/bin/bash

usage() {
    echo "add it later!!!!!!!!!"
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

cp /mnt/windows/Windows/System32/config/SYSTEM ~/SYSTEM.copy
echo -e "\n/mnt/windows/Windows/System32/config/SYSTEM registry copy created at ~/SYSTEM.copy\n"

outputCS=$(echo -e "cd Select\nls\nq" | chntpw -e ~/SYSTEM.copy)
controlset_num=$(echo "$outputCS" | grep '<Current>' | awk '{print $(NF-1)}')

printf -v cs "ControlSet%03d" "$controlset_num"
echo -e "accessing $cs\n"

btdriverlinux=$(ls /var/lib/bluetooth/)
btdriverwindows=$(normalize_mac "$btdriverlinux")

echo -e "accessing $cs\Services\BTHPORT\Parameters\Keys\\$btdriverwindows as bluetooth controller\n"

targetdevicewindows=$(normalize_mac "$TARGETDEVICE")
outputhex=$(echo -e "cd $cs\Services\BTHPORT\Parameters\Keys\\$btdriverwindows\nhex $targetdevicewindows\nq" | chntpw -e ~/SYSTEM.copy)
hex=$(extract_hex_bytes "$outputhex" )
echo -e "hex key for target device: $hex\n"

change_linkkey "/var/lib/bluetooth/$btdriverlinux/$TARGETDEVICE/info" "$hex"
echo  -e "updated the Key in the info file of Target Device $TARGETDEVICE\n"
echo -e "PLEASE RESTART BLUETOOTH SERVICE TO CONNECT THE DEVICE, USE THE BELOW COMMAND TO RESTART...\nsystemctl restart bluetooth"

exit 0

