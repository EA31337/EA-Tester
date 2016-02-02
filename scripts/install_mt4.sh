#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
set -e
type wget xdotool xwininfo wine

# Initialize settings.
. $CWD/.configrc

echo "Downloading MT4 installer..."
[ ! -f "$HOME/mt4setup.exe" ] && wget -P "$HOME" -ct3 https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe

# Detect and configure proxy.
#configure_proxy

echo "Starting MT4 Setup in Wine..."
wine "$HOME/mt4setup.exe" &

set +e
echo "Waiting for Wine to initialize..."
while ! WID=$(xdotool search --name "MetaTrader 4 Setup"); do
  sleep 2
done

echo "Sending installer keystrokes..."
xdotool key --window $WID --delay 500 space Tab Tab Tab Return Tab Tab Tab space Alt+n

echo "Waiting for installer to finish..."
xwininfo -id $WID -tree
while pgrep -l mt4setup; do sleep 5; done

echo "Waiting for MT4 platform to start..."
while ! WID=$(xdotool search --name "MetaTrader 4 - *"); do
  sleep 2
done

# Close running MT4 instance, first the two login popup window, secondly application itself
echo "Closing application..."
xdotool key --window $WID --delay 500 Escape Escape Alt+f x
sleep 1
wineserver -k

# Re-initialize settings.
. $CWD/.configrc

find ~ "$OUT" -name terminal.exe -print -quit
echo "Installation successful.'
echo "$0 done."
