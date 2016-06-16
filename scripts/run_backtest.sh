#!/usr/bin/env bash
# Script to run backtest test.
# E.g. run_backtest.sh -v -t -e MACD -f "/path/to/file.set" -c USD -p EURUSD -d 2000 -m 1-2 -y 2015 -s 20 -b DS -r Report -O "_optimization_results"
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS=":r:Re:f:GE:c:p:d:D:m:M:y:b:s:l:oi:I:CtTO:vxX:h"

## Check dependencies.
type git pgrep xargs ex xxd xdpyinfo od perl > /dev/null

## Initialize.
. $CWD/.funcs.inc.sh
. $CWD/.vars.inc.sh

## Define local functions.

# Invoke on test success.
on_success() {
  echo "Checking logs..." >&2
  show_logs
  ! check_logs "Initialization failed" || exit 1
# ! check_logs "ExpertRemove" || exit 1
  ! check_logs "TestGenerator: .\+ not found" || exit 1
  ! check_logs ".\+ no history data" || { rm $VFLAG "$CUSTOM_INI"; exit 1; }
  ! check_logs ".\+ cannot start" || exit 1
  ! check_logs ".\+ cannot open" || exit 1
  ! check_logs ".\+ rate cannot" || exit 1 # E.g. Tester: exchange rate cannot be calculated
  ! check_logs "Error: .\+" || exit 1
  echo "TEST succeeded." >&2
  parse_results $@
  on_finish
  local OPTIND
  while getopts $ARGS arg; do
    case $arg in
      X) # Invoke file on exit after the successful test.
        echo "Invoking file after test..." >&2
        . "$OPTARG"
        ;;
      esac
  done
  exit 0
}

# Invoke on test failure.
on_failure() {
  echo "FAIL?!" >&2
  # Sometimes MT4 fails on success, therefore double checking.
  REPORT_HTM=$(find "$TESTER_DIR" -name "$(basename "$(ini_get TestReport)").htm")
  test -f "$REPORT_HTM" && on_success $@

  echo "Printing logs..." >&2
  show_logs
  echo "TEST failed." >&2
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
  REPORT_HTM=$(find "$TESTER_DIR" -name "${REPORT_BASE}.htm")
  test -f "$REPORT_HTM" || exit 1
  echo "Checking the total time elapsed..." >&2
  save_time
  while getopts $ARGS arg; do
    case $arg in
      t) # Convert test report file into brief text format.
        REPORT_TXT="$(dirname "$REPORT_HTM")/$REPORT_BASE.txt"
        echo "Converting HTML report ($(basename "$REPORT_HTM")) into short text file ($(basename "$REPORT_TXT"))..." >&2
        grep -v mso-number "$REPORT_HTM" | html2text -nobs -width 105 | sed "/\[Graph\]/q" | grep -v '^\s.*;' > "$REPORT_TXT"
        ;;
      T) # Convert test report file into full detailed text format.
        REPORT_TXT="$(dirname "$REPORT_HTM")/$REPORT_BASE.txt"
        echo "Converting full HTML report ($(basename "$REPORT_HTM")) into short text file ($(basename "$REPORT_TXT"))..." >&2
        grep -v mso-number "$REPORT_HTM" | html2text -nobs -width 105 -o "$REPORT_TXT"
        ;;
      G) # Enhance gif report files.
        REPORT_GIF="$(dirname "$REPORT_HTM")/$REPORT_BASE.gif"
        echo "Enhancing report image ($REPORT_BASE.gif)..." >&2
        enhance_gif "$REPORT_GIF"
        ;;
      O)
        DEST="${DEST:-$(echo $CWD)}"
        echo "Copying report files ($REPORT_BASE.* into: $DEST)..." >&2
        cp $VFLAG "$TESTER_DIR/$REPORT_BASE".* "$DEST"
        find "$TESTER_DIR/files" -type f $VPRINT -exec cp $VFLAG "{}" "$DEST" ';'
        ;;
      v)
        echo "Printing test report ($(basename "$REPORT_HTM"))..." >&2
        grep -v mso-number "$REPORT_HTM" | html2text -nobs -width 180 | sed "/\[Graph\]/q"
        find "$TESTER_DIR/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" +
        ;;
      o)
        echo "Saving optimization results..."
        if [ -z "$input_values" ]; then
          for input in ${param_list[@]}; do
            value=$(ini_get "$input" "$REPORT_HTM")
            echo "Setting '$input' to '$value' in '$(basename $SETORG)'" >&2
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

    h | \?) # Display help.
      echo "$0 usage:" >&2
      grep " .)\ #" "$0" >&2
      exit 0
      ;;

    M) # Specify version of MetaTrader.
      MT_VER=${OPTARG:-4x}
      type unzip 2> /dev/null
      configure_display
      install_mt $MT_VER
      . $CWD/.vars.inc.sh # Reload variables.
      ;;

    v) # Verbose mode.
      VERBOSE=1
      VFLAG="-v"
      VPRINT="-print"
      VDD="noxfer"
      type html2text sed >&2
      ;;

    x) # Run the script in debug mode.
      TRACE=1
      set -x
      ;;

  esac
