#!/bin/sh

git_push() {
    local path="$1"
    local ignor_errors=$2

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
    else
        echo "✗ push failed: $path"
    fi
} 

git_commit() {
    local path=$1
    check_path "$path"
    git -C "$path" add .
    git -C "$path" commit -m "Backup push for all git and backup disks by $(date +%Y-%m-d%) by project backuper https://github.com/RioryFox/backuper"
}

git_backup(){
    local path="$1"
    local git_commit="$2"
    check_path "$path"

    if [[ "$2"=="y" ]]; then
        git_commit "$1"
    fi
    git_push "$1"
}