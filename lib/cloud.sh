#!/usr/bin/env bash

cloud_backup(){
        local path="$1"
        local destination="$2"
        local ignor_error="$3"

        if ! check_path "$path"; then
                echo "$path не существует, невозможно создать резервную копию этого пути в облачные структуры..."
                ignor_errors "$path" "$ignor_error"
        else
                rclone copy "$path" "$destination" --progress || return 1
                return 0
        fi
}