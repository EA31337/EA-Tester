#!/usr/bin/env bash
# Script to clone a repo.
# Usage: clone_repo.sh (git@repo/url) (args...)
set -e
type git >/dev/null
CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO=$1
DIR="$(basename "$REPO")"
[ -z "$REPO" ] && { echo "Usage: $0 (git@repo/url) (args)"; exit 1; }
[ ! -d "$DIR" ] && git clone "$@" -q -b master --recursive --single-branch --depth 1