done

# Check if terminal is present, otherwise install it.
echo "Checking platform..." >&2
[ "$TERMINAL_EXE" ] \
  || { echo "Error: Terminal not found, please specify -M parameter with version to install it." >&2; exit 1; }

# Re-load variables.
. $CWD/.vars.inc.sh

# Copy ini files.
copy_ini

# Parse the primary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    e) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH=$(find_ea "$EA_NAME")
      [ -f "$EA_PATH" ] || { echo "Error: EA file ($EA_NAME) not found in '$ROOT'!" >&2; exit 1; }
      copy_ea "$EA_PATH"
      ini_set "^TestExpert" "$(basename "${EA_PATH%.*}")" "$TESTER_INI"
      ;;

    C) # Clear previous backtest data files.
      clean_files
      clean_bt
      ;;

    m) # Which months to test (default: 1-12)
      IFS='-' MONTHS=(${OPTARG})
      IFS=$' \t\n' # Restore IFS.
      ;;

  esac
done

# Parse the secondary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    b) # Backtest data to test.
      BT_SRC=${OPTARG}
      ;;

    y) # Year to test (e.g. 2014).
      YEAR=${OPTARG}
      START_DATE="$YEAR.${MONTHS[0]:-01}.01"
      END_DATE="$YEAR.${MONTHS[1]:-$(echo ${MONTHS[0]:-12})}.30"
      echo "Configuring test period ($START_DATE-$END_DATE)..." >&2
      ini_set "^TestFromDate" "$START_DATE" "$TESTER_INI"
      ini_set "^TestToDate"   "$END_DATE" "$TESTER_INI"
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      SYMBOL=${OPTARG}
      echo "Configuring symbol pair ($SYMBOL)..." >&2
      ini_set "^TestSymbol" "$SYMBOL" "$TESTER_INI"
      ;;

    I) # Change tester INI file with custom settings.
      TEST_OPTS=${OPTARG}
      echo "Applying tester settings ($TEST_OPTS)..." >&2
      IFS=','; test_options=($TEST_OPTS); restore_ifs
      for opt_pair in "${test_options[@]}"; do
        IFS='='; test_option=($opt_pair); restore_ifs
        ini_set "^${test_option[0]}" "${test_option[1]}" "$TESTER_INI"
      done
      ;;

  esac
done


# Parse the tertiary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in
    # todo
  esac
done

# Configure EA.
EA_NAME="$(ini_get TestExpert)"
SYMBOL="$(ini_get TestSymbol)"
SERVER="$(ini_get Server)"
EA_INI="$TESTER_DIR/$EA_NAME.ini"
cp $VFLAG "$TPL_EA" "$EA_INI"
copy_srv
check_files

