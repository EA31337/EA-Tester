#!/usr/bin/env bash
# Script to run backtest test.
# E.g. run_backtest.sh -v -t -e MACD -f "/path/to/file.set" -c USD -p EURUSD -d 2000 -m 1-2 -y 2019 -s 20 -b DS -r Report -O "_optimization_results"

# Initialize variables.
[ -n "$OPT_NOERR" ] || set -eE
[ -n "$OPT_TRACE" ] && set -x
CWD="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ARGS="45?b:B:c:Cd:D:e:E:f:FgGi:I:jl:L:m:M:p:P:r:Rs:S:oO:tT:vVxX:y:_"

# Check dependencies.
type git pgrep xargs ex xxd od perl xdpyinfo > /dev/null

## Define local functions. ##

# Show script usage and exit.
usage()
{
  printf "Usage: %s (args)\n\n" "$0"
  cat $CWD/options.txt
  printf "\n\nExample: %s -v -t -e MACD -p EURUSD -c USD -d 2000 -y 2019 -m 1-2 -S 20 -b DS -T M30\n" "$0"
}

# Invoke on test success.
on_success()
{

  # Fail on error in the logs.
  echo "INFO: Checking logs for warnings and errors..."
  check_log_errors
  if [ $? -ne 0 ]; then
    echo "ERROR: RUN failed with errors."
    on_fail
    on_error 1
  fi

  check_log_warns
  if [ $? -ne 0 ]; then
    echo "ERROR: RUN failed with warnings."
    on_warn
    on_fail
    on_error 1
  fi

  echo "INFO: RUN succeeded."
  show_logs
  parse_results $@
  on_finish
  local OPTIND
  # Invoke custom code on success.
  if [ -n "$RUN_ON_SUCCESS" ]; then
    echo "INFO: Running code on success ($RUN_ON_SUCCESS)..."
    eval "$RUN_ON_SUCCESS"
  fi
  while getopts $ARGS arg; do
    case $arg in
      X) # Invoke file on exit after the successful test.
        echo "INFO: Invoking script file after test..."
        . "$OPTARG"
        ;;
    esac
  done
  # Set exit status to 0.
  exit_status=0
}

# Invoke on test failure.
on_failure()
{
  echo "WARN: Something went wrong, a non-zero exit code returned."
  # Sometimes MT4 fails on success, therefore double checking.
  TEST_REPORT_BASE="$(basename "$(ini_get TestReport)" .htm)"

  if [ -n "$TEST_REPORT_BASE" ]; then
    TEST_REPORT_HTM=$(find "$TESTER_DIR" "$TERMINAL_DIR" -maxdepth 2 -name "${TEST_REPORT_BASE//[][]/?}*.htm" -print -quit)
    test -f "$TEST_REPORT_HTM" && {
      on_success $@
      return
    }
  elif [ -z "$TEST_EXPERT" -a -n "$SCRIPT" ]; then
    # Report success when script was run and platform killed.
    log_file="$(find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
    grep -w -C1 "uninit reason 0" "$log_file" && {
      on_success $@
      return
    }
  fi

  echo "INFO: Printing logs..."
  show_logs
  echo "ERROR: RUN failed."
  on_fail
  on_finish
}

