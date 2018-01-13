#!/usr/bin/env bash
# Script to run backtest test.
# E.g. run_backtest.sh -v -t -e MACD -f "/path/to/file.set" -c USD -p EURUSD -d 2000 -m 1-2 -y 2015 -s 20 -b DS -r Report -O "_optimization_results"
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS="A:b:B:c:Cd:D:e:E:f:Ghi:I:l:m:M:p:P:r:Rs:S:oO:tTvVxX:y:"

## Check dependencies.
type git pgrep xargs ex xxd od perl > /dev/null

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
# ! check_logs "ExpertRemove" || exit 1
  ! check_logs "TestGenerator: .\+ not found" || exit 1
  ! check_logs ".\+ no history data" || { rm $VFLAG "$CUSTOM_INI"; exit 1; }
  ! check_logs ".\+ cannot start" || exit 1
  ! check_logs ".\+ cannot open" || exit 1
  ! check_logs ".\+ rate cannot" || exit 1 # E.g. Tester: exchange rate cannot be calculated
  ! check_logs ".\+ not initialized" || exit 1
  ! check_logs ".\+ file error" || exit 1
  ! check_logs ".\+ data error" || exit 1
  ! check_logs ".\+ deficient data" || exit 1
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
      G) # Enhance gif report files.
        REPORT_GIF="$(dirname "$REPORT_HTM")/$REPORT_BASE.gif"
        echo "Enhancing report image ($REPORT_BASE.gif)..." >&2
        enhance_gif "$REPORT_GIF" ${GIF_ENHANCE:-"-n"}
        if [ -f "$REPORT_TXT" ]; then
          local gif_text=$(grep -wE '^\s*(Symbol|Period|Bars|Initial|Total|Profit|Absolute)' "$REPORT_TXT")
          enhance_gif "$REPORT_GIF" -t "$gif_text"
        fi
        ;;
      t) # Convert test report file into brief text format.
        REPORT_TXT="$(dirname "$REPORT_HTM")/$REPORT_BASE.txt"
        echo "Converting HTML report ($(basename "$REPORT_HTM")) into short text file ($(basename "$REPORT_TXT"))..." >&2
        convert_html2txt "$REPORT_HTM" "$REPORT_TXT"
        ;;
      T) # Convert test report file into full detailed text format.
        REPORT_TXT="$(dirname "$REPORT_HTM")/$REPORT_BASE.txt"
        echo "Converting full HTML report ($(basename "$REPORT_HTM")) into short text file ($(basename "$REPORT_TXT"))..." >&2
        convert_html2txt_full "$REPORT_HTM" "$REPORT_TXT"
        ;;
      O)
        DEST="${DEST:-$CWD}"
        echo "Copying report files ($REPORT_BASE.* into: $DEST)..." >&2
        [ -d "$DEST" ] || mkdir $VFLAG "$DEST"
        cp $VFLAG "$TESTER_DIR/$REPORT_BASE".* "$DEST"
        find "$TESTER_DIR/files" -type f $VPRINT -exec cp $VFLAG "{}" "$DEST" ';'
        ;;
      o)
        echo "Sorting test results..."
        if [ "${MT_VER%%.*}" -ne 5 ]; then
          # Note: To display sorted results, -o needs to be specified before -v.
          sort_opt_results "$REPORT_HTM"
        fi
        echo "Saving optimization results..."
        if [ -z "$input_values" ]; then
          for input in ${param_list[@]}; do
            value=$(ini_get "$input" "$REPORT_HTM")
            echo "Setting '$input' to '$value' in '$(basename $SETORG)'" >&2
            ini_set "^$input" "$value" "$SETORG"
          done
        fi
        ;;
      v)
        echo "Printing test report ($(basename "$REPORT_HTM"))..." >&2
        grep -v mso-number "$REPORT_HTM" | html2text -nobs -width 180 | sed "/\[Graph\]/q"
        find "$TESTER_DIR/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" +
        ;;
      *)
        ignores="$arg=$OPTARG"
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
      install_mt $MT_VER
      . $CWD/.vars.inc.sh # Reload variables.
      validate_dirs
      ;;

    v) # Verbose mode.
      VERBOSE=1
      VFLAG="-v"
      VPRINT="-print"
      VDD="noxfer"
