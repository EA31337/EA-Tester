#!/usr/bin/env bash
# .vars.rc.sh file
#
# Initialize variables.

if [ ! "$TERMINAL_EXE" ] && [ "$VERBOSE" ]; then
  echo "Initializing variables... (args: $*)" >&2
fi

# Determine platform paths.
SCR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ROOT="$(cd "$SCR" && git rev-parse --show-toplevel 2> /dev/null || echo "$SCR/..")"
OUT="/opt"
CONF_TEST="mt4-tester.ini"
CONF_TERM="terminal.ini"
CONF_LAST="lastparameters.ini"
CONF_EA="ea.ini"
CONF_CUSTOM="custom.ini"
TPL_TEST="$ROOT/conf/$CONF_TEST"
TPL_TERM="$ROOT/conf/$CONF_TERM"
TPL_EA="$ROOT/conf/$CONF_EA"
TERMINAL_ARG="/skipupdate /portable"
TERMINAL_EXE="$(find ~ "$OUT" -name terminal.exe -print -quit)"
MTEDITOR_EXE="$(find ~ "$OUT" -name metaeditor.exe -print -quit)"
TERMINAL_DIR="$( [ "$TERMINAL_EXE" ] && dirname "$TERMINAL_EXE" || true )"
TERMINAL_CNF="$TERMINAL_DIR/config"
TERMINAL_INI="$TERMINAL_CNF/$CONF_TERM"
TESTER_INI="$TERMINAL_CNF/$CONF_TEST"
TESTER_DIR="$TERMINAL_DIR/tester"
HISTORY_DIR="$TERMINAL_DIR/history"
DOWNLOAD_DIR="$TERMINAL_DIR/history/downloads"
TICKDATA_DIR="$TERMINAL_DIR/tester/history"
TERMINAL_LOG="$TESTER_DIR/logs/terminal.log.txt"
LASTPARAM_INI="$TESTER_DIR/$CONF_LAST"
CUSTOM_INI="$TESTER_DIR/$CONF_CUSTOM"
CUSTOM_LOG="$TESTER_DIR/logs/backtest.log"
LOG_DIR="$TERMINAL_DIR/MQL4/Logs"
EXPERTS_DIR="MQL4/Experts"
SCRIPTS_DIR="MQL4/Scripts"
WINE_PATH="$HOME/.wine/drive_c/Program Files"
REPO_URL="https://github.com/EA31337/FX-MT-VM"

# Set constants.
TRUE=0
FALSE=1
FXT_OFF_SPREAD=$(printf "%02x" 252)
FXT_OFF_LOTSTEP=$(printf "%02x" 280)
SRAW_OFF_DIGITS=$(printf "%02x" 104)
SRAW_OFF_PSIZE=$(printf "%02x" 1776)
