#!/usr/bin/env bash
set -x
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
type git realpath ex

# Define functions.
on_success() {
  echo "Test succeded."
  show_logs
  html2text "$(find "$TERMINAL_DIR" -name "Report*.htm")"
  [ "$DEST" ] && find "$TERMINAL_DIR" -name "*Report*" -and -not -path "*templates/*" -execdir cp -v "{}" "$DEST" ';'
}

on_failure() {
  echo "Test failed."
  show_logs
}

on_finish() {
  wineserver -k
  echo "$0 done."
}

# Initialize settings.
. $CWD/.configrc

# Check if terminal is present, otherwise install it.
test -d "$TERMINAL_DIR" || { $SCR/install_mt4.sh && load_config; }

# Copy the configuration file, so platform can find it.
cp -v "$TPL" "$TERMINAL_INI"
# cp -v $SETFILE $TERMINAL_DIR/tester

# Check if backtest files are present.
[ "$(find "$OUT" -name '*.fxt')" ] || $CWD/scripts/dl_bt_data.sh ${symbol:EURUSD} ${year:2014} DS

# Prepare before test run.
clean_files

# Run the test with the platform.
time wine "$TERMINAL_EXE" "config/$CONF" && on_success || on_failure
on_finish