#EXFLAG="-V1" # @see: https://github.com/vim/vim/issues/919
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
  || {
    echo "ERROR: Terminal not found, please specify -M parameter with version to install it." >&2;
    [ -n "$VERBOSE" ] && grep ^TERMINAL <(set)
    exit 1;
  }

# Re-load variables.
. $CWD/.vars.inc.sh

# Check the version of installed platform.
MT_VER=$(filever terminal.exe)
MTE_VER=$(filever metaeditor.exe)
echo "Installed Terminal: $MT_VER"
echo "Installed MetaEditor: $MTE_VER"

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
      INCLUDE_BOOT+=("${OPTARG}")
      ;;

    C) # Clear previous backtest data files.
      clean_files
      clean_bt
      ;;

    e) # EA name.
      EA_NAME=${OPTARG}
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

    y) # Year to test (e.g. 2014, 2011-2015).
      YEARS=${OPTARG}
      ;;

  esac
done

# Apply settings.
if [ -n "$INCLUDE_BOOT" ]; then
  echo "Invoking include booting file(s) (${INCLUDE_BOOT[@]})..." >&2
  for file in "${INCLUDE_BOOT[@]}"; do
    [ -f "$INCLUDE_BOOT" ]
    . <(cat "$file")
  done
fi

if [ -n "$BOOT_CODE" ]; then
  echo "Evaluating boot code ($BOOT_CODE)..." >&2
  eval "$BOOT_CODE"
fi

if [ -n "$MONTHS" ]; then
  IFS='-' MONTHS=(${MONTHS})
  restore_ifs
fi
if [ -n "$YEARS" ]; then
  IFS='-' YEARS=(${YEARS})
  restore_ifs
fi
if [ -n "$YEARS" ]; then
  START_DATE="${YEARS[0]}.${MONTHS[0]:-01}.01"
  END_DATE="${YEARS[1]:-$(echo ${YEARS[0]})}.${MONTHS[1]:-$(echo ${MONTHS[0]:-12})}.31"
fi

if [ -n "$EA_NAME" ]; then
  EA_PATH=$(find_ea "$EA_NAME")
  [ -f "$EA_PATH" ] || { echo "Error: EA file ($EA_NAME) not found in '$ROOT'!" >&2; exit 1; }
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
SCR_NAME="$(ini_get Script)"
SERVER="${SERVER:-$(ini_get Server)}"
SETFILE="${EA_NAME:-$SCR_NAME}.set"

if [ "$EA_NAME" ]; then
  EA_INI="$TESTER_DIR/$EA_NAME.ini"
  cp $VFLAG "$TPL_EA" "$EA_INI"
fi

# Copy EA.
if [ -n "$EA_PATH" ]; then
  copy_ea "$EA_PATH"
fi

if [ "$SCR_NAME" ]; then
  SCR_INI="$SCRIPTS_DIR/$SCR_NAME.ini"
  cp $VFLAG "$TPL_SCR" "$SCR_INI"
  SCR_PATH=$(find_ea "$SCR_NAME")
  copy_script "$SCR_PATH"
fi

if [ -n "$SETORG" ]; then
  echo "Configuring SET parameters ($SETFILE)..." >&2
  if [ -f "$SETORG" ]; then
    cp -f $VFLAG "$SETORG" "$TESTER_DIR/$SETFILE"
  fi
  if [ -f "$TESTER_DIR/$SETFILE" ]; then
    ini_set "^TestExpertParameters" "$SETFILE" "$TESTER_INI"
    echo "Copying parameters from SET into INI file..." >&2
    ini_set_inputs "$TESTER_DIR/$SETFILE" "$EA_INI"
  else
    echo "ERROR: Set file not found ($SETORG)!" >&2
    exit 1
  fi
fi

copy_srv
check_files

# Parse the main arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    A) # Action to evaluate (e.g. "dl_file URL")
      CODE+=("${OPTARG}")
      ;;

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
      INCLUDE+=("${OPTARG}")
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

    V) # Enables visual mode.
      VISUAL_MODE=1
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
  echo "Invoking include file(s) (${INCLUDE[@]})..." >&2
  for file in ${INCLUDE[@]}; do
    [ -f "$INCLUDE" ]
    . <(cat "$file")
  done