# Parse report files.
parse_results()
{
  TEST_REPORT_BASE="$(basename "$(ini_get TestReport)" .htm)"

  echo "INFO: Checking the total time elapsed..."
  save_time

  # Ignore if no test results or test expert name is set (e.g. when running the script).
  [ -z "$TEST_REPORT_BASE" -o -z "$TEST_EXPERT" ] && return

  # Locate the report file.
  TEST_REPORT_HTM=$(find "$TESTER_DIR" "$TERMINAL_DIR" -maxdepth 2 -name "${TEST_REPORT_BASE//[][]/?}*.htm" -print -quit)
  TEST_REPORT_DIR="$(dirname "$TEST_REPORT_HTM")"
  test -d "$TEST_REPORT_DIR" || on_error 1
  test -f "$TEST_REPORT_HTM" || on_error 1

  if [ -n "$OPT_FORMAT_JSON" ]; then
    # Convert test report file into JSON format.
    echo "INFO: Converting HTML report ($TEST_REPORT_DIR) into JSON file..."
    convert_html2json "$TEST_REPORT_HTM"
  fi

  if [ -n "$OPT_OPTIMIZATION" ]; then
    # Parse and save the optimization test results.
    echo "INFO: Sorting optimization test results..."
    if [ "${MT_VER:0:1}" = 4 ]; then
      sort_opt_results "$TEST_REPORT_HTM"
    fi
    echo "INFO: Saving optimization results..."
    if [ -n "${param_list[*]}" ] || [ -n "$SET_PARAMS" ]; then
      if [ -z "${param_list[*]}" ]; then
        IFS=',' param_list=(${SET_PARAMS})
        restore_ifs
      fi
      for input in ${param_list[@]}; do
        value=$(htm_get "$input" "$TEST_REPORT_HTM")
        echo "INFO: Setting '$input' to '$value' in '$(basename $SETFILE)'"
        ini_set "^$input" "$value" "$SETFILE"
      done
    fi
  fi

  if [ -n "$OPT_FORMAT_FULL" ]; then
    # Convert test report file to full detailed text format.
    TEST_REPORT_TXT="$TEST_REPORT_DIR/$TEST_REPORT_BASE.txt"
    echo "INFO: Converting HTML report ($(basename "$TEST_REPORT_HTM")) into full text file ($(basename "$TEST_REPORT_TXT"))..."
    convert_html2txt_full "$TEST_REPORT_HTM" "$TEST_REPORT_TXT"
  elif [ -n "$OPT_FORMAT_BRIEF" ]; then
    # Convert test report file into brief text format.
    TEST_REPORT_TXT="$TEST_REPORT_DIR/$TEST_REPORT_BASE.txt"
    echo "INFO: Converting HTML report ($(basename "$TEST_REPORT_HTM")) into short text file ($(basename "$TEST_REPORT_TXT"))..."
    convert_html2txt "$TEST_REPORT_HTM" "$TEST_REPORT_TXT"
  fi

  if [ -n "$OPT_GIF_ENHANCE" ]; then
    # Enhance gif report files.
    report_gif="$TEST_REPORT_DIR/$TEST_REPORT_BASE.gif"
    echo "INFO: Enhancing report image ($TEST_REPORT_BASE.gif)..."
    enhance_gif "$report_gif" ${GIF_ENHANCE:-"-n"}
    if [ -f "$TEST_REPORT_TXT" ]; then
      local gif_text=$(grep -wE '^\s*(Symbol|Period|Bars|Initial|Total|Profit|Absolute)' "$TEST_REPORT_TXT")
      enhance_gif "$report_gif" -t "$gif_text"
    fi
  fi

  if [ -n "$OPT_VERBOSE" ]; then
    # Print test results in plain text.
    echo "INFO: Printing test report ($(basename "$TEST_REPORT_HTM"))..."
    grep -v mso-number "$TEST_REPORT_HTM" | html2text -nobs -width 180 | sed "/\[Graph\]/q"
    find "$TESTER_DIR/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" +
  fi

  if [ -d "$BT_DEST" ]; then
    # Copy the test results if the destination directory has been specified.
    echo "INFO: Copying report files (${TEST_REPORT_HTM%.*}* into: $BT_DEST)..."
    cp $VFLAG "${TEST_REPORT_HTM%.*}"* "$BT_DEST"
    [ -f "$TESTER_LOGS/$(date +%Y%m%d).log" ] && cp $VFLAG "$TESTER_LOGS/$(date +%Y%m%d).log" "$BT_DEST/${TEST_REPORT_BASE}.log"
    find "$TESTER_DIR/files" -type f $VPRINT -exec cp $VFLAG "{}" "$BT_DEST" ';'
  fi

  if [ -n "$OPT_GIST" ]; then
    # Post results to Gist if set.
    [ -n "$OPT_TRACE" ] && set +x
    post_gist "${BT_DEST:-$TEST_REPORT_DIR}" "$TEST_REPORT_BASE"
    [ -n "$OPT_TRACE" ] && set -x
  fi
  result_summary
}

