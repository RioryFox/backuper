#!/usr/bin/env bash


while IFS= read -r disk; do
        device="/dev/$disk"
        model=$(lsblk -dn -o NAME "$device")
        mount_point=$(lsblk -dn -o MOUNTPOINT "$device")
        size=$(lsblk -dn -o SIZE "$device")
        if model[0:${#NAME_TYPE}] == "$NAME_TYPE" && check_path "$mount_point/$FLAG_POINT"; then
                echo "disk: $disk"
        fi
done < <(lsblk -dn -o NAME)