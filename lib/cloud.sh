#!/bin/sh

cloud_backup(){
        local path="$1"
        local destination="$2"

        if [[ ! -d "$path" ]]; then
                echo "$path не существует, невозможно создать резервную копию этого пути в облачные структуры..."
        fi
}