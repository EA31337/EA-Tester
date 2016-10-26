#!/usr/bin/env bash
# Script to run MQL scripts.
# E.g. run_script.sh -v -e MACD -f "/path/to/file.set"
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS="b:B:c:C:d:D:e:E:f:hi:I:l:m:M:p:P:r:Rs:S:vxX:y:"

## Check dependencies.
type git pgrep xargs ex xxd xdpyinfo od perl > /dev/null

## Initialize.
. $CWD/.funcs.inc.sh
. $CWD/.vars.inc.sh
configure_display

## Define local functions.

# Invoke on test success.
on_success() {
  echo "Checking logs..." >&2
  show_logs
  ! check_logs "Initialization failed" || exit 1
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
  on_finish
  local OPTIND
  while getopts $ARGS arg; do
    case $arg in
      X) # Invoke file on exit after the successful run.
        echo "Invoking file after test..." >&2
        . "$OPTARG"
        ;;
      esac
  done
  exit 0
}

# Invoke on test failure.
on_failure() {
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

    B) # Specify early booting file.
      # @fixme: Won't work for paths with spaces.
      INCLUDE_BOOT+=(${OPTARG})
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
      ;;

    I) # Change tester INI file with custom settings (e.g. Server=MetaQuotes-Demo,Login=123).
      TEST_OPTS=${OPTARG}
      ;;

    m) # Which months to test (default: 1-12)
      MONTHS=${OPTARG}
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      SYMBOL=${OPTARG}
      ;;

    y) # Year to test (e.g. 2014).
      YEAR=${OPTARG}
      ;;

  esac
done

# Apply settings.
if [ -n "$INCLUDE_BOOT" ]; then
  echo "Invoking include booting file(s) (${INCLUDE_BOOT[@]})..." >&2
  for file in ${INCLUDE_BOOT[@]}; do
    [ -f "$INCLUDE_BOOT" ]
    . <(cat "$file")
  done
fi

if [ -n "$MONTHS" ]; then
  IFS='-' MONTHS=(${MONTHS})
  IFS=$' \t\n' # Restore IFS.
fi
if [ -n "$YEAR" ]; then
  START_DATE="$YEAR.${MONTHS[0]:-01}.01"
  END_DATE="$YEAR.${MONTHS[1]:-$(echo ${MONTHS[0]:-12})}.30"
fi

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
EA_NAME="$(ini_get Script)"
SERVER="${SERVER:-$(ini_get Server)}"
EA_INI="$TESTER_DIR/$EA_NAME.ini"
SETFILE="${EA_NAME}.set"
cp $VFLAG "$TPL_EA" "$EA_INI"
copy_srv
check_files

if [ -n "$SETORG" ]; then
  echo "Configuring script parameters ($SETFILE)..." >&2
  if [ -f "$SETORG" ]; then
    cp -f $VFLAG "$SETORG" "$TESTER_DIR/$SETFILE"
  fi
  if [ -f "$TESTER_DIR/$SETFILE" ]; then
    ini_set "^ScriptParameters" "$SETFILE" "$TESTER_INI"
    ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
  else
    echo "ERROR: Set file not found ($SETORG)!" >&2
    exit 1
  fi
fi

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
      # @fixme: Won't work for paths with spaces.
      INCLUDE+=(${OPTARG})
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
    b | B | C | e | f | G | h | I | m | M | p | v | x | y) ;;

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
    echo "Invoking include file(s) (${INCLUDE[@]})..." >&2
    ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
    for file in ${INCLUDE[@]}; do
      [ -f "$INCLUDE" ]
      . <(cat "$file")
    done
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

# Run the test under the platform.
live_logs &
echo "Testing..." >&2
(time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2> "$TERMINAL_LOG" && on_success $@ || on_failure $@