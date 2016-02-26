#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check if terminal is present, otherwise install it.
echo "Checking platform dependencies..." >&2
type wine
[ ! "$(find ~ /opt -name terminal.exe -print -quit)" ] && $CWD/install_mt4.sh
echo "Display is: $DISPLAY"

# Initialize settings.
. $CWD/.configrc

# Run the test under the platform.
echo "Running platform..." >&2
wine "$TERMINAL_EXE" 2> "$TERMINAL_LOG"
echo "$0 done."
