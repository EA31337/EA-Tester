#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
type git ex html2text

# Define functions.
on_success() {
  ! grep -C2 -e "Initialization failed" <(show_logs) || exit 1
  echo "Test succeded." >&2
  show_logs
  find "$TERMINAL_DIR" -name "Report*.htm" -exec sh -c "html2text '{}' | head -n40"  ';'
  [ "$DEST" ] && find "$TERMINAL_DIR" -name "Report*" -execdir cp -v "{}" "$DEST" ';'
  on_finish
  exit 0
}

on_failure() {
  echo "Test failed." >&2
  show_logs
  on_finish
  exit 1
}

on_finish() {
  wineserver -k
  echo "$0 done." >&2
}

# Check if terminal is present, otherwise install it.
echo "Checking platform dependencies..." >&2
[ ! "$(find ~ /opt -name terminal.exe -print -quit)" ] && $CWD/install_mt4.sh

# Initialize settings.
. $CWD/.configrc

# Copy the configuration file, so platform can find it.
cp -v "$TPL_TEST" "$TESTER_INI"
cp -v "$TPL_TERM" "$TERMINAL_INI"

# Parse the arguments.
while getopts :hr:f:n:E:p:d:y:s:cb:D: opts; do
  case ${opts} in
    r) # The name of the test report file. A relative path can be specified
      if [ -s "$(dirname "${OPTARG}")" ]; then # If base folder exists,
        type realpath
        REPORT="$(realpath --relative-to="${TERMINAL_DIR}" "${OPTARG}")" # ... treat as relative path
      else
        REPORT="$(basename "${OPTARG}")" # ... otherwise, it's a filename.
      fi
      ini_set "^TestReport" "$REPORT" "$TESTER_INI"
      ;;

    f) # The set file to run the test.
      SETFILE=${OPTARG}
      [ -s "$SETFILE" ] && cp -v "$SETFILE" "$TERMINAL_DIR/tester"
      ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
      ;;

    n) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH="$(find "$ROOT" '(' -name "*$EA_NAME*.ex4" -o -name "*$EA_NAME*.ex5" ')' -print -quit)"
      [ -s "$EA_PATH" ] && { cp -v "$EA_PATH" "$TERMINAL_DIR/MQL4/Experts"; EA_NAME="$(basename "$EA_PATH")"; }
      ini_set "^TestExpert" "$EA_NAME" "$TESTER_INI"
      ;;

    E) # EA settings.
      EA_OPTS=${OPTARG}
      EA_NAME="$(ini_get TestExpert)"
      echo "$EA_OPTS" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    p) # Symbol pair to test.
      SYMBOL=${OPTARG}
      ini_set "^TestSymbol" "$SYMBOL" "$TESTER_INI"
      # EA_NAME="$(ini_get TestExpert)"
      # echo "currency=$SYMBOL" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    d) # Deposit amount to test.
      DEPOSIT=${OPTARG}
      EA_NAME="$(ini_get TestExpert)"
      echo "deposit=$DEPOSIT" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    y) # Year to test.
      YEAR=${OPTARG}
      ini_set "^TestFromDate" "$YEAR.01.01" "$TESTER_INI"
      ini_set "^TestToDate"   "$YEAR.01.30" "$TESTER_INI"
      ;;

    s) # Spread to test.
      SPREAD=${OPTARG}
      ini_set "^Spread" "$SPREAD" "$TERMINAL_INI"
      ini_set "^TestSpread" "$SPREAD" "$TESTER_INI"

      #EA_NAME="$(ini_get TestExpert)"
      #echo "spread=$SPREAD" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    c) # Clean previous backtest data.
      clean_files
      clean_bt
      ;;
    b) # Backtest data to test.
      BT_SRC=${OPTARG}
      # Generate backtest files if not present.
      test -s "$(find "$TERMINAL_DIR" -name '*.fxt' -print -quit)" || $SCR/dl_bt_data.sh ${SYMBOL:-EURUSD} ${YEAR:-2014} $BT_SRC
      ;;

    D) # Destination directory to save test results.
      DEST=${OPTARG}
      ;;
    \? | h | *)
      grep " .) #" $0 | grep -v grep
      exit 0
      ;;

  esac
done

# Prepare before test run.
[ "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')')" ] || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
clean_files

# Run the test under the platform.
set -x
time wine "$TERMINAL_EXE" "config/$CONF_TEST" && on_success || on_failure
