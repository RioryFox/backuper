#!/usr/bin/env bash

check_path(){
    local path="$1"
    if [[ ! -d "$path" ]]; then
        echo "Не найден каталог: $path"
        return 1;
    fi 
    return 0
}

ignor_errors(){
    local path=$1
    local ignor_error=$2

    if [[ "$ignor_error" == "y" ]]; then
            echo "Продолжение сохранения резервных данных не смотря на неудавшуюся операцию..."
            return 0
    fi
    return 1
}

disk_backup(){
    local path="$1"
    local destination="$2"
    check_path $path || return 1
    check_path $destination || return 1
    rsync -azq --checksum --delete "$path/" "$destination/" --exclude='containers/storage/overlay*' --exclude='*.sock' --exclude='*.pid' 2>/dev/null
    return 0
}