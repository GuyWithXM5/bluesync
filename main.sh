#!/usr/bin/bash

usage() {
    echo "add it later!!!!!!!!!"
}

while getopts "hd:" opt; do 
    case $opt in
        h) 
            usage
            exit 0
            ;;
        d) 
            DISK="$OPTARG"
            ;;

    esac
done

if (( $EUID!=0 )); then
    echo "Need root privileges."
    exit 1
fi
echo -e "running in root privileges...\n"

if [ -z "$DISK" ]; then
    echo "missing -d <arg>"
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

outputbtdriver=$(echo -e "cd $cs\Services\BTHPORT\Parameters\Keys\nls\nq" | chntpw -e ~/SYSTEM.copy)
btdriver=$(echo "$outputbtdriver" | awk 'NR==12 {print $NF}' | tr -d '<>')
echo -e "accessing $cs\Services\BTHPORT\Parameters\Keys\\$btdriver as bluetooth controller\n"



# controlset_num=$((16#controlset_hex))
# echo "$controlset_num"

echo "\n\n"
exit 1