# Show usage on no arguments.
[ $# -eq 0 ] && {
  usage
  exit 0
}

# Parse the initial arguments.
while getopts $ARGS arg; do
  case ${arg} in

    \?) # Display help.
      usage
      exit 0
      ;;

    4) # MT4
      MT_VER=4
      ;;

    5) # MT5
      MT_VER=5
      ;;

    M) # Specify version of MetaTrader (e.g. 4, 4x, 5, 4.0.0.1010).
      MT_VER=${OPTARG:-4.0.0.1010}
      ;;

    v) # Verbose mode.
      OPT_VERBOSE=true
      VFLAG="-v"
      VPRINT="-print"
      VDD="noxfer"
      # EX_ARGS="-V1" # @see: https://github.com/vim/vim/issues/919
      type html2text sed > /dev/null
      ;;

    x) # Run the script in debug mode.
      OPT_TRACE=1
      ;;

  esac
done

[ -n "$NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && {
  set -x
  EX_ARGS="${EX_ARGS:-"-V1"}"
}

# Invoke includes.
. "$CWD"/.aliases.inc.sh
. "$CWD"/.funcs.inc.sh
. "$CWD"/.funcs.cmds.inc.sh
. "$CWD"/.funcs.sets.inc.sh
. "$CWD"/.vars.inc.sh

# Initialize.
initialize

# Check if MT version has been specified.
if [ -n "$MT_VER" ] && [ ${#MT_VER} -gt 8 ]; then
  # Install MT platform.
  type unzip > /dev/null
  install_mt $MT_VER
  . "$CWD"/.vars.inc.sh # Reload variables.
  check_dirs
fi

# Check if terminal is present, otherwise install it.
echo "INFO: Checking platform..."
if [ -f "$TERMINAL_EXE" ]; then
  # Check required directories.
  check_dirs
else
  [ -n "$OPT_VERBOSE" ] && grep ^TERMINAL <(set) | xargs
  echo "ERROR: Terminal not found, please specify -M parameter with version to install it."
  on_error 1
fi

# Enter platform directory.
cd "$TERMINAL_DIR"

# Check the version of installed platform.
print_ver

# Copy ini files.
ini_copy

# Parse the primary arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    b) # Source of backtest data to test.
      BT_SRC=${OPTARG}
      ;;

    B) # Specify early booting file.
      # @fixme: Won't work for paths with spaces.
      INCLUDE_BOOT+=("${OPTARG}")
      ;;

    C) # Clear previous backtest data files.
      clean_bt
      ;;

    e) # EA name (TestExpert).
      TEST_EXPERT=${OPTARG}
      ;;

    E) # EA name (Expert).
      EXPERT=${OPTARG}
      ;;

    f) # The .set file to run the test.
      SETFILE="$(eval echo "$OPTARG")"
      ;;

    I) # Change tester INI file with custom settings (e.g. Server=MetaQuotes-Demo,Login=123).
      TEST_OPTS=${OPTARG}
      ;;

    m) # Which months to test (default: 1-12).
      BT_MONTHS=${OPTARG}
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      BT_SYMBOL=${OPTARG}
      ;;

    s) # Script to run.
      SCRIPT=${OPTARG}
      ;;

    y) # Year to test (e.g. 2018, 2019, 2011-2015).
      BT_YEARS=${OPTARG}
      ;;

  esac
done

# Apply settings.
if [ -n "$INCLUDE_BOOT" ]; then
  echo "INFO: Invoking include booting file(s) (${INCLUDE_BOOT[@]})..."
  for file in "${INCLUDE_BOOT[@]}"; do
    [ -f "$INCLUDE_BOOT" ]
    . <(cat "$file")
  done
fi

# Invoke boot code.
if [ -n "$RUN_ON_START" ]; then
  echo "INFO: Running code on startup ($RUN_ON_START)..."
  eval "$RUN_ON_START"
fi

if [ -n "$BT_DAYS" ]; then
  IFS='-' BT_DAYS=(${BT_DAYS})
  restore_ifs
fi
if [ -n "$BT_MONTHS" ]; then
  IFS='-' BT_MONTHS=(${BT_MONTHS})
  restore_ifs
