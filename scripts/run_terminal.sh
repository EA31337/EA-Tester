#!/usr/bin/env bash
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check if terminal is present, otherwise install it.
echo "Checking platform dependencies..." >&2
type wine >/dev/null

# Initialize variables.
. $CWD/.vars.inc.sh

[ "$TERMINAL_EXE" ] \
  || { echo "Error: Terminal not found, please install it first." >&2; exit 1; }
echo "Display is: $DISPLAY"

# Run the test under the platform.
echo "Running platform..." >&2
wine "$TERMINAL_EXE" 2> "$TERMINAL_LOG"
echo "$0 done." 1>&2
