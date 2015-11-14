#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. $CWD/.configrc
VDIR="/vagrant"
OUT="/opt"
TPL="$VDIR/conf/$CONF"
FIND_EXCLUDES="-path *dosdevices* -prune -o"

# Check dependencies.
set -e
type git realpath ex

# Define functions.
load_config() {
  . $CWD/.configrc
}

clean_files() {
  find -L "$OUT" '(' $FIND_EXCLUDES -name "*.log" -or $FIND_EXCLUDES -name '*.dat' -or $FIND_EXCLUDES -name '*.htm' ')' -exec rm {} ';' # Remove old log, dat and htm files.
}

check_logs() {
  find -L "$OUT" $FIND_EXCLUDES -name "*.log" -exec tail "{}" ';'
}

configure_wine() {
# Configure wine.
  export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
  export DISPLAY=:0.0 # Select screen 0.
  #export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all
}

on_success() {
  echo "Test succeded."
  wineserver -k
  check_logs
  html2text "$(find -L "$TERMINAL_DIR" $FIND_EXCLUDES -name "Report*.htm")"
  [ "$DEST" ] && find -L "$TERMINAL_DIR" $FIND_EXCLUDES -name "*Report*" -and -not -path "*templates/*" -execdir cp -v "{}" "$DEST" ';'
}

on_failure() {
  echo "Test failed."
  check_logs
}

# Initialize settings.
load_config

# Check if terminal is present, otherwise install it.
test -d "$TERMINAL_DIR" || { $CWD/install_mt4.sh && load_config; }
TERMINAL_INI="$TERMINAL_DIR/config/$CONF"

# Copy the configuration file, so platform can find -L it.
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
      EA_PATH="$(find -L "$VDIR" '(' $FIND_EXCLUDES -name "*$EA_NAME*.ex4" -or $FIND_EXCLUDES -name "*$EA_NAME*.ex5" ')' -print -quit)"
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
      [ "$(find "$TERMINAL_DIR" -name '*.fxt')" ] || $VDIR/scripts/dl_bt_data.sh $SYMBOL $YEAR DS
      ;;

    D) # Destination directory to save test results.
      DEST=${OPTARG}
      ;;

  esac
done

# Prepare before test run.
clean_files
configure_wine

# Run the test in the platform.
time wine "$TERMINAL_EXE" "config/$CONF" &>> ~/wine_terminal.exe.log && on_success || on_failure
