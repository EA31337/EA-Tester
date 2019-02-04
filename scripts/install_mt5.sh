#!/usr/bin/env bash
# Script to install MT5 platform using winetricks.
[ "$OPT_NOERR" ] || set -e
[ "$OPT_TRACE" ] && set -x
CWD="$(cd -P -- "$(dirname -- "$0")" 2>/dev/null; pwd -P)"
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

# Prints information of the window status in the background.
set_display
live_stats &

echo "Installing winhttp..." >&2
sh -s winhttp < <(wget -qO- $WURL)

echo "Installing platform..." >&2
sh -s "$CWD"/install_mt5.verb < <(wget -qO- $WURL)

echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
