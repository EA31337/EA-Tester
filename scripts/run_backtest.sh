#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS=":r:e:f:E:p:d:y:s:oi:cb:tD:vxh"

## Check dependencies.
type git ex

## Define functions.
# Invoke on test success.
on_success() {
  ! grep -C2 -e "Initialization failed" <(show_logs) || exit 1
  show_logs
  echo "Test succeded." >&2
  parse_results $@
  on_finish
  exit 0
}

# Invoke on test failure.
on_failure() {
  echo "Test failed." >&2
  show_logs
  on_finish
  exit 1
}

# Invoke on test finish.
on_finish() {
  wineserver -k
  echo "$0 done." >&2
}

# Parse report files.
parse_results() {
  local OPTIND
  REPORT_BASE="$(basename "$(ini_get TestReport)")"
  REPORT_FILE=$(find "$TERMINAL_DIR" -name "$REPORT_BASE.htm")
  while getopts $ARGS arg; do
    case $arg in
      t)
        echo "Converting report files..."
        html2text -width 180 -o "$REPORT_BASE.txt" "$REPORT_FILE"
        ;;
      D)
        echo "Copying report files..."
        DEST="${DEST:-$(echo $CWD)}"
        cp $VFLAG "$TERMINAL_DIR/$(basename "${REPORT_FILE%.*}")".* "$DEST"
        find "$TERMINAL_DIR/tester/files" -type f $VPRINT -exec cp $VFLAG "{}" "$DEST" ';'
        ;;
      v)
        echo "Printing test reports..."
        html2text -width 180 "$REPORT_FILE" | sed /Graph/q
        find "$TERMINAL_DIR/tester/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" ';'
        ;;
      o)
        echo "Saving optimization results..."
        if [ -z "$input_values" ]; then
          echo 123
          # ini_get "^todo"
          # ini_set "^todo" true "$SETORG"
        fi
        ;;
      esac
  done
}

# Parse the initial arguments.
while getopts $ARGS opts; do
  case ${opts} in
    v) # Verbose mode.
      VERBOSE=1
      VFLAG="-v"
      VPRINT="-print"
      type html2text sed
      ;;
    x) # Run the script in debug mode.
      set -x
      ;;
  esac
done

# Check if terminal is present, otherwise install it.
echo "Checking platform dependencies..." >&2
[ ! "$(find ~ /opt -name terminal.exe -print -quit)" ] && $CWD/install_mt4.sh

# Initialize settings.
. $CWD/.configrc

# Copy the configuration file, so platform can find it.
cp $VFLAG "$TPL_TEST" "$TESTER_INI"
cp $VFLAG "$TPL_TERM" "$TERMINAL_INI"

# Parse the arguments.
OPTIND=1
while getopts $ARGS opts; do
  case ${opts} in
    r) # The name of the test report file. A relative path can be specified.
      if [ -s "$(dirname "${OPTARG}")" ]; then # If base folder exists,
        type realpath
        REPORT="$(realpath --relative-to="${TERMINAL_DIR}" "${OPTARG}")" # ... treat as relative path
      else
        REPORT="$(basename "${OPTARG}")" # ... otherwise, it's a filename.
      fi
      echo "Setting test report..."
      ini_set "^TestReport" "$REPORT" "$TESTER_INI"
      ;;

    e) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH="$(find "$ROOT" '(' -name "*$EA_NAME*.ex4" -o -name "*$EA_NAME*.ex5" ')' -print -quit)"
      [ -s "$EA_PATH" ] && { cp $VFLAG "$EA_PATH" "$TERMINAL_DIR/MQL4/Experts"; EA_NAME="$(basename "${EA_PATH%.*}")"; }
      ini_set "^TestExpert" "$EA_NAME" "$TESTER_INI"
      ;;

    f) # The .set file to run the test.
      echo "Setting EA parameters..."
      SETORG="$OPTARG"
      EA_NAME="$(ini_get TestExpert)"
      SETFILE="${EA_NAME}.set"
      [ -f "$TESTER_DIR/$SETFILE" ] || cp -f $VFLAG "$OPTARG" "$TESTER_DIR/$SETFILE"
      ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
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
      ini_set "^TestToDate"   "$YEAR.02.30" "$TESTER_INI"
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
      SETFILE="$(ini_get TestExpert).set"
      [ -f "$TESTER_DIR/$SETFILE" ] || { echo "Please specify .set file first (-f)."; exit 1; }
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
      [ -s "$(find "$TERMINAL_DIR" -name '*.fxt' -print -quit)" ] || $SCR/get_bt_data.sh ${SYMBOL:-EURUSD} ${YEAR:-2014} ${BT_SRC:-N1}
      ;;

    t) # Convert Report files into text format.
      type html2text
      ;;

    D) # Destination directory to save the test results.
      DEST=${OPTARG}
      ;;

    v)
      # Verbose flag.
      ;;
    x)
      # Debug flag.
      ;;

    \? | h | *)
      echo "$0 usage:"
      grep " .)\ #" $0
      exit 0
      ;;

  esac
done

# Prepare before test run.
[ "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')')" ] \
  || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
clean_files

# Run the test under the platform.
time wine "$TERMINAL_EXE" "config/$CONF_TEST" && on_success $@ || on_failure
