#!/usr/bin/env bash
# Script to clone a repo.
# Usage: clone_repo.sh repo_url
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
REPO=$1
DIR="$(basename "$REPO")"
type git 2> /dev/null
[ ! "$REPO" ] && { echo "Usage: $0 (git@repo/url)"; exit 1; }

[ ! -d "$DIR" ] && git clone "$REPO";
cd "$DIR" && git status