#!/bin/sh
# Script to install MT platform using winetricks.
set -e
type winetricks
. $(which winetricks)

set -x
echo $W_CACHE
w_download "https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe"
ls -la $W_CACHE
# @todo
cd "$W_CACHE"/
w_try "$WINE" mt4setup.exe $W_UNATTENDED_SLASH_Q
# @todo
echo "$0 done."
