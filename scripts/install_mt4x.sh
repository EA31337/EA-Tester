#!/usr/bin/env bash
# Script to install MT platform using xdotool.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
CWD="$(cd -P -- "$(dirname -- "$0")" 2>/dev/null && pwd -P || pwd -P)"
DTMP=$(mktemp -d)
EXEFILE=mt4setup.exe
WURL=${WURL:-https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks}

# Check the dependencies.
type wget xdotool xwininfo wine ar >/dev/null

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

echo "Installing winhttp..." >&2
sh -s winhttp < <(wget -qO- $WURL)

echo "Downloading MT4 installer..." >&2
[ ! -f "$HOME/$EXEFILE" ] \
  && wget -O "$HOME/$EXEFILE" -ct3 --content-disposition ${MT_URL:-"https://www.xm.co.uk/download/xmuk-mt4"}
[ -f "$HOME/$EXEFILE" ]

# Prints information of the window status in the background.
set_display
live_stats &

echo "Starting MT4 Setup in Wine..." >&2
wine "$HOME/$EXEFILE" &

echo "Waiting for installer to initialize..." >&2
while ! WID=$(xdotool getactivewindow 2>/dev/null); do sleep 2; done

echo "Installing $(xdotool getwindowname $WID)..." >&2
while WID=$(xdotool getactivewindow); do
  xdotool key --window $WID --delay 500 Alt+N
  sleep 20
  xdotool key --window $WID --delay 500 Tab space
done

# Workaround for Chrome launching when installer finishes.
pkill -KILL chrome || true
#(sleep 10 && wineserver -k) &

echo "Waiting for platform to start..." >&2
while ! WID=$(xdotool getactivewindow 2>/dev/null); do sleep 5; done
xwininfo -id $WID -tree

# Close running MT4 instance, first the two login popup window, secondly application itself.
echo "Closing platform..." >&2
xdotool search -classname terminal.exe key --delay 200 Escape Escape Alt+f x

echo "Waiting for application to exit..." >&2
while WID=$(xdotool getactivewindow 2>/dev/null); do sleep 2; done

find "$HOME" /opt -name terminal.exe -print -quit
echo "Installation successful." >&2
echo "${BASH_SOURCE[0]} done." >&2
