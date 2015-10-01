#!/usr/bin/env bash
set -x
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."
OUT="/opt"
TPL="/vagrant/conf/mt4-tester.ini"

# Check if terminal is present.
[ "$(find "$OUT" -name terminal.exe -print -quit)" ] || $CWD/scripts/dl_mt4.sh
TERMINAL_EXE="$(find "$OUT" -name terminal.exe -print -quit)"
TERMINAL_DIR="$(dirname "$TERMINAL")"
TERMINAL_INI="$TERMINAL_DIR/config/$TPL"

# Check if backtest files are present.
[ "$(find "$OUT" -name '*.fxt')" ] || $CWD/scripts/dl_bt_data.sh

# Copying ini file to MT's directory so MT can find it.
cp -v $TPL $TERMINAL_INI
cp -v $SETFILE $TERMINAL_DIR/tester

# Monitor logs in the background.
find "$OUT" '(' -name "*.log" -or -name '*.dat' ')' -delete
sleep 5 && tail -f $TERMINAL_DIR/*/*.log &
trap "killall tail" EXIT # Clean up after exit.

# Configure wine.
export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
export DISPLAY=:0.0 # Select screen 0.
export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all

# Run terminal.
wine $TERMINAL_EXE $TERMINAL_INI && html2text $TERMINAL_DIR/Report.htm
