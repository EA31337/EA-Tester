#!/usr/bin/env bash
# Script to install MT platform using xdotool.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
CWD="$( (cd -P -- "$(dirname -- "$0")" 2>/dev/null && pwd -P) || pwd -P)"
EXEFILE=mt4setup.exe

# Check the dependencies.
type winetricks wget xdotool xwininfo wine ar >/dev/null

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

echo "Installing winhttp..." >&2
winetricks -q winhttp

echo "Downloading MT4 installer..." >&2
[ ! -f "$HOME/$EXEFILE" ] \
  && wget -O "$HOME/$EXEFILE" -ct3 --content-disposition "${MT_URL:-"https://download.mql5.com/cdn/web/8472/mt4/xmuk4setup.exe"}"
[ -f "$HOME/$EXEFILE" ]

# Prints information of the window status in the background.
echo "Checking display..." >&2
set_display
live_stats &

echo "Starting MT4 Setup in Wine..." >&2
[ -f /.dockerenv ] && export WINEPREFIX="$HOME/.wine_mt4" # Fixes MT4 startup issue in Docker.
wine "$HOME/$EXEFILE" &

echo "Waiting for installer to initialize..." >&2
while ! WID=$(xdotool getactivewindow 2>/dev/null); do sleep 2; done

echo "Installing $(xdotool getwindowname "$WID")..." >&2
while WID=$(xdotool getactivewindow); do
  xdotool key --window "$WID" --delay 500 Alt+N
  sleep 20
  xdotool key --window "$WID" --delay 500 Tab space
done

# Workaround for Chrome launching when installer finishes.
pkill -KILL chrome || true
#(sleep 10 && wineserver -k) &

echo "Waiting for platform to start..." >&2
while ! WID=$(xdotool getactivewindow 2>/dev/null); do sleep 5; done
xwininfo -id "$WID" -tree

# Close running MT4 instance, first the two login popup window, secondly application itself.
echo "Closing platform..." >&2
xdotool search -classname terminal.exe key --delay 200 Escape Escape Alt+f x

echo "Waiting for application to exit..." >&2
while WID=$(xdotool getactivewindow 2>/dev/null); do sleep 2; done

find "$HOME" /opt -name terminal.exe -print -quit
echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
