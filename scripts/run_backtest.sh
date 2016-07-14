#!/usr/bin/env bash
# Script to run backtest test.
# E.g. run_backtest.sh -v -t -e MACD -f "/path/to/file.set" -c USD -p EURUSD -d 2000 -m 1-2 -y 2015 -s 20 -b DS -r Report -O "_optimization_results"
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS="b:c:C:d:D:e:E:f:Ghi:I:l:m:M:p:P:r:Rs:S:oO:tTvxX:y:"

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
  ! check_logs ".\+ not initialized" || exit 1
  ! check_logs ".\+ file error" || exit 1
  ! check_logs ".\+ data error" || exit 1
  ! check_logs "stop button .\+" || exit 1
  ! check_logs "Error: .\+" || exit 1
  ! check_logs "Configuration issue .\+" || exit 1
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

# Check the version of installed platform.
echo "Installed Terminal: $(filever terminal.exe)"
echo "Installed MetaEditor: $(filever metaeditor.exe)"

# Copy ini files.
copy_ini

# Parse the primary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    b) # Backtest data to test.
      BT_SRC=${OPTARG}
      ;;

    C) # Clear previous backtest data files.
      clean_files
      clean_bt
      ;;

    e) # EA name.
      EA_NAME=${OPTARG}
      EA_PATH=$(find_ea "$EA_NAME")
      ;;

    f) # The .set file to run the test.
      SETORG="$OPTARG"
      SETFILE="${EA_NAME}.set"
      ;;

    I) # Change tester INI file with custom settings.
      TEST_OPTS=${OPTARG}
      ;;

    m) # Which months to test (default: 1-12)
      IFS='-' MONTHS=(${OPTARG})
      IFS=$' \t\n' # Restore IFS.
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      SYMBOL=${OPTARG}
      ;;

    y) # Year to test (e.g. 2014).
      YEAR=${OPTARG}
      START_DATE="$YEAR.${MONTHS[0]:-01}.01"
      END_DATE="$YEAR.${MONTHS[1]:-$(echo ${MONTHS[0]:-12})}.30"
      ;;

  esac
done

if [ -n "$EA_PATH" ]; then
  [ -f "$EA_PATH" ] || { echo "Error: EA file ($EA_NAME) not found in '$ROOT'!" >&2; exit 1; }
  copy_ea "$EA_PATH"
  ini_set "^TestExpert" "$(basename "${EA_PATH%.*}")" "$TESTER_INI"
fi

if [ -n "$START_DATE" ]; then
  echo "Configuring start test period ($START_DATE)..." >&2
  ini_set "^TestFromDate" "$START_DATE" "$TESTER_INI"
fi
if [ -n "$END_DATE" ]; then
  echo "Configuring end test period ($END_DATE)..." >&2
  ini_set "^TestToDate"   "$END_DATE" "$TESTER_INI"
fi

if [ -n "$SYMBOL" ]; then
  echo "Configuring symbol pair ($SYMBOL)..." >&2
  ini_set "^TestSymbol" "$SYMBOL" "$TESTER_INI"
else
  SYMBOL="$(ini_get TestSymbol)"
fi

if [ -n "$TEST_OPTS" ]; then
  echo "Applying tester settings ($TEST_OPTS)..." >&2
  IFS=','; test_options=($TEST_OPTS); restore_ifs
  for opt_pair in "${test_options[@]}"; do
    IFS='='; test_option=($opt_pair); restore_ifs
    ini_set "^${test_option[0]}" "${test_option[1]}" "$TESTER_INI"
  done
fi

# Configure EA.
EA_NAME="$(ini_get TestExpert)"
SERVER="${SERVER:-$(ini_get Server)}"
EA_INI="$TESTER_DIR/$EA_NAME.ini"
SETFILE="${EA_NAME}.set"
cp $VFLAG "$TPL_EA" "$EA_INI"
copy_srv
check_files

if [ -n "$SETORG" ]; then
  if [ -f "$SETORG" ]; then
    echo "Configuring EA parameters ($SETFILE)..." >&2
    cp -f $VFLAG "$SETORG" "$TESTER_DIR/$SETFILE"
    ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
    ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
  else
    echo "ERROR: Set file not found ($SETORG)!" >&2
    exit 1
  fi
