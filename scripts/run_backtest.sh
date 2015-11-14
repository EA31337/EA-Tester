#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
type git realpath ex

# Define functions.
configure_wine() {
# Configure wine.
  export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
  export DISPLAY=:0.0 # Select screen 0.
  export WINEDEBUG="warn-all,fixme-all" # For debugging, try: WINEDEBUG=trace+all
}

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

# Parse the arguments.
while getopts r:f:n:p:d:y:s:b:D: opts; do
  case ${opts} in
    r) # The name of the test report file. A relative path can be specified
      if [ -s "$(dirname "${OPTARG}")" ]; then # If base folder exists,
        REPORT="$(realpath --relative-to="${TERMINAL_DIR}" "${OPTARG}")" # ... treat as relative path
      else
        REPORT="$(basename "${OPTARG}")" # ... otherwise, it's a filename.
      fi
      [ "$REPORT" ] && ex -s +"%s#^TestReport=\zs.\+\$#$REPORT#" -cwq "$TERMINAL_INI"
      ;;

    f) # The set file to run the test.
      SETFILE=${OPTARG}
      [ -s "$SETFILE" ] && cp -v "$SETFILE" "$TERMINAL_DIR/tester"
      [ "$SETFILE" ]    && ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq "$TERMINAL_INI"
      ;;

    n) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH="$(find "$ROOT" '(' -name "*$EA_NAME*.ex4" -o -name "*$EA_NAME*.ex5" ')' -print -quit)"
      [ -s "$EA_PATH" ] && { cp -v "$EA_PATH" "$TERMINAL_DIR/MQL4/Experts"; EA_NAME="$(basename "$EA_PATH")"; }
      [ "$EA_NAME" ]    && ex -s +"%s/^TestExpert=\zs.\+$/$EA_NAME/" -cwq "$TERMINAL_INI"
      ;;

    p) # Symbol pair to test.
      SYMBOL=${OPTARG}
      [ "$SYMBOL" ] && ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq "$TERMINAL_INI"
      ;;

    d) # Deposit amount to test.
      DEPOSIT=${OPTARG}
      if [ -n "$DEPOSIT" ]; then
        DEPOSIT_PATTERN="Deposit="
        grep -q "^$DEPOSIT_PATTERN" "$TERMINAL_INI" && sed "s/\(^$DEPOSIT_PATTERN\).*/\1$DEPOSIT/" -i "$TERMINAL_INI" \
                                                    || echo -e "\n; Set deposit amount to test\n$DEPOSIT_PATTERN$DEPOSIT" >> "$TERMINAL_INI"
      fi
      ;;

    y) # Year to test.
      YEAR=${OPTARG}
      FROM="$YEAR.01.01"
      TO="$YEAR.01.02"
      [ "$FROM" ] && ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq "$TERMINAL_INI"
      [ "$TO" ]   && ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq "$TERMINAL_INI"
      ;;

    s) # Spread to test.
      SPREAD=${OPTARG}
      [ "$SPREAD" ] && ex -s +"%s/^Spread=\zs.\+$/$SPREAD/" -cwq "$TERMINAL_DIR/config/terminal.ini"
      ;;

    b) # Backtest data to test.
      BT_SOURCE=${OPTARG}
      # Download backtest files if not present.
      [ "$(find "$TERMINAL_DIR" -name '*.fxt')" ] || $SCR/dl_bt_data.sh ${SYMBOL:EURUSD} ${YEAR:2014} DS
      ;;

    D) # Destination directory to save test results.
      DEST=${OPTARG}
      ;;

  esac
done

# Prepare before test run.
clean_files
configure_wine

# Run the test with the platform.
time wine "$TERMINAL_EXE" "config/$CONF" && on_success || on_failure
on_finish