# Download backtest data if needed.
echo "Checking backtest data (${BT_SRC:-DS})..."
bt_key="${SYMBOL:-EURUSD}-${YEAR:-2014}-${BT_SRC:-DS}"
# Generate backtest files if not present.
if [ ! "$(find "$TERMINAL_DIR" -name '*.fxt' -print -quit)" ] || [ "$(ini_get "bt_data" "$CUSTOM_INI")" != "$bt_key" ]; then
  env SERVER=$SERVER $SCR/get_bt_data.sh ${SYMBOL:-EURUSD} ${YEAR:-2014} ${BT_SRC:-DS}
fi

# Assign variables.
FXT_FILE=$(find "$TICKDATA_DIR" -name "*.fxt" -print -quit)

# Parse the main arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    c) # Base currency for test (e.g. USD).
      CURRENCY=${OPTARG}
      echo "Configuring base currency ($CURRENCY)..." >&2
      ini_set "^currency" "$CURRENCY" "$EA_INI"
      ;;

    d) # Deposit amount to test (e.g. 2000).
      DEPOSIT=${OPTARG}
      echo "Configuring deposit ($DEPOSIT)..." >&2
      ini_set "^deposit" "$DEPOSIT" "$EA_INI"
      ;;

    D) # Change market digits.
      DIGITS=${OPTARG}
      echo "Configuring digits ($DIGITS)..." >&2
      set_digits $DIGITS
      ;;

    E) # EA backtest settings (e.g. genetic=0, maxdrawdown=20.00).
      EA_OPTS=${OPTARG}
      echo "Applying EA settings ($EA_OPTS)..." >&2
      IFS='='; ea_option=($EA_OPTS)
      IFS=$' \t\n' # Restore IFS.
      [ -f "$EA_INI" ]
      ini_set_ea "^${ea_option[0]}" "${ea_option[1]}"
      ;;

    f) # The .set file to run the test.
      SETORG="$OPTARG"
      SETFILE="${EA_NAME}.set"
      echo "Configuring EA parameters ($SETFILE)..." >&2
      [ -f "$SETORG" ] || { echo "ERROR: Set file not found!" >&2; exit 1; }
      cp -f $VFLAG "$OPTARG" "$TESTER_DIR/$SETFILE"
      ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
      ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
      ;;

    i) # Invoke file with custom rules.
      type bc
      INCLUDE=${OPTARG}
      SETFILE="$(ini_get TestExpert).set"
      [ -f "$TESTER_DIR/$SETFILE" ] || { echo "ERROR: Please specify .set file first (-f)." >&2; exit 1; }
      echo "Invoking include file ($INCLUDE)..." >&2
      ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
      . "$INCLUDE"
      ;;

    l) # Lot step.
      LOTSTEP=${OPTARG}
      echo "Configuring lot step ($LOTSTEP)..." >&2
      set_lotstep $LOTSTEP
      ;;

    o) # Run optimization test.
      OPTIMIZATION=true
      echo "Configuring optimization mode..." >&2
      ini_set "^TestOptimization" true "$TESTER_INI"
      ;;

    O) # Output directory to save the test results.
      DEST=${OPTARG}
      echo "Checking destination ($DEST)..." >&2
      [ -d "$DEST" ] || mkdir -p $VFLAG "$DEST"
      ;;

    r) # The name of the test report file.
      REPORT="tester/$(basename "${OPTARG}")"
      echo "Configuring test report ($REPORT)..." >&2
      ini_set "^TestReport" "$REPORT" "$TESTER_INI"
      ;;

    R) # Set files to read-only.
      set_read_perms
      ;;

    s) # Spread to test.
      SPREAD=${OPTARG}
      echo "Configuring spread ($SPREAD)..." >&2
      set_spread $SPREAD
      ;;

    t)
      type html2text >&2
      ;;

    # Placeholders for parameters used somewhere else.
    e | h | G | m | M | p | y | C | b | I | v | x) ;;

    *) # Display help.
      echo "$0 usage:" >&2
      grep " .)\ #" "$0" >&2
      exit 0
      ;;

  esac
done

# Prepare before test run.
[ "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')' -size +1)" ] \
  || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
clean_files

# Run the test under the platform.
configure_display
live_logs &
echo "Testing..." >&2
(time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2> "$TERMINAL_LOG" && on_success $@ || on_failure $@