fi

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
      ;;

    d) # Deposit amount to test (e.g. 2000).
      DEPOSIT=${OPTARG}
      ;;

    D) # Change market digits.
      DIGITS=${OPTARG}
      ;;

    E) # EA backtest settings (e.g. genetic=0, maxdrawdown=20.00).
      EA_OPTS=${OPTARG}
      ;;

    i) # Invoke file with custom rules.
      INCLUDE=${OPTARG}
      ;;

    l) # Lot step.
      LOTSTEP=${OPTARG}
      ;;

    o) # Run optimization test.
      OPTIMIZATION=true
      ;;

    O) # Output directory to save the test results.
      DEST=${OPTARG}
      ;;

    P) # Period to test.
      PERIOD=${OPTARG}
      ;;

    r) # The name of the test report file.
      REPORT="tester/$(basename "${OPTARG}")"
      ;;

    R) # Set files to read-only.
      set_read_perms
      ;;

    s) # Spread to test.
      SPREAD=${OPTARG}
      ;;

    S) # Set EA option in SET file (e.g. VerboseInfo=1,TakeProfit=0).
      SET_OPTS=${OPTARG}
      ;;

    t)
      type html2text >&2
      ;;

    X)
      echo "Checking whether after test script exists..." >&2
      [ -f "$OPTARG" ] || { echo "ERROR: Script specified by -X parameter does no exist." >&2; exit 1; }
      ;;

    # Placeholders for parameters used somewhere else.
    b | C | e | f | G | h | I | m | M | p | v | x | y) ;;

    *) # Display help.
      echo "$0 usage:" >&2
      grep " .)\ #" "$0" >&2
      exit 0
      ;;

  esac
done

# Apply settings.
if [ -n "$INCLUDE" ]; then
  if [ -f "$TESTER_DIR/$SETFILE" ]; then
    type bc
    echo "Invoking include file ($INCLUDE)..." >&2
    ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
    . "$INCLUDE"
  else
    echo "ERROR: Please specify .set file first (-f)." >&2
    exit 1
  fi
fi
if [ -n "$EA_OPTS" ]; then
  echo "Applying EA settings ($EA_OPTS)..." >&2
  [ -f "$EA_INI" ]
  IFS=','; ea_options=($EA_OPTS); restore_ifs
  for opt_pair in "${ea_options[@]}"; do
    IFS='='; ea_option=($opt_pair); restore_ifs
    ini_set_ea "${ea_option[0]}" "${ea_option[1]}"
  done
fi
if [ -n "$CURRENCY" ]; then
  echo "Configuring base currency ($CURRENCY)..." >&2
  ini_set "^currency" "$CURRENCY" "$EA_INI"
fi
if [ -n "$DEPOSIT" ]; then
  echo "Configuring deposit ($DEPOSIT)..." >&2
  ini_set "^deposit" "$DEPOSIT" "$EA_INI"
fi
if [ -n "$DIGITS" ]; then
  echo "Configuring digits ($DIGITS)..." >&2
  set_digits $DIGITS
fi
if [ -n "$LOTSTEP" ]; then
  echo "Configuring lot step ($LOTSTEP)..." >&2
  set_lotstep $LOTSTEP
fi
if [ -n "$PERIOD" ]; then
  echo "Configuring period ($PERIOD)..." >&2
  ini_set "^TestPeriod" "$PERIOD" "$TESTER_INI"
fi
if [ -n "$REPORT" ]; then
  echo "Configuring test report ($REPORT)..." >&2
  ini_set "^TestReport" "$REPORT" "$TESTER_INI"
fi
if [ -n "$SPREAD" ]; then
  echo "Configuring spread ($SPREAD)..." >&2
  set_spread $SPREAD
fi
if [ -n "$SET_OPTS" ]; then
  echo "Setting EA options ($SET_OPTS)..." >&2
  [ -f "$TESTER_DIR/$SETFILE" ] || { echo "ERROR: Please specify .set file first (-f)." >&2; exit 1; }
  IFS=','; set_options=($SET_OPTS); restore_ifs
  for set_pair in "${set_options[@]}"; do
    IFS='='; set_option=($set_pair); restore_ifs
    input_set "${set_option[0]}" "${set_option[1]}"
  done
fi
if [ "$OPTIMIZATION" ]; then
  echo "Configuring optimization mode..." >&2
  ini_set "^TestOptimization" true "$TESTER_INI"
fi
if [ -n "$DEST" ]; then
  echo "Checking destination ($DEST)..." >&2
  [ -d "$DEST" ] || mkdir -p $VFLAG "$DEST"
fi

# Prepare before test run.
[ "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')' -size +1)" ] \
  || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
clean_files

# Run the test under the platform.
configure_display
live_logs &
echo "Testing..." >&2
(time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2> "$TERMINAL_LOG" && on_success $@ || on_failure $@