fi

# Configure test period.
if [ -n "$PERIOD" ]; then
  echo "Configuring test period ($PERIOD)..." >&2
  ini_set "^TestPeriod" "$PERIOD" "$TESTER_INI"
fi

# Action(s) to evaluate.
if [ -n "$CODE" ]; then
  for code in "${CODE[@]}"; do
    echo "Evaluating action ($code)..." >&2
    eval "$code"
  done
fi
if [ -n "$EA_OPTS" ]; then
  echo "Applying EA backtest settings ($EA_OPTS)..." >&2
  [ -f "$EA_INI" ]
  IFS=','; ea_options=($EA_OPTS); restore_ifs
  for opt_pair in "${ea_options[@]}"; do
    IFS='='; ea_option=($opt_pair); restore_ifs
    ini_set_ea "${ea_option[0]}" "${ea_option[1]}"
  done
fi
if [ -n "$SET_OPTS" ]; then
  echo "Setting EA options ($SET_OPTS)..." >&2
  [ -f "$TESTER_DIR/$SETFILE" ] || { echo "ERROR: Please specify .set file first (-f)." >&2; exit 1; }
  IFS=','; set_options=($SET_OPTS); restore_ifs
  for set_pair in "${set_options[@]}"; do
    IFS='='; set_option=($set_pair); restore_ifs
    input_set "${set_option[0]}" "${set_option[1]}"
    ini_set_ea "${set_option[0]}" "${set_option[1]}"
  done
  if [ "$VERBOSE" -gt 0 ]; then
    # Print final version of SET file in compressed base64 format for debug purposes.
    # Note: Read by: printf "FOO" | base64 -d | gunzip -d > file.set
    echo "Final SET: $(grep -v ,.= "$TESTER_DIR/$SETFILE" | gzip -9c | base64 -w0)" >&2
  fi
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
if [ -n "$REPORT" ]; then
  echo "Configuring test report ($REPORT)..." >&2
  ini_set "^TestReport" "$REPORT" "$TESTER_INI"
fi
if [ -n "$SPREAD" ]; then
  echo "Configuring spread ($SPREAD)..." >&2
  set_spread $SPREAD
fi
if [ "$OPTIMIZATION" ]; then
  echo "Configuring optimization mode..." >&2
  ini_set "^TestOptimization" true "$TESTER_INI"
fi
if [ -n "$DEST" ]; then
  echo "Checking destination ($DEST)..." >&2
  [ -d "$DEST" ] || mkdir -p $VFLAG "$DEST"
fi
if [ "$VISUAL_MODE" ]; then
  echo "Enabling visual mode..." >&2
  ini_set "^TestVisualEnable" true "$TESTER_INI"
fi

PERIOD=$(ini_get ^TestPeriod)
if [ "$EA_NAME" ]; then
  # Download backtest data if needed.
  echo "Checking backtest data (${BT_SRC:-DS})..."
  bt_key="${SYMBOL:-EURUSD}-$(join_by - ${YEARS[@]:-2015})-${BT_SRC:-DS}"
  # Generate backtest files if not present.
  if [ ! "$(find "$TERMINAL_DIR" -name "${SYMBOL:-EURUSD}*_0.fxt" -print -quit)" ] || [ "$(ini_get "bt_data" "$CUSTOM_INI")" != "$bt_key" ]; then
    env SERVER=$SERVER VERBOSE=$VERBOSE TRACE=$TRACE \
      $SCR/get_bt_data.sh ${SYMBOL:-EURUSD} "$(join_by - ${YEARS[@]:-2015})" ${BT_SRC:-DS} ${PERIOD}
  fi
# Assign variables.
  FXT_FILE=$(find "$TICKDATA_DIR" -name "*.fxt" -print -quit)
fi

# Prepare before test run.
if [ "$EA_NAME" ]; then
  [ "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')' -size +1)" ] \
    || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
fi
clean_files

# Run the test under the platform.
live_logs &
live_stats &
echo "Testing..." >&2
(time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2>> "$TERMINAL_LOG" && on_success $@ || on_failure $@
echo "$0 done"
