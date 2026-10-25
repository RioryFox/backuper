#!/usr/bin/env bash
source ./lib/backup.sh

readonly FLAG_POINT='.fbi_backup_disk'
readonly NAME_TYPE='FBL_BK'
readonly ORIGIN_DISK_PATH='/'

while IFS= read -r disk; do
        device="/dev/$disk"
        mount_point=$(lsblk -o MOUNTPOINTS "$device")
        uuid=$(lsblk -dn -o UUID "$device")

        echo "диск: $disk"

        while IFS= read -r partition; do
                echo " раздел: $partition"
                check_path "$mount_point/$partition/$FLAG_POINT"
        done < <(lsblk -ln -o NAME,TYPE "$device" | awk '$2 == "part" {print $1}')
done < <(lsblk -dn -o NAME)