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
  find "$TERMINAL_DIR" -name "Report*" -execdir cp -v "{}" "${DEST:-$(echo $CWD)}" ';'
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
while getopts :xr:f:e:E:p:d:y:s:oi:cb:D:h opts; do
  case ${opts} in
    x) # Run the script in debug mode.
      set -x
      ;;

    r) # The name of the test report file. A relative path can be specified
      if [ -s "$(dirname "${OPTARG}")" ]; then # If base folder exists,
        type realpath
        REPORT="$(realpath --relative-to="${TERMINAL_DIR}" "${OPTARG}")" # ... treat as relative path
      else
        REPORT="$(basename "${OPTARG}")" # ... otherwise, it's a filename.
      fi
      echo "Setting test report..."
      ini_set "^TestReport" "$REPORT" "$TESTER_INI"
      ;;

    f) # The .set file to run the test.
      echo "Setting EA parameters..."
      EA_NAME="$(ini_get TestExpert)"
      SETFILE="${EA_NAME}.set"
      test -s "$TESTER_DIR/$SETFILE" || cp -vf "$OPTARG" "$TESTER_DIR/$SETFILE"
      ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
      ;;

    e) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH="$(find "$ROOT" '(' -name "*$EA_NAME*.ex4" -o -name "*$EA_NAME*.ex5" ')' -print -quit)"
      [ -s "$EA_PATH" ] && { cp -v "$EA_PATH" "$TERMINAL_DIR/MQL4/Experts"; EA_NAME="$(basename "$EA_PATH")"; }
      ini_set "^TestExpert" "$EA_NAME" "$TESTER_INI"
      ;;

    E) # EA settings.
      EA_OPTS=${OPTARG}
      EA_NAME="$(ini_get TestExpert)"
      echo "Applying EA settings..."
      echo "$EA_OPTS" | tee -a "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    p) # Symbol pair to test.
      SYMBOL=${OPTARG}
      echo "Setting symbol pair..."
      ini_set "^TestSymbol" "$SYMBOL" "$TESTER_INI"
      # EA_NAME="$(ini_get TestExpert)"
      # echo "currency=$SYMBOL" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    d) # Deposit amount to test.
      DEPOSIT=${OPTARG}
      EA_NAME="$(ini_get TestExpert)"
      echo "Setting deposit..."
      echo "deposit=$DEPOSIT" >> "$TESTER_DIR/${EA_NAME}.ini"
      ;;

    y) # Year to test.
      YEAR=${OPTARG}
      echo "Setting period to test..."
      ini_set "^TestFromDate" "$YEAR.01.01" "$TESTER_INI"
      ini_set "^TestToDate"   "$YEAR.01.30" "$TESTER_INI"
      ;;

    s) # Spread to test.
      SPREAD=${OPTARG}
      echo "Setting spread to test..."
      ini_set "^Spread" "$SPREAD" "$TERMINAL_INI"
      ini_set "^TestSpread" "$SPREAD" "$TESTER_INI"
      ;;

    o) # Run optimization test.
      OPTIMIZATION=true
      echo "Setting optimization mode..."
      ini_set "^TestOptimization" true "$TESTER_INI"
      ;;

    i) # Invoke file with custom rules.
      INCLUDE=${OPTARG}
      echo "Invoking includes..."
      [ -s "$SETFILE" ] || { echo "Please specify .set file first (-f)."; exit 1; }
      . "$INCLUDE"
      ;;

    c) # Clean previous backtest data.
      clean_files
      clean_bt
      ;;

    b) # Backtest data to test.
      BT_SRC=${OPTARG}
      # Generate backtest files if not present.
      echo "Checking backtest data..."
      test -s "$(find "$TERMINAL_DIR" -name '*.fxt' -print -quit)" || $SCR/dl_bt_data.sh ${SYMBOL:-EURUSD} ${YEAR:-2014} ${BT_SRC:-N1}
      ;;

    D) # Destination directory to save the test results.
      DEST=${OPTARG}
      ;;

    \? | h | *)
      echo "$0 usage:"
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
