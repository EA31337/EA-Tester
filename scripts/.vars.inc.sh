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
WINE_PATH="${WINE_PATH:-$HOME/.wine/drive_c/Program Files}"
OUT="/opt"
CONF_TEST="mt4-tester.ini"
CONF_TERM="terminal.ini"
CONF_LAST="lastparameters.ini"
CONF_EA="ea.ini"
CONF_CUSTOM="custom.ini"
TPL_TEST="$ROOT/conf/$CONF_TEST"
TPL_TERM="$ROOT/conf/$CONF_TERM"
TPL_EA="$ROOT/conf/$CONF_EA"
set -x
TERMINAL_EXE="$(find "$ROOT" "$OUT" "$HOME" -name terminal.exe -print -quit)"
TERMINAL_DIR="${TERMINAL_DIR:-$([ -f "$TERMINAL_EXE" ] && dirname "$TERMINAL_EXE" || true)}"
MTEDITOR_EXE="$([ -d "$TERMINAL_DIR" ] && find "$TERMINAL_DIR" -name metaeditor.exe -print -quit || true)"
set +x
MQL_DIR="MQL4"
if [ "$TERMINAL_DIR" ]; then
  TERMINAL_ARG="/skipupdate /portable"
  TERMINAL_CNF="${TERMINAL_DIR}/config"
  TERMINAL_INI="${TERMINAL_INI:-$TERMINAL_CNF/$CONF_TERM}"
  TESTER_INI="${TESTER_INI:-$TERMINAL_CNF/$CONF_TEST}"
  TESTER_DIR="$TERMINAL_DIR/tester"
  HISTORY_DIR="$TERMINAL_DIR/history"
  DOWNLOAD_DIR="$TERMINAL_DIR/history/downloads"
  TICKDATA_DIR="$TERMINAL_DIR/tester/history"
  LASTPARAM_INI="$TESTER_DIR/$CONF_LAST"
  CUSTOM_INI="$TESTER_DIR/$CONF_CUSTOM"
  CUSTOM_LOG="$TESTER_DIR/logs/backtest.log"
  MQLOG_DIR="$TERMINAL_DIR/$MQL_DIR/Logs"
  LIB_DIR="$TERMINAL_DIR/$MQL_DIR/Libraries"
  FILES_DIR="$TERMINAL_DIR/$MQL_DIR/Files"
  EXPERTS_DIR="$TERMINAL_DIR/$MQL_DIR/Experts"
  SCRIPTS_DIR="$TERMINAL_DIR/$MQL_DIR/Scripts"
  LOG_DIR="$TESTER_DIR/logs"
  TERMINAL_LOG="$LOG_DIR/terminal.log.txt"
fi
REPO_URL="https://github.com/EA31337/FX-MT-VM"

# Set constants.
TRUE=0
FALSE=1
FXT_OFF_SPREAD=$(printf "%02x" 252)
FXT_OFF_LOTSTEP=$(printf "%02x" 280)
SRAW_OFF_DIGITS=$(printf "%02x" 104)
SRAW_OFF_PSIZE=$(printf "%02x" 1776)
