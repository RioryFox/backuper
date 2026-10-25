#!/bin/sh

git_push_force() {
    git add .
    git commit -m "Backup push for all git and backup disks by $(date +%Y-%m-d%)"
    if result=$(git push 2>&1); then
        echo "✓ push successful"
    else
        echo "✗ push failed: $result"
    fi
} 

