#!/usr/bin/env bash
# Script to download asset file from tag release using GitHub API v3.
# Specify ASSET_OVERRIDE=1 to download even when the previous file exist.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
set -e
type curl grep sed tr >/dev/null
xargs=$(command -v gxargs || command -v xargs)

# Validate settings.
[ -z "$GITHUB_API_TOKEN" ] && [ -f ~/.secrets ] && source ~/.secrets
[ -n "$GITHUB_API_TOKEN" ] || { echo "Error: Please define GITHUB_API_TOKEN variable." >&2; exit 1; }
[ $# -lt 4 ] && { echo "Usage: $0 [owner] [repo] [tag] [name] [dest]"; exit 1; }
[ -n "$OPT_TRACE" ] && set -x
read owner repo tag name dest <<<$@

# Define variables.
BT_DEST=${dest:-.}
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_TAGS="$GH_REPO/releases/tags/$tag"
AUTH="Authorization: token $GITHUB_API_TOKEN"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

# Validate token.
echo "Validating token..." >&2
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags.
response=$(curl -sH "$AUTH" $GH_TAGS)
# Get ID of the asset based on given name.
echo "Fetching asset ID..." >&2
id=$(echo "$response" | grep -C3 "name.:.\+$name" | grep -w id | head -n1)
echo $id
eval $(echo $id | tr : = | tr -cd '[[:alnum:]]=')
[ -n "$id" ] || { echo "Error: Failed to get asset id, response: $response" | awk 'length($0)<100' >&2; exit 1; }
GH_ASSET="$GH_REPO/releases/assets/$id"

# Changing the working folder. Create if does not exist.
[ ! -d "$BT_DEST" ] && mkdir -vp "$BT_DEST"
cd "$BT_DEST"

# Download asset file.
echo "Downloading asset..." >&2
[ -n "$ASSET_OVERRIDE" ] && find "$BT_DEST" -type f -name '*.ex?' -execdir mv -vf {} {}.bak ';'
curl $CURL_ARGS -H 'Accept: application/octet-stream' "$GH_ASSET?access_token=$GITHUB_API_TOKEN"
echo "${BASH_SOURCE[0]} done." >&2
