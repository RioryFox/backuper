#!/usr/bin/env bash

readonly FLAG_POINT='.fbi_backup_disk'
readonly NAME_TYPE='FBL_BK'
readonly ORIGIN_DISK_PATH='/'

while IFS= read -r disk; do
        device="/dev/$disk"
        mount_point=$(lsblk -dn -o MOUNTPOINT "$device")
        uuid=$(lsblk -dn -o UUID "$device")

        while read -r partition; do

                if [[ "$partition" == "$NAME_TYPE"* ]]; then
                        echo "найден раздел для резервных копий на диске: $disk\n $uuid \n $mountpoint"
                else
                        echo "$disk не подошел, $partition"
                fi
        done
done < <(lsblk -dn -o NAME)