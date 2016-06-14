#!/bin/sh -e
# Script to install MT platform using winetricks.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
DTMP=$(mktemp -d)
export WINEDLLOVERRIDES="mscoree,mshtml="

# Check the dependencies.
type winetricks ar

# @todo
#bash <(curl $WURL) winhttp # @fixme: https://github.com/Winetricks/winetricks/issues/645

echo "Installing winhttp..." >&2
curl -o "$DTMP"/winetricks $WURL
sh $DTMP/winetricks winhttp

echo "Installing platform..." >&2
sh $DTMP/winetricks mt4

echo "Installation successful." >&2
echo "$0 done." >&2
