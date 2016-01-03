#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS=":r:e:f:E:c:p:d:y:s:oi:I:Cb:tD:vxh"

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
  local OPTIND
  while getopts $ARGS arg; do
    case $arg in
      I) # Invoke file after successful test.
        echo "Invoking file after test..."
        . "$OPTARG"
        ;;
      esac
  done
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
        html2text -width 180 "$REPORT_FILE" | sed "/\[Graph\]/q"
        find "$TERMINAL_DIR/tester/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" ';'
        ;;
      o)
        echo "Saving optimization results..."
        if [ -z "$input_values" ]; then
          for input in ${param_list[@]}; do
            value=$(ini_get "$input" "$REPORT_FILE")
            echo "Setting '$input' to '$value' in '$(basename $SETORG)'"
            ini_set "^$input" "$value" "$SETORG"
          done
        fi
        ;;
      esac
  done
}

# Parse the initial arguments.
while getopts $ARGS arg; do
  case ${arg} in
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

# Parse the primary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in
    e) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH="$(find "$ROOT" '(' -name "*$EA_NAME*.ex4" -o -name "*$EA_NAME*.ex5" ')' -print -quit)"
      [ -f "$EA_PATH" ]
      cp $VFLAG "$EA_PATH" "$TERMINAL_DIR/MQL4/Experts";
      ini_set "^TestExpert" "$(basename "${EA_PATH%.*}")" "$TESTER_INI"
      ;;
  esac
done

# Configure EA.
EA_NAME="$(ini_get TestExpert)"
EA_INI="$TESTER_DIR/$EA_NAME.ini"
cp $VFLAG "$TPL_EA" "$EA_INI"

# Parse the secondary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in
    r) # The name of the test report file. A relative path can be specified.
      echo "Setting test report..."
      if [ -s "$(dirname "${OPTARG}")" ]; then # If base folder exists,
        type realpath
        REPORT="$(realpath --relative-to="${TERMINAL_DIR}" "${OPTARG}")" # ... treat as relative path
      else
        REPORT="$(basename "${OPTARG}")" # ... otherwise, it's a filename.
      fi
      ini_set "^TestReport" "$REPORT" "$TESTER_INI"
      ;;

    f) # The .set file to run the test.
      echo "Setting EA parameters..."
      SETORG="$OPTARG"
      SETFILE="${EA_NAME}.set"
      [ -f "$SETORG" ]
      [ ! -f "$TESTER_DIR/$SETFILE" ] && cp -f $VFLAG "$OPTARG" "$TESTER_DIR/$SETFILE"
      ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
      ;;

    E) # EA settings (e.g. genetic=0, maxdrawdown=20.00).
      echo "Applying EA settings..."
      EA_OPTS=${OPTARG}
      IFS='=' ea_option=($in)
      [ -f "$EA_INI" ]
      ini_set "^${option[0]}" "${option[1]}" "$EA_INI"
      ;;

    c) # Base currency for test (e.g. USD).
      CURRENCY=${OPTARG}
      ini_set "^currency" "$CURRENCY" "$EA_INI"
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      echo "Setting symbol pair..."
      SYMBOL=${OPTARG}
      ini_set "^TestSymbol" "$SYMBOL" "$TESTER_INI"
      ;;

    d) # Deposit amount to test (e.g. 2000).
      echo "Setting deposit..."
      DEPOSIT=${OPTARG}
      ini_set "^deposit" "$DEPOSIT" "$EA_INI"
      ;;

    y) # Year to test (e.g. 2014).
      echo "Setting period to test..."
      YEAR=${OPTARG}
      ini_set "^TestFromDate" "$YEAR.01.01" "$TESTER_INI"
      ini_set "^TestToDate"   "$YEAR.12.30" "$TESTER_INI"
      ;;

    s) # Spread to test.
      echo "Setting spread to test..."
      SPREAD=${OPTARG}
      ini_set "^Spread" "$SPREAD" "$TERMINAL_INI"
      ini_set "^TestSpread" "$SPREAD" "$TESTER_INI"
      ;;

    o) # Run optimization test.
      echo "Setting optimization mode..."
      OPTIMIZATION=true
      ini_set "^TestOptimization" true "$TESTER_INI"
      ;;

    i) # Invoke file with custom rules.
      echo "Invoking includes..."
      INCLUDE=${OPTARG}
      SETFILE="$(ini_get TestExpert).set"
      [ -f "$TESTER_DIR/$SETFILE" ] || { echo "Please specify .set file first (-f)."; exit 1; }
      . "$INCLUDE"
      ;;

    C) # Clear previous backtest data files.
      clean_files
      clean_bt
      ;;

    b) # Backtest data to test.
      echo "Checking backtest data..."
      BT_SRC=${OPTARG}
      # Generate backtest files if not present.
      [ -s "$(find "$TERMINAL_DIR" -name '*.fxt' -print -quit)" ] || $SCR/get_bt_data.sh ${SYMBOL:-EURUSD} ${YEAR:-2014} ${BT_SRC:-N1}
      ;;

    t) # Convert Report files into text format.
      type html2text
      ;;

    D) # Destination directory to save the test results.
      DEST=${OPTARG}
      echo "Checking if destination exists..."
      [ -d "$DEST" ]
      ;;

    # Placeholders.
    e) ;;
    I) ;;
    v) ;;
    x) ;;

    \? | h | *) # Display help.
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
