#!/usr/bin/env bash
set -x
CWD="$(cd -P -- "$(dirname -- "$0")/../" && pwd -P)"
OUT="/opt"
TPL="/vagrant/conf/mt4-tester.ini"

# Define functions.
run_logs() {
  # Monitor logs in the background.
  find "$OUT" '(' -name "*.log" -or -name '*.dat' ')' -delete # Remove old log and dat files.
  (sleep 5 && find . -name "*.log" | xargs tail -f) &
  trap "killall tail" EXIT # Clean up after exit.
}
configure_wine() {
# Configure wine.
  export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
  export DISPLAY=:0.0 # Select screen 0.
  export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all
}

# Check if terminal is present.
[ "$(find "$OUT" -name terminal.exe -print -quit)" ] || $CWD/scripts/dl_mt4.sh
TERMINAL_EXE="$(find "$OUT" -name terminal.exe -print -quit)"
TERMINAL_DIR="$(dirname "$TERMINAL_EXE")"
TERMINAL_INI="$TERMINAL_DIR/config/mt4-tester.ini"

# Copy the configuration file, so platform can find it.
cp -v "$TPL" "$TERMINAL_INI"

# Parse the arguments.
while getopts r:f:n:p:d:y:s:b: opts; do
  case ${opts} in
    r) # Directory to save the Reports files.
      REPORTDIR=${OPTARG}
      [ "$REPORTDIR" ]  && ex -s +"%s#^TestReport=\zs.\+$#$REPORTDIR#" -cwq "$TERMINAL_INI"
      ;;
    f) # The set file to run the test.
      SETFILE=${OPTARG}
      [ -s "$SETFILE" ] && cp -v "$SETFILE" "$TERMINAL_DIR/tester"
      [ "$SETFILE" ]    && ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq "$TERMINAL_INI"
      ;;
    n) # EA name.
      NAME=${OPTARG}
      EXPERT="$(find "$CWD" '(' -name "*$NAME*.ex4" -or -name "*$NAME*.ex5" ')' -print -quit)"
      $CWD/scripts/dl_ea.sh # Download EA.
      [ "$EXPERT" ]     && ex -s +"%s/^TestExpert=\zs.\+$/$EXPERT/" -cwq "$TERMINAL_INI"
      ;;
    p) # Symbol pair to test.
      SYMBOL=${OPTARG}
      [ "$SYMBOL" ]     && ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq "$TERMINAL_INI"
      ;;
    d) # Deposit amount to test.
      DEPOSIT="$5"
      # @todo: Set the right deposit for the test.
      ;;
    y) # Year to test.
      YEAR=${OPTARG}
      FROM="$YEAR.01.01"
      TO="$YEAR.01.02"
      [ "$FROM" ]       && ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq "$TERMINAL_INI"
      [ "$TO" ] 	      && ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq "$TERMINAL_INI"
      ;;
    s) # Spread to test.
      SPREAD=${OPTARG}
      # @todo: Set the right spread for the test.
      ;;
    b) # Backtest data to test.
      BT_SOURCE=${OPTARG}
      # @todo: Place the right backtest data into the right place and change the profile name.
      [ "$(find "$OUT" -name '*.fxt')" ] || $CWD/scripts/dl_bt_data.sh # Download backtest files if not present.
      ;;
  esac
done

# Prepare before test run.
run_logs
configure_wine

# Run the test in the platform.
wine "$TERMINAL_EXE" "$TERMINAL_INI" && html2text "$TERMINAL_DIR/Report.htm"