fi
if [ -n "$BT_YEARS" ]; then
  IFS='-' BT_YEARS=(${BT_YEARS})
  restore_ifs
fi
if [ -n "$BT_YEARS" ]; then
  BT_START_DATE="${BT_YEARS[0]}.${BT_MONTHS[0]:-01}.${BT_DAYS[0]:-01}"
  BT_END_DATE="${BT_YEARS[1]:-$(echo ${BT_YEARS[0]})}.${BT_MONTHS[1]:-$(echo ${BT_MONTHS[0]:-12})}.${BT_DAYS[1]:-$(echo ${BT_DAYS[0]:-31})}"
fi

# Locate the main file to execute.
if [ -n "$TEST_EXPERT" ]; then
  # Locate TestExpert if specified.
  echo "INFO: Locating TestExpert file ($TEST_EXPERT)..."
  cd "$EXPERTS_DIR"
  EA_PATH=$(ea_find "$TEST_EXPERT")
  if [ -f "$EA_PATH" ]; then
    echo "INFO: TestExpert file found at: $EA_PATH"
  else
    echo "ERROR: TestExpert file ($TEST_EXPERT) not found!"
    on_error 1
  fi
  if [ "${EA_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    ea_copy "$EA_PATH"
    EA_PATH=$(ea_find "$TEST_EXPERT")
  fi
  # Use relative path to Experts dir.
  ini_set "^TestExpert" "${EA_PATH%.*}" "$TESTER_INI"
  cd - &> /dev/null
elif [ -n "$EXPERT" ]; then
  # Locate Expert if specified.
  echo "INFO: Locating Expert file ("$EXPERT")..."
  cd "$EXPERTS_DIR"
  EA_PATH=$(ea_find "$EXPERT")
  if [ -f "$EA_PATH" ]; then
    echo "INFO: Expert file found at: $EA_PATH"
  else
    echo "ERROR: Expert file ($EXPERT) not found!"
    on_error 1
  fi
  if [ "${EA_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    ea_copy "$EA_PATH"
    EA_PATH=$(ea_find "$EXPERT")
  fi
  # Use relative path to Experts dir.
  ini_set "^Expert" "${EA_PATH%.*}" "$TESTER_INI"
  cd - &> /dev/null
elif [ -n "$SCRIPT" ]; then
  # Locate Script if specified.
  echo "INFO: Locating Script file ("$SCRIPT")..."
  cd "$SCRIPTS_DIR"
  SCR_PATH=$(script_find "$SCRIPT")
  if [ -f "$SCR_PATH" ]; then
    echo "INFO: Script file found at: $SCR_PATH"
  else
    echo "ERROR: Script file ($SCRIPT) not found!"
    on_error 1
  fi
  if [ "${SCR_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    script_copy "$SCR_PATH"
    SCR_PATH=$(script_find "$SCRIPT")
  fi
  # Use relative path to Scripts dir.
  ini_set "^Script" "${SCR_PATH%.*}" "$TESTER_INI"
  cd - &> /dev/null
fi

if [ -n "$BT_START_DATE" ]; then
  echo "INFO: Configuring start test period ($BT_START_DATE)..."
  ini_set "^TestFromDate" "$BT_START_DATE" "$TESTER_INI"
else
  BT_START_DATE="$(ini_get TestFromDate)"
  BT_YEARS=(${BT_START_DATE%%.*})
fi
if [ -n "$BT_END_DATE" ]; then
  echo "INFO: Configuring end test period ($BT_END_DATE)..."
  ini_set "^TestToDate" "$BT_END_DATE" "$TESTER_INI"
else
  BT_END_DATE="$(ini_get TestToDate)"
  if [[ "${BT_YEARS[0]}" != "${BT_END_DATE%%.*}" ]]; then
    # Append ending year when the end date got a different year.
    BT_YEARS+=(${BT_END_DATE%%.*})
  fi
fi

# Configure symbol pair.
if [ -n "$BT_SYMBOL" ]; then
  echo "INFO: Configuring symbol pair ($BT_SYMBOL)..."
  ini_set "^TestSymbol" "$BT_SYMBOL" "$TESTER_INI"
else
  BT_SYMBOL="$(ini_get TestSymbol)"
fi

# Configure testing mode.
if [ -n "$BT_TESTMODEL" ]; then
  echo "INFO: Configuring test model ($BT_TESTMODEL)..."
  ini_set "^TestModel" "$BT_TESTMODEL" "$TESTER_INI"
else
  BT_TESTMODEL="$(ini_get TestModel)"
fi

if [ -n "$TEST_OPTS" ]; then
  echo "INFO: Applying tester settings ($TEST_OPTS)..."
  IFS=','
  test_options=($TEST_OPTS)
  restore_ifs
  for opt_pair in "${test_options[@]}"; do
    IFS='='
    test_option=($opt_pair)
    restore_ifs
    ini_set "^${test_option[0]}" "${test_option[1]}" "$TESTER_INI"
  done
fi

# Configure EA.
TEST_EXPERT="$(ini_get TestExpert)"
EXPERT="$(ini_get Expert)"
EA_FILE="${TEST_EXPERT:-$EXPERT}"
EA_INI="$TESTER_DIR/${EA_FILE##*/}.ini"
SCRIPT="$(ini_get Script)"
SCR_INI="$SCRIPTS_DIR/${SCRIPT##*/}.ini"
EA_SETFILE="${EA_FILE:-$SCRIPT}.set"
EA_SETFILE=${EA_SETFILE##*/} # Drop the path.
SERVER="${SERVER:-$(ini_get Server)}"

# Export SET file when SETFILE does not exist.
if [ -n "$SETFILE" -a ! -s "$SETFILE" ]; then
  echo "ERROR: Specified SET file via -f param does not exist ($SETFILE), exporting from EA ..."
  exported_setfile=${TEST_EXPERT:-$EXPERT}
  exported_setfile=$(export_set "${exported_setfile##*/}" "$(basename "$SETFILE")")
  [ ! -s "$TESTER_DIR/$exported_setfile" ] && {
    echo "ERROR: Export of SET file failed!"
    ls "$TESTER_DIR"/*.set
    on_error 1
  }
  cp -f $VFLAG "$TESTER_DIR/$exported_setfile" "$SETFILE"
fi
if [ -r "$SETFILE" ] && ! diff -u "$TESTER_DIR/$EA_SETFILE" "$SETFILE"; then
  echo "INFO: Copying SET file..."
  cp -f $VFLAG "$SETFILE" "$TESTER_DIR/$EA_SETFILE"
fi

# Copy the template INI file.
if [ -n "$EA_FILE" -a ! -s "$EA_INI" ]; then
  cp $VFLAG "$TPL_EA" "$EA_INI"
elif [ -n "$SCRIPT" -a ! -s "$SCR_INI" ]; then
  cp $VFLAG "$TPL_EA" "$SCR_INI"
fi

srv_copy
check_files

# Parse the main arguments.
OPTIND=1
while getopts $ARGS arg; do
  case ${arg} in

    b) ;; # Already parsed.
    B) ;; # Already parsed.

    c) # Base currency for test (e.g. USD).
      BT_CURRENCY=${OPTARG}
      ;;

    C) ;; # Already parsed.

    d) # Deposit amount to test (e.g. 2000).
      BT_DEPOSIT=${OPTARG}
      ;;

    D) # Specify market digits.
      BT_DIGITS=${OPTARG}
      ;;

    F) # Convert test report file to full detailed text format.
      type html2text sed > /dev/null
      OPT_FORMAT_FULL=1
      ;;

    g) # Post results to Gist.
      type gist pup > /dev/null
      OPT_GIST=true
      OPT_FORMAT_BRIEF=true
      OPT_FORMAT_JSON=true
      ;;

    G) # Enhances graph.
      type convert > /dev/null
      OPT_GIF_ENHANCE=1
      ;;

    i) # Invoke file with custom rules.
      INCLUDE+=("${OPTARG}")
      ;;

    j) # Convert test report file to JSON format.
      type pup paste > /dev/null
      OPT_FORMAT_JSON=1
      ;;

    l) # Lot step.
      BT_LOTSTEP=${OPTARG}
      ;;

    L) # Common/limit test parameters (e.g. genetic=0, maxdrawdown=20.00).
      EA_OPTS=${OPTARG}
      ;;

    o) # Run optimization test.
      OPT_OPTIMIZATION=true
      ;;

    O) # Output directory to save the test results.
      BT_DEST=${OPTARG}
      ;;

    P) # Set EA param in SET file (e.g. VerboseInfo=1,TakeProfit=0).
      SET_OPTS=${OPTARG}
      ;;

    r) # The name of the test report file.
      TEST_REPORT_NAME="tester/$(basename "${OPTARG}")"
      ;;

    R) # Set files to read-only.
      set_read_perms
      ;;

    S) # Spread to test.
      BT_SPREAD=${OPTARG}
      ;;

    t) # Convert test report file into brief text format.
      type html2text > /dev/null
      OPT_FORMAT_BRIEF=true
      ;;

    T) # Timeframe to test.
      BT_PERIOD=${OPTARG}
      ;;

    X)
      echo "INFO: Checking whether after test script exists..."
      [ -f "$OPTARG" ] || {
        echo "ERROR: Script specified by -X parameter does no exist."
        on_error 1
      }
      ;;

    v) # Enables verbose mode.
      OPT_VERBOSE=true
      ;;

    V) # Enables visual mode.
      VISUAL_MODE=true
      ;;

    _) # Dry run.
      OPT_DRY_RUN=true
      ;;

      # Placeholders for parameters used somewhere else.
    b | B | C | e | E | f | I | m | M | p | s | x | y) ;;

    *)
      echo "WARN: Args: $@" >&2
      usage
      on_error 1
      ;;

  esac
done

# Apply settings.
if [ -n "$INCLUDE" ]; then
  echo "INFO: Invoking include file(s) (${INCLUDE[@]})..."
  for file in ${INCLUDE[@]}; do
    [ -f "$INCLUDE" ]
    . <(cat "$file")
  done
fi

# Configure test period.
if [ -n "$BT_PERIOD" ]; then
  echo "INFO: Configuring test period ($BT_PERIOD)..."
  ini_set "^TestPeriod" "$BT_PERIOD" "$TESTER_INI"
fi

# Action(s) to evaluate.
if [ -n "$RUN_ON_SET" ]; then
  for code in "${RUN_ON_SET[@]}"; do
    echo "INFO: Running code on SET configuration ($code)..."
    eval "$code"
  done
fi
if [ -n "$EA_OPTS" ]; then
  echo "INFO: Applying EA backtest settings ($EA_OPTS)..."
  [ -f "$EA_INI" ]
  IFS=','
  ea_options=($EA_OPTS)
  restore_ifs
  for opt_pair in "${ea_options[@]}"; do
    IFS='='
    ea_option=($opt_pair)
    restore_ifs
    ini_set_ea "${ea_option[0]}" "${ea_option[1]}"
  done
fi
if [ -n "$SET_OPTS" ]; then
  echo "INFO: Setting EA options ($SET_OPTS)..."
  if [ -f "$TESTER_DIR/$EA_SETFILE" ]; then
    # Append settings into the SET file.
    IFS=','
    set_options=($SET_OPTS)
    restore_ifs
    for set_pair in "${set_options[@]}"; do
      IFS='='
      set_option=($set_pair)
      restore_ifs
      input_set "${set_option[0]}" "${set_option[1]}"
      ini_set_ea "${set_option[0]}" "${set_option[1]}"
    done
  else
    # Create a new SET file if does not exist.
    tr , "\n" <<< $SET_OPTS > "$TESTER_DIR/$EA_SETFILE"
  fi
  if [ -n "$OPT_VERBOSE" ]; then
    # Print final version of the SET file.
    echo "INFO: Final parameters: $(grep -v ,.= "$TESTER_DIR/$EA_SETFILE" | paste -sd,)" >&2
  fi
fi

# Adds SET file into Terminal INI Configuration file.
if [ -n "$SETFILE" -o -n "$SET_OPTS" ]; then
  echo "INFO: Configuring SET parameters ($EA_SETFILE)..."
  if [ -f "$TESTER_DIR/$EA_SETFILE" ]; then
    if [ -n "$TEST_EXPERT" ]; then
      ini_set "^TestExpertParameters" "$EA_SETFILE" "$TESTER_INI"
    elif [ -n "$EXPERT" ]; then
      ini_set "^ExpertParameters" "$EA_SETFILE" "$TESTER_INI"
    elif [ -n "$SCRIPT" ]; then
      ini_set "^ScriptParameters" "$EA_SETFILE" "$TESTER_INI"
    fi
    echo "INFO: Copying parameters from SET into INI file..."
    ini_set_inputs "$TESTER_DIR/$EA_SETFILE" "$EA_INI"
  else
    if [ ! -s "$SETFILE" ]; then
      echo "ERROR: Set file not found ($SETFILE)!"
      on_error 1
    fi
  fi
fi

# Configure base currency if present.
if [ -n "$BT_CURRENCY" ]; then
  echo "INFO: Configuring base currency ($BT_CURRENCY)..."
  ini_set "^currency" "$BT_CURRENCY" "$EA_INI"
fi

# Configure deposit if present.
if [ -n "$BT_DEPOSIT" ]; then
  echo "INFO: Configuring deposit ($BT_DEPOSIT)..."
  ini_set "^deposit" "$BT_DEPOSIT" "$EA_INI"
fi

# Sets a test report if present.
if [ -n "$EA_FILE" ]; then
  TEST_REPORT_NAME="${TEST_REPORT_NAME:-tester/${EA_FILE##*/}-Report}.htm"
  echo "INFO: Configuring test report ($TEST_REPORT_NAME)..."
  ini_set "^TestReport" "$TEST_REPORT_NAME" "$TESTER_INI"
fi

# Sets the optimization mode if present.
if [ -n "$OPT_OPTIMIZATION" ]; then
  echo "INFO: Configuring optimization mode..."
  ini_set "^TestOptimization" true "$TESTER_INI"
fi

# Sets the visual mode if present.
if [ -n "$VISUAL_MODE" ]; then
  echo "INFO: Enabling visual mode..."
  ini_set "^TestVisualEnable" true "$TESTER_INI"
fi

# Checks the destination folder (if run EA, not a script).
if [ -n "$EA_FILE" -a -n "$BT_DEST" ]; then
  echo "INFO: Checking destination directory ($BT_DEST)..."
  [ -d "$BT_DEST" ] || mkdir -p $VFLAG "$BT_DEST"
  [ -f /.dockerenv -a -w "$BT_DEST" ] || {
    echo "WARN: No write access! Attempting fixing the destination directory permissions ($BT_DEST)..."
    timeout 1 sudo id && chmod $VFLAG a=rwx "$BT_DEST" || true
  }
  [ -w "$BT_DEST" ] || {
    echo "ERROR: Destination directory ($BT_DEST) not writeable!"
    stat "$BT_DEST" >&2
    on_error 1
  }
fi

# Check backtest data if required.
BT_PERIOD=$(ini_get TestPeriod)
BT_PERIOD_FXT=${BT_PERIOD_FXT:-$BT_PERIOD}
BT_TESTMODEL_FXT=${BT_TESTMODEL_FXT:-0}
if [ -n "$TEST_EXPERT" ]; then
  echo "INFO: Checking backtest data (${BT_SRC:-DS})..."
  bt_key=$BT_SYMBOL-$(join_by - ${BT_YEARS[@]:-2019})-${BT_SRC:-DS}
  bt_data=$(ini_get "bt_data" "$CUSTOM_INI")
  # Download backtest files if not present.
  if [ -z "$(find "$TERMINAL_DIR" -name "${BT_SYMBOL}*_0.fxt" -print -quit)" ] || [ "${bt_data%.*}" != "$bt_key" ]; then
    bt_data_get "$BT_SYMBOL" "$(join_by - "${BT_YEARS[@]:-2019}")" "${BT_SRC:-DS}" "${BT_PERIOD_FXT}" "${BT_TESTMODEL_FXT}"
    if [ -n "$OPT_VERBOSE" ]; then
      cd "$TERMINAL_DIR"
      find . '(' -name "*.hst" -o -name "*.fxt" ')' -ls
      cd - &> /dev/null
    fi
  fi
  # Assign variables.
  FXT_FILE=$(find "$TICKDATA_DIR" -name "*.fxt" -print -quit)
fi

# Sets a spread in FXT files (if specified).
if [ -n "$BT_SPREAD" ]; then
  echo "INFO: Configuring spread ($BT_SPREAD)..."
  set_spread $BT_SPREAD
fi

# Sets currency/volume digits and point size in symbol raw and FXT files (if specified).
if [ -n "$BT_DIGITS" ]; then
  echo "INFO: Configuring digits ($BT_DIGITS)..."
  set_digits $BT_DIGITS
fi

# Sets a lot step in FXT files (if specified).
if [ -n "$BT_LOTSTEP" ]; then
  echo "INFO: Setting lot step in FXT files ($BT_LOTSTEP)..."
  set_lotstep $BT_LOTSTEP
fi

# Sets an account leverage in FXT files (if specified).
if [ -n "$BT_LEVERAGE" ]; then
  echo "INFO: Setting account leverage in FXT files ($BT_LEVERAGE)..."
  set_leverage $BT_LEVERAGE
fi

# Sets white-listed web-request URLs (if specified).
if [ -n "$EA_WHITELIST_URLS" ]; then
  echo "INFO: Setting white-listed URLs ($EA_WHITELIST_URLS)..."
  add_url $EA_WHITELIST_URLS
fi

# Final checks.
if [ -n "$TEST_EXPERT" ]; then
  [ -n "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')' -size +1 -print -quit)" ] \
    || {
      echo "ERROR: Missing backtest data files!"
      on_error 1
    }
fi

if [ -z "$TEST_EXPERT" -a -z "$EXPERT" -a -z "$SCRIPT" ]; then
  echo "ERROR: You need to specify TestExpert (-e), Expert (-E) or Script (-s)!"
  on_error 1
fi

if [ -n "$EA_FILE" ] && [[ ${EA_PATH##*.} =~ 'mq' ]]; then
  # Compile EA when source code file is specified.
  echo "INFO: Compiling EA ($EA_PATH)..."
  compiled_no="$(compile_ea ${EA_PATH##*/})"
  echo "INFO: Number of files compiled: $compiled_no"
  [ "${compiled_no}" -gt 0 ]
elif [ -n "$SCRIPT" ] && [[ ${SCR_PATH##*.} =~ 'mq' ]]; then
  # Compile script when source code file is specified.
  echo "INFO: Compiling script ($SCR_PATH)..."
  compiled_no="$(compile_script ${SCR_PATH##*/})"
  echo "INFO: Number of files compiled: $compiled_no"
  [ ${compiled_no} -gt 0 ]
fi

# Exit on dry run.
if [ -n "$OPT_DRY_RUN" ]; then
  errcode=$?
  echo "INFO: Dry run completed."
  on_exit
  exit $?
fi

# Start X virtual framebuffer.
set_display

# Clean files before run.
clean_files

# Kill on error condition when running script.
if [ -n "$SCRIPT" ]; then
  kill_on_match &
fi

# Show live logs and stats when in verbose mode.
if [ -n "$OPT_VERBOSE" ]; then
  live_logs &
  live_stats &
fi

# Run the test in the platform.
echo "INFO: Starting..."
{
  time wine "$TERMINAL_EXE" $TERMINAL_ARG $TERMINAL_ARG_CFG
} 2>> "$TERMINAL_LOG" && exit_status=$? || exit_status=$?

# Check the results.
[ ${exit_status} -eq 0 ] && on_success $@ || on_failure $@

# Invoke custom code on shutdown/final run.
if [ -n "$RUN_ON_EXIT" ]; then
  echo "INFO: Running code on exit ($RUN_ON_EXIT)..."
  eval "$RUN_ON_EXIT"
fi

[ -n "$OPT_VERBOSE" ] && times >&2 && echo "INFO: $0 done."
exit $exit_status
