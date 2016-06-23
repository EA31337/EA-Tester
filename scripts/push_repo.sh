#!/usr/bin/env bash
# Script to push change to the repo.
# Usage: push_repo.sh repo_url branch message
set -e
type git 2> /dev/null
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
read repo branch message args <<<$@
[ ! "$repo" ] && { echo "Usage: $0 (git@repo/url) (branch) (message)"; exit 1; }
dir="$(basename "$repo")"
message=${message:-$(echo Test results for $branch)}

[ -d "$dir" ] && cd "$dir"
[ "$branch" ] && git checkout -fB "$branch"
git status && git diff
git commit -am "$message" && git push "$repo" "$branch" -vf || true
