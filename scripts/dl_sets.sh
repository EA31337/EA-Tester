#!/bin/bash 
DEST=$(find /opt -name tester)
[ -z "$@" ] && { echo "Usage: $0 (git_repo)"; exit 1; }
git clone $@ "$DEST/sets"

# Add files to the git repository.
git --git-dir=/opt/.git add -A
git --git-dir=/opt/.git commit -m"$0: Downloaded set files." -a

echo "$0 done."
