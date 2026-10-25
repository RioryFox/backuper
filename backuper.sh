#!/usr/bin/env bash

readonly FLAG_POINT='.fbi_backup_disk'
readonly NAME_TYPE='FBL_BK'
readonly ORIGIN_DISK_PATH='/'

while IFS= read -r disk; do
        device="/dev/$disk"
        mount_point=$(lsblk -dn -o MOUNTPOINT "$device")
        uuid=$(lsblk -dn -o UUID "$device")

        echo "диск: $disk"

        while IFS= read -r partition; do
                echo " раздел: $partition"
        done 
done < <(lsblk -dn -o NAME)