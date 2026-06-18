#!/bin/sh

git_push_force() {
    if result=$(git push "$1" main --force 2>&1); then
        echo "✓ $1 push successful"
    else
        echo "✗ $1 push failed: $result"
    fi
} 

