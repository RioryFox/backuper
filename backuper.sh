#!/usr/bin/env bash
source ./lib/backup.sh

readonly FLAG_POINT='.fbi_backup_disk'
readonly NAME_TYPE='FBL_DK'
readonly ORIGIN_DISK_PATH='/'

while IFS= read -r disk; do
        device="/dev/$disk"
        uuid=$(lsblk -dno UUID "$device")

        while IFS= read -r partition; do

                mount_point=$(lsblk -dno MOUNTPOINT "$partition")
                label=$(lsblk -dno LABEL "$partition")
                if  [[ "$label" == "$NAME_TYPE"* ]]; then
                        if check_file "$mount_point/$FLAG_POINT"; then
                                echo "диск: $disk"
                                echo "раздел: $partition"
                        fi
                        
                fi
        done < <(lsblk -lnpo NAME,TYPE "$device" | awk '$2 == "part" {print $1}')
done < <(lsblk -dno NAME)