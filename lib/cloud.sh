#!/usr/bin/env bash

cloud_backup(){
        local path="$1"
        local destination="$2"

        if [[ check_path "$path" ]]; then
                echo "$path не существует, невозможно создать резервную копию этого пути в облачные структуры..."
                ignor_errors "$3"
        fi
        rclone copy "$path" "$destination" --progress
        return 1
}