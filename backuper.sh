#!/usr/bin/env bash

for disk in "$(lsblk -o NAME,SIZE,MODEL,FSTYPE,LABEL,UUID,MOUNTPOINTS)"; do
        echo "disk: $disk"
done