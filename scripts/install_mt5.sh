#!/usr/bin/env bash
# Script to install MT platform using winetricks.
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
export WINEDLLOVERRIDES="mscoree,mshtml="
[ "$TRACE" ] && set -x

# Check the dependencies.
#type winetricks

echo "Installing winhttp..." >&2
sh -s winhttp < <(wget -qO- $WURL)

# Check whether libgnutls needs patching.
[ -d "/usr/lib/i386-linux-gnu" ] && $CWD/fix_libgnutls.sh


echo "Installing platform..." >&2
sh -s "$CWD"/install_mt5.verb < <(wget -qO- $WURL)

echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
