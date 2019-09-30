#!/usr/bin/env bash
# .vars.inc.sh file
#
# Initialize variables.

# Determine VM.
is_vm() { [ -d /vagrant -a -d /home/travis -a ! -f /.dockerenv ]; }

# Determine platform paths.
SCR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P || pwd -P)"
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
is_vm && set -x
TERMINAL_EXE="$(find "$ROOT" "$OUT" "$HOME" -not -path "*/WebInstall/*" -name terminal.exe -print -quit)"
TERMINAL_DIR="${TERMINAL_DIR:-$([ -f "$TERMINAL_EXE" ] && dirname "$TERMINAL_EXE" || true)}"
MTEDITOR_EXE="$([ -d "$TERMINAL_DIR" ] && find "$TERMINAL_DIR" -name metaeditor.exe -print -quit || true)"
TERMINAL5_EXE="$(find "$ROOT" "$OUT" "$HOME" -not -path "*/WebInstall/*" -name terminal64.exe -print -quit)"
TERMINAL5_DIR="${TERMINAL5_DIR:-$([ -f "$TERMINAL5_EXE" ] && dirname "$TERMINAL5_EXE" || true)}"
MTEDITOR5_EXE="$([ -d "$TERMINAL5_DIR" ] && find "$TERMINAL5_DIR" -name metaeditor64.exe -print -quit || true)"
MTTESTER5_EXE="$([ -d "$TERMINAL5_DIR" ] && find "$TERMINAL5_DIR" -name metatester64.exe -print -quit || true)"
is_vm && set +x
MQL_DIR="MQL4"
if [ -n "$TERMINAL_DIR" ]; then
  TERMINAL_ARG="${TERMINAL_ARG:-/skipupdate /portable}"
  TERMINAL_CNF="${TERMINAL_DIR}/config"
  TERMINAL_INI="${TERMINAL_INI:-$TERMINAL_CNF/$CONF_TERM}"
  TESTER_INI="${TESTER_INI:-$TERMINAL_CNF/$CONF_TEST}"
  TESTER_DIR="$TERMINAL_DIR/tester"
  TESTER_LOGS="$TESTER_DIR/logs"
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
  LOG_DIR="$TERMINAL_DIR/logs"
  TERMINAL_LOG="$LOG_DIR/terminal.log.txt"
fi
REPO_MT="EA31337/MT-Platforms"

# Set constants.
TRUE=0
FALSE=1
