#!/usr/bin/env bash
# .vars.inc.sh file
#
# Initialize variables.
MT_VER=${MT_VER:-4}

# Defines functions.
get_scan_dirs()
{
  printf "%s %s %s %s %s" "$ROOT" \
    $([ -d "$OPT" ] && printf "%s " "$OPT") \
    $([ -w "$HOME" ] && printf "%s " "$HOME") \
    $([ -w "$WINE_PATH" ] && printf "%s " "$WINE_PATH") \
    $([ -w "$WORKDIR" ] && printf "%s " "$WORKDIR")
}
# Determine VM.
get_mtv()
{
  printf "%s" "${MT_VER:0:1}"
}
is_mt5()
{
  [ "$(get_mtv)" = 5 ]
}
is_vm()
{
  [ -d /vagrant -a -d /home/travis -a ! -f /.dockerenv ]
}

# Determine platform paths.
SCR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" 2> /dev/null && pwd -P || pwd -P)"
ROOT="$(cd "$SCR" && git rev-parse --show-toplevel 2> /dev/null || echo "$SCR/..")"
WORKDIR="${WORKDIR:-$ROOT}"
WINE_PATH="${WINE_PATH:-$HOME/.wine/drive_c}"
OPT="/opt"
CONF_TERM="terminal.ini"
CONF_EXPERTS="experts.ini"
CONF_LAST="lastparameters.ini"
CONF_EA="ea.ini"
CONF_CUSTOM="custom.ini"
HAS_SUDO=$(
  ! timeout 1 sudo true
  echo $?
)
SCAN_DIR=$(get_scan_dirs)
TPL_TEST="$ROOT/conf/$CONF_TEST"
TPL_TERM="$ROOT/conf/$CONF_TERM"
TPL_EA="$ROOT/conf/$CONF_EA"
is_vm && set -x
TERMINAL4_EXE="$(find $SCAN_DIR -not -path "*/WebInstall/*" -name terminal.exe -print -quit)"
TERMINAL4_DIR="${TERMINAL4_DIR:-$([ -f "$TERMINAL4_EXE" ] && dirname "$TERMINAL4_EXE" || true)}"
TERMINAL4_CNF="${TERMINAL4_DIR}/config"
TERMINAL4_HST="${TERMINAL4_DIR}/history"
MTEDITOR4_EXE="$([ -d "$TERMINAL4_DIR" ] && find "$TERMINAL4_DIR" -name metaeditor.exe -print -quit || true)"
TERMINAL5_EXE="$(find $SCAN_DIR -not -path "*/WebInstall/*" -name terminal64.exe -print -quit)"
TERMINAL5_DIR="${TERMINAL5_DIR:-$([ -f "$TERMINAL5_EXE" ] && dirname "$TERMINAL5_EXE" || true)}"
TERMINAL5_CNF="${TERMINAL5_DIR}/Config"
TERMINAL5_HST="${TERMINAL5_DIR}/Bases/Default/History"
MTEDITOR5_EXE="$([ -d "$TERMINAL5_DIR" ] && find "$TERMINAL5_DIR" -name metaeditor64.exe -print -quit || true)"
MTTESTER5_EXE="$([ -d "$TERMINAL5_DIR" ] && find "$TERMINAL5_DIR" -name metatester64.exe -print -quit || true)"
if [ -n "$TERMINAL4_EXE" ]; then
  export MT_VER=4
elif [ -n "$TERMINAL5_EXE" ]; then
  export MT_VER=5
fi
CONF_TEST="mt$(get_mtv)-tester.ini"
MQL_DIR="MQL$(get_mtv)"
is_mt5 && {
  MTEDITOR_EXE="$MTEDITOR5_EXE"
  TERMINAL_ARG_CFG="/config:Config/$CONF_TEST"
  TERMINAL_CNF="$TERMINAL5_CNF"
  TERMINAL_DIR="$TERMINAL5_DIR"
  TERMINAL_EXE="$TERMINAL5_EXE"
  TERMINAL_HST="$TERMINAL5_HST"
} || {
  MTEDITOR_EXE="$MTEDITOR4_EXE"
  TERMINAL_ARG_CFG="config/$CONF_TEST"
  TERMINAL_CNF="$TERMINAL4_CNF"
  TERMINAL_DIR="$TERMINAL4_DIR"
  TERMINAL_EXE="$TERMINAL4_EXE"
  TERMINAL_HST="$TERMINAL4_HST"
}
is_vm && set +x
if [ -n "$TERMINAL_DIR" ]; then
  TERMINAL_ARG="${TERMINAL_ARG:-/skipupdate /portable}"
  TERMINAL_INI="${TERMINAL_INI:-$TERMINAL_CNF/$CONF_TERM}"
  EXPERTS_INI="${EXPERTS_INI:-$TERMINAL_CNF/$CONF_EXPERTS}"
  TESTER_INI="${TESTER_INI:-$TERMINAL_CNF/$CONF_TEST}"
  TESTER_DIR="$TERMINAL_DIR/tester"
  TESTER_LOGS="$TESTER_DIR/logs"
  DOWNLOAD_DIR="$TERMINAL_HST/downloads"
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
