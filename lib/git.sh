#!/usr/bin/env bash

git_push() {
    local path="$1"
    local ignor_error=$2

    check_path "$path"

    if [[ ! -d "$path/.git" && ! -f "$path/.git" ]]; then
        echo "Каталог $path не является коренм git репозитория!"
        return 1;
    fi 

    echo "Производится отправка резервной копии git репозитория $path"

    #git add .
    #git commit -m "Backup push for all git and backup disks by $(date +%Y-%m-d%)"
    if git -C "$path" push; then
        echo "✓ $path push successful"
        return 0
    else
        echo "✗ push failed: $path"
        ignor_errors "$path" "$ignor_error"
    fi
} 

git_commit() {
    local path=$1
    check_path "$path"
    git -C "$path" add . || return 1
    git -C "$path" commit -m "Backup push for all git and backup disks by $(date +%Y-%m-d%) by project backuper https://github.com/RioryFox/backuper" || return 1
}

git_backup(){
    local path="$1"
    local git_commit="$2"
    local ignor_error="$3"
    check_path "$path"

    if [[ "$git_commit" == "y" ]]; then
        git_commit "$path"  || ignor_errors "$path" "$ignor_error"
    fi
    git_push "path"
}