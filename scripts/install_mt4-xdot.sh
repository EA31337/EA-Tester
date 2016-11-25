#!/usr/bin/env bash
# Script to install MT platform using xdotool..
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
DTMP=$(mktemp -d)
WURL="https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks"
export WINEDLLOVERRIDES="mscoree,mshtml=,winebrowser.exe="
[ "$TRACE" ] && set -x

# Check the dependencies.
type wget xdotool xwininfo wine winetricks ar >&2

echo "Downloading MT4 installer..." >&2
[ ! -f "$HOME/mt4setup.exe" ] && wget -P "$HOME" -ct3 https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe

echo "Starting MT4 Setup in Wine..." >&2
wine "$HOME/mt4setup.exe" &

set +e
echo "Waiting for Wine to initialize..."
while ! WID=$(xdotool search --name "MetaTrader Setup"); do
  sleep 2
done

echo "Title: $(xdotool getwindowname $WID)..."

echo "Sending installer keystrokes..." >&2
xdotool key --window $WID --delay 500 space Tab Tab Tab Return Tab Tab Tab space Alt+n

echo "Waiting for installer to finish..." >&2
xwininfo -id $WID -tree
while pgrep -l mt4setup; do sleep 5; done

echo "Waiting for MT4 platform to start..." >&2
while ! WID=$(xdotool search --name "Account"); do
  sleep 2
done
xwininfo -id $WID -tree

# Close running MT4 instance, first the two login popup window, secondly application itself.
echo "Closing application..." >&2
xdotool key --window $WID --delay 500 Escape Escape Alt+f x
sleep 1
wineserver -k

find ~ /opt -name terminal.exe -print -quit
echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
