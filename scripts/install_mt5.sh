#!/bin/sh -e
# Script to install MT platform using winetricks.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
export WINEDLLOVERRIDES="mscoree,mshtml="

# Check the dependencies.
type winetricks

echo "Installing winhttp..." >&2
curl -o "$DTMP"/winetricks $WURL
sh $DTMP/winetricks winhttp

# Check whether libgnutls needs patching.
[ -d "/usr/lib/i386-linux-gnu" ] && $CWD/secur32_fix.sh


echo "Installing platform..." >&2
winetricks $CWD/winetricks_mt5.verb

echo "Installation successful." >&2
echo "$0 done." >&2
