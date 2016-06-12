#!/bin/sh -e
# Script to install MT platform using winetricks.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
DTMP=$(mktemp -d)
type winetricks ar
#bash <(curl $WURL) winhttp # @fixme: https://github.com/Winetricks/winetricks/issues/645
curl -o "$DTMP"/winetricks $WURL
winetricks winhttp
sh $DTMP/winetricks mt4
