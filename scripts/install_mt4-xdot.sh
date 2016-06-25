#!/bin/sh -e
# Script to install MT platform using xdotool.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
DTMP=$(mktemp -d)
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
export WINEDLLOVERRIDES="mscoree,mshtml="

# Check the dependencies.
type wget xdotool xwininfo wine winetricks ar >&2

# @fixme: This breaks MT4 install on CI.
#echo "Installing winhttp..." >&2
#curl -o "$DTMP"/winetricks $WURL
#sh $DTMP/winetricks winhttp

# Check whether libgnutls needs patching.
[ -d "/usr/lib/i386-linux-gnu" ] && $CWD/secur32_fix.sh

echo "Downloading MT4 installer..." >&2
[ ! -f "$HOME/mt4setup.exe" ] && wget -P "$HOME" -ct3 https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe

echo "Starting MT4 Setup in Wine..." >&2
wine "$HOME/mt4setup.exe" &

set +e
echo "Waiting for Wine to initialize..."
while ! WID=$(xdotool search --name "MetaTrader 4 Setup"); do
  sleep 2
done

echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 space Tab Tab Tab Return Tab Tab Tab space Alt+n

echo "Waiting for installer to finish..." >&2
xwininfo -id $WID -tree
while pgrep -l mt4setup; do sleep 5; done

echo "Waiting for MT4 platform to start..." >&2
while ! WID=$(xdotool search --name "MetaTrader 4 - *"); do
  sleep 2
done

# Close running MT4 instance, first the two login popup window, secondly application itself
echo "Closing application..." >&2
xdotool key --window $WID --delay 500 Escape Escape Alt+f x
sleep 1
wineserver -k

find ~ /opt -name terminal.exe -print -quit
echo "Installation successful." >&2
echo "$0 done." >&2
