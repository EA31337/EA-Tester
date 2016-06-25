#!/usr/bin/env bash
# Script to push change to the repo.
# Usage: push_repo.sh repo_url branch message
set -e
type git 2> /dev/null
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
read repo branch message <<<$@
[ ! "$repo" ] && { echo "Usage: $0 (git@repo/url) (branch) (message) (author)"; exit 1; }
dir="$(basename "$repo")"
message="${message:-$(echo "$branch")}"

[ -d "$dir" ] && cd "$dir"
[ "$branch" ] && git checkout -mB "$branch"
git status && git diff
git commit -am "$message" "$GIT_ARGS" && git push "$repo" "$branch" -vf || true
