#!/usr/bin/env bash
# Script to install MT4 platform using winetricks.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
CWD="$( (cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" 2> /dev/null && pwd -P) || pwd -P)"
type winetricks > /dev/null

# Load variables.
export WINETRICKS_DOWNLOADER_RETRIES=${WINETRICKS_DOWNLOADER_RETRIES:-10}
export WINETRICKS_DOWNLOADER=curl

# Initializing
echo "Initializing..." >&2
curl -s ifconfig.me/all.json

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

# Activates display.
echo "Configuring display..." >&2
set_display

# Updates Wine configuration.
echo "Updating configuration..." >&2
wineboot -u

echo "Installing winhttp..." >&2
winetricks -q winhttp

echo "Installing .NET..." >&2
winetricks -q dotnet472

echo "Installing platform..." >&2
winetricks -q -v mt4

echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
