#!/usr/bin/env bash
# Script to push change to the repo.
# Usage: push_repo.sh repo_url branch message
set -e
[ "$TRACE" ] && set -x
type git 2> /dev/null
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
read repo branch message <<<$@
[ ! "$repo" ] && { echo "Usage: $0 (git@repo/url) (branch) (message) (author)"; exit 1; }
dir="$(basename "$repo")"
message="${message:-$(echo "$branch")}"

[ -d "$dir" ] && cd "$dir"
git status || pwd

# Checkout or create the given branch.
[ "$branch" ] && git checkout -mB "$branch"

# Pull the changes from upstream branch or ignore.
git pull -r -Xours origin "$branch" || true

# Add all files and display the changes.
git add -vA && git status && git diff

# Commit and push the changes.
git commit -am "$message" "$GIT_ARGS" && git push "$repo" "$branch" -vf || true
