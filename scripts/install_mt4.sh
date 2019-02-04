#!/usr/bin/env bash
# Script to install MT4 platform using winetricks.
[ "$OPT_NOERR" ] || set -e
[ "$OPT_TRACE" ] && set -x
CWD="$(cd -P -- "$(dirname -- "$0")" 2>/dev/null && pwd -P || pwd -P)"
WURL=${WURL:-https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks}

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

echo "Installing winhttp..." >&2
sh -s winhttp < <(wget -qO- $WURL)

echo "Installing platform..." >&2
sh -s "$CWD"/install_mt4.verb < <(wget -qO- $WURL)

echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
