#!/usr/bin/env bash
# Script to run backtest test.
# E.g. run_backtest.sh -v -t -e MACD -f "/path/to/file.set" -c USD -p EURUSD -d 2000 -m 1-2 -y 2017 -s 20 -b DS -r Report -O "_optimization_results"

# Initialize variables.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ARGS="?b:B:c:Cd:D:e:E:f:FgGi:I:jl:L:m:M:p:P:r:Rs:S:oO:tT:vVxX:y:"

# Check dependencies.
type git pgrep xargs ex xxd od perl xdpyinfo >/dev/null

## Define local functions. ##

# Show script usage and exit.
usage() {
  printf "Usage: %s (args)\n\n" "$0"
  cat $CWD/options.txt
  printf "\n\nExample: %s -v -t -e MACD -p EURUSD -c USD -d 2000 -y 2017 -m 1-2 -S 20 -b DS -T M30\n" "$0"
}

# Invoke on test success.
on_success() {
  echo "Checking logs..." >&2
  show_logs
  check_log_errors
  echo "RUN succeeded." >&2
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
  # Set exit status to 0.
  exit_status=0
}

# Invoke on test failure.
on_failure() {
  echo "FAIL?!" >&2
  # Sometimes MT4 fails on success, therefore double checking.
  TEST_REPORT_BASE="$(basename "$(ini_get TestReport)")"
  if [ -n "$TEST_REPORT_BASE" ]; then
    TEST_REPORT_HTM=$(find "$TESTER_DIR" "$TERMINAL_DIR" -maxdepth 2 -name "$TEST_REPORT_BASE.htm" -print -quit)
    test -f "$TEST_REPORT_HTM" && { on_success $@; return; }
  elif [ -z "$TEST_EXPERT" -a -n "$SCRIPT" ]; then
    # Report success when script was run and platform killed.
    log_file="$(find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
    grep -w -C1 "uninit reason 0" "$log_file" && { on_success $@; return; }
  fi

  echo "Printing logs..." >&2
  show_logs
  echo "RUN failed." >&2
  on_finish
}

# Invoke on test finish.
on_finish() {
  kill_jobs
  kill_wine
  kill_display
}

# Parse report files.
parse_results() {
  TEST_REPORT_BASE="$(basename "$(ini_get TestReport)")"

  # Ignore if no test results or test expert name is set (e.g. when running the script).
  [ -z "$TEST_REPORT_BASE" -o -z "$TEST_EXPERT" ] && return

  # Locate the report file.
  TEST_REPORT_HTM=$(find "$TESTER_DIR" "$TERMINAL_DIR" -maxdepth 2 -name "$TEST_REPORT_BASE.htm" -print -quit)
  TEST_REPORT_DIR="$(dirname "$TEST_REPORT_HTM")"
  test -d "$TEST_REPORT_DIR" || exit 1
  test -f "$TEST_REPORT_HTM" || exit 1

  echo "Checking the total time elapsed..." >&2
  save_time

  if [ -n "$OPT_FORMAT_JSON" ]; then
    # Convert test report file into JSON format.
    echo "Converting HTML report ($TEST_REPORT_DIR) into JSON file..." >&2
    convert_html2json "$TEST_REPORT_HTM"
  fi

  if [ -n "$OPT_OPTIMIZATION" ]; then
    # Parse and save the optimization test results.
    echo "Sorting optimization test results..." >&2
    if [ "${MT_VER%%.*}" -ne 5 ]; then
      sort_opt_results "$TEST_REPORT_HTM"
    fi
    echo "Saving optimization results..."
    if [ -z "$input_values" ]; then
      for input in ${param_list[@]}; do
        value=$(ini_get "$input" "$TEST_REPORT_HTM")
        echo "Setting '$input' to '$value' in '$(basename $SETFILE)'" >&2
        ini_set "^$input" "$value" "$SETFILE"
      done
    fi
  fi

  if [ -n "$OPT_FORMAT_FULL" ]; then
    # Convert test report file to full detailed text format.
    TEST_REPORT_TXT="$TEST_REPORT_DIR/$TEST_REPORT_BASE.txt"
    echo "Converting HTML report ($(basename "$TEST_REPORT_HTM")) into full text file ($(basename "$TEST_REPORT_TXT"))..." >&2
    convert_html2txt_full "$TEST_REPORT_HTM" "$TEST_REPORT_TXT"
  elif [ -n "$OPT_FORMAT_BRIEF" ]; then
    # Convert test report file into brief text format.
    TEST_REPORT_TXT="$TEST_REPORT_DIR/$TEST_REPORT_BASE.txt"
    echo "Converting HTML report ($(basename "$TEST_REPORT_HTM")) into short text file ($(basename "$TEST_REPORT_TXT"))..." >&2
    convert_html2txt "$TEST_REPORT_HTM" "$TEST_REPORT_TXT"
  fi

  if [ -n "$OPT_GIF_ENHANCE" ]; then
    # Enhance gif report files.
    report_gif="$TEST_REPORT_DIR/$TEST_REPORT_BASE.gif"
    echo "Enhancing report image ($TEST_REPORT_BASE.gif)..." >&2
    enhance_gif "$report_gif" ${GIF_ENHANCE:-"-n"}
    if [ -f "$TEST_REPORT_TXT" ]; then
      local gif_text=$(grep -wE '^\s*(Symbol|Period|Bars|Initial|Total|Profit|Absolute)' "$TEST_REPORT_TXT")
      enhance_gif "$report_gif" -t "$gif_text"
    fi
  fi

  if [ -n "$OPT_VERBOSE" ]; then
    # Print test results in plain text.
    echo "Printing test report ($(basename "$TEST_REPORT_HTM"))..." >&2
    grep -v mso-number "$TEST_REPORT_HTM" | html2text -nobs -width 180 | sed "/\[Graph\]/q"
    find "$TESTER_DIR/files" '(' -name "*.log" -o -name "*.txt" ')' $VPRINT -exec cat "{}" +
  fi

  if [ -d "$BT_DEST" ]; then
    # Copy the test results if the destination directory has been specified.
    echo "Copying report files ($TEST_REPORT_BASE.* into: $BT_DEST)..." >&2
    cp $VFLAG "$TEST_REPORT_DIR/$TEST_REPORT_BASE".* "$BT_DEST"
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
[ $# -eq 0 ] && { usage; exit 0; }

# Parse the initial arguments.
while getopts $ARGS arg; do
  case ${arg} in

    \?) # Display help.
      usage
      exit 0
      ;;

    v) # Verbose mode.
      OPT_VERBOSE=true
      VFLAG="-v"
      VPRINT="-print"
      VDD="noxfer"
#EXFLAG="-V1" # @see: https://github.com/vim/vim/issues/919
      type html2text sed >/dev/null
      ;;

    x) # Run the script in debug mode.
      OPT_TRACE=1
      set -x
      ;;

  esac
done

# Invoke includes.
. "$CWD"/.aliases.inc.sh
. "$CWD"/.funcs.cmds.inc.sh
. "$CWD"/.funcs.inc.sh
. "$CWD"/.vars.inc.sh

# Initialize.
initialize
set_display

[ -n "$NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x

# Check if terminal is present, otherwise install it.
echo "Checking platform..." >&2
if [ -f "$TERMINAL_EXE" ]; then
  # Check required directories.
  check_dirs
else
  [ -n "$OPT_VERBOSE" ] && grep ^TERMINAL <(set) | xargs
  echo "ERROR: Terminal not found, please specify -M parameter with version to install it." >&2;
  exit 1;
fi

# Re-load variables.
. "$CWD"/.vars.inc.sh

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
      clean_files
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

    M) # Specify version of MetaTrader (e.g. 4, 4x, 5, 4.0.0.1010).
      MT_VER=${OPTARG:-4.0.0.1010}
      type unzip >/dev/null
      install_mt $MT_VER
      . "$CWD"/.vars.inc.sh # Reload variables.
      check_dirs
      ;;

    p) # Symbol pair to test (e.g. EURUSD).
      BT_SYMBOL=${OPTARG}
      ;;

    s) # Script to run.
      SCRIPT=${OPTARG}
      ;;

    y) # Year to test (e.g. 2017, 2011-2015).
      BT_YEARS=${OPTARG}
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

# Invoke boot code.
if [ -n "$RUN_ON_START" ]; then
  echo "Running code on startup ($RUN_ON_START)..." >&2
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
  cd "$EXPERTS_DIR"
  EA_PATH=$(ea_find "$TEST_EXPERT")
  echo "Locating TestExpert file ("$TEST_EXPERT" => "$EA_PATH")..." >&2
  [ -f "$EA_PATH" ] || { echo "Error: TestExpert file ($TEST_EXPERT) not found in '$ROOT'!" >&2; exit 1; }
  if [ "${EA_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    ea_copy "$EA_PATH"
    EA_PATH=$(ea_find "$TEST_EXPERT")
  fi
  # Use relative path to Experts dir.
  ini_set "^TestExpert" "${EA_PATH%.*}" "$TESTER_INI"
  cd - &>/dev/null
elif [ -n "$EXPERT" ]; then
  # Locate Expert if specified.
  cd "$EXPERTS_DIR"
  EA_PATH=$(ea_find "$EXPERT")
  echo "Locating Expert file ("$EXPERT" => "$EA_PATH")..." >&2
  [ -f "$EA_PATH" ] || { echo "Error: Expert file ($EXPERT) not found in '$ROOT'!" >&2; exit 1; }
  if [ "${EA_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    ea_copy "$EA_PATH"
    EA_PATH=$(ea_find "$EXPERT")
  fi
  # Use relative path to Experts dir.
  ini_set "^Expert" "${EA_PATH%.*}" "$TESTER_INI"
  cd - &>/dev/null
elif [ -n "$SCRIPT" ]; then
  # Locate Script if specified.
  cd "$SCRIPTS_DIR"
  SCR_PATH=$(script_find "$SCRIPT")
  echo "Locating Script file ("$SCRIPT" => "$SCR_PATH")..." >&2
  [ -f "$SCR_PATH" ] || { echo "Error: Script file ($SCRIPT) not found in '$ROOT'!" >&2; exit 1; }
  if [ "${SCR_PATH::1}" == '/' ]; then
    # Copy EA to Experts dir when path is absolute.
    script_copy "$SCR_PATH"
    SCR_PATH=$(script_find "$SCRIPT")
  fi
  # Use relative path to Scripts dir.
  ini_set "^Script" "${SCR_PATH%.*}" "$TESTER_INI"
  cd - &>/dev/null
fi

if [ -n "$BT_START_DATE" ]; then
  echo "Configuring start test period ($BT_START_DATE)..." >&2
  ini_set "^TestFromDate" "$BT_START_DATE" "$TESTER_INI"
else
  BT_START_DATE="$(ini_get TestFromDate)"
  BT_YEARS=(${BT_START_DATE%%.*})
fi
if [ -n "$BT_END_DATE" ]; then
  echo "Configuring end test period ($BT_END_DATE)..." >&2
  ini_set "^TestToDate"   "$BT_END_DATE" "$TESTER_INI"
else
  BT_END_DATE="$(ini_get TestToDate)"
  if [[ "${BT_YEARS[0]}" != "${BT_END_DATE%%.*}" ]]; then
    # Append ending year when the end date got a different year.
    BT_YEARS+=(${BT_END_DATE%%.*})
  fi
fi

if [ -n "$BT_SYMBOL" ]; then
  echo "Configuring symbol pair ($BT_SYMBOL)..." >&2
  ini_set "^TestSymbol" "$BT_SYMBOL" "$TESTER_INI"
else
  BT_SYMBOL="$(ini_get TestSymbol)"
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
TEST_EXPERT="$(ini_get ^TestExpert)"
EXPERT="$(ini_get ^Expert)"
EA_FILE="${TEST_EXPERT:-$EXPERT}"
EA_INI="$TESTER_DIR/${EA_FILE##*/}.ini"
SCRIPT="$(ini_get ^Script)"
SCR_INI="$SCRIPTS_DIR/${SCRIPT##*/}.ini"
EA_SETFILE="${EA_FILE:-$SCRIPT}.set"
EA_SETFILE=${EA_SETFILE##*/} # Drop the path.
SERVER="${SERVER:-$(ini_get Server)}"

# Export SET file when SETFILE does not exist.
if [ -n "$SETFILE" -a ! -s "$SETFILE" ]; then
  echo "Specified SET file via -f param does not exist ($SETFILE), exporting from EA ..." >&2
  exported_setfile=${TEST_EXPERT:-$EXPERT}
  exported_setfile=$(export_set "${exported_setfile##*/}" "$(basename "$SETFILE")")
  [ ! -s "$TESTER_DIR/$exported_setfile" ] && { echo "ERROR: Export of SET file failed!" >&2; ls "$TESTER_DIR"/*.set; exit 1; }
  cp -f $VFLAG "$TESTER_DIR/$exported_setfile" "$SETFILE"
fi
if [ -s "$SETFILE" -a ! -f "$TESTER_DIR/$EA_SETFILE" ]; then
  echo "EA's SET file does not exist ($EA_SETFILE), copying from $SETFILE..." >&2
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
      type html2text sed >/dev/null
      OPT_FORMAT_FULL=1
      ;;

    g) # Post results to Gist.
      type gist pup >/dev/null
      OPT_GIST=true
      OPT_FORMAT_BRIEF=true
      OPT_FORMAT_JSON=true
      ;;

    G) # Enhances graph.
      type convert >/dev/null
      OPT_GIF_ENHANCE=1
      ;;

    i) # Invoke file with custom rules.
      INCLUDE+=("${OPTARG}")
      ;;

    j) # Convert test report file to JSON format.
      type pup paste >/dev/null
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
      type html2text >/dev/null
      OPT_FORMAT_BRIEF=true
      ;;

    T) # Timeframe to test.
      BT_PERIOD=${OPTARG}
      ;;

    X)
      echo "Checking whether after test script exists..." >&2
      [ -f "$OPTARG" ] || { echo "ERROR: Script specified by -X parameter does no exist." >&2; exit 1; }
      ;;

    v) # Enables verbose mode.
      OPT_VERBOSE=true
      ;;

    V) # Enables visual mode.
      VISUAL_MODE=true
      ;;

    # Placeholders for parameters used somewhere else.
    ( b | B | C | e | E | f | I | m | M | p | s | x | y ) ;;

    *)
      echo "Args: $@" >&2
      usage
      exit 1
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
if [ -n "$BT_PERIOD" ]; then
  echo "Configuring test period ($BT_PERIOD)..." >&2
  ini_set "^TestPeriod" "$BT_PERIOD" "$TESTER_INI"
fi

# Action(s) to evaluate.
if [ -n "$RUN_ON_SET" ]; then
  for code in "${RUN_ON_SET[@]}"; do
    echo "Running code on SET configuration ($code)..." >&2
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
  if [ -f "$TESTER_DIR/$EA_SETFILE" ]; then
    # Append settings into the SET file.
    IFS=','; set_options=($SET_OPTS); restore_ifs
    for set_pair in "${set_options[@]}"; do
      IFS='='; set_option=($set_pair); restore_ifs
      input_set "${set_option[0]}" "${set_option[1]}"
      ini_set_ea "${set_option[0]}" "${set_option[1]}"
    done
  else
    # Create a new SET file if does not exist.
    tr , "\n" <<<$SET_OPTS > "$TESTER_DIR/$EA_SETFILE"
  fi
  if [ -n "$OPT_VERBOSE" ]; then
    # Print final version of the SET file.
    echo "Final parameters: $(grep -v ,.= "$TESTER_DIR/$EA_SETFILE" | paste -sd,)" >&2
  fi
fi

# Adds SET file into Terminal INI Configuration file.
if [ -n "$SETFILE" -o -n "$SET_OPTS" ]; then
  echo "Configuring SET parameters ($EA_SETFILE)..." >&2
  if [ -f "$TESTER_DIR/$EA_SETFILE" ]; then
    if [ -n "$TEST_EXPERT" ]; then
      ini_set "^TestExpertParameters" "$EA_SETFILE" "$TESTER_INI"
    elif [ -n "$EXPERT" ]; then
      ini_set "^ExpertParameters" "$EA_SETFILE" "$TESTER_INI"
    elif [ -n "$SCRIPT" ]; then
      ini_set "^ScriptParameters" "$EA_SETFILE" "$TESTER_INI"
    fi
    echo "Copying parameters from SET into INI file..." >&2
    ini_set_inputs "$TESTER_DIR/$EA_SETFILE" "$EA_INI"
  else
    if [ ! -s "$SETFILE" ]; then
      echo "ERROR: Set file not found ($SETFILE)!" >&2
      exit 1
    fi
  fi
fi

# Configure base currency if present.
if [ -n "$BT_CURRENCY" ]; then
  echo "Configuring base currency ($BT_CURRENCY)..." >&2
  ini_set "^currency" "$BT_CURRENCY" "$EA_INI"
fi

# Configure deposit if present.
if [ -n "$BT_DEPOSIT" ]; then
  echo "Configuring deposit ($BT_DEPOSIT)..." >&2
  ini_set "^deposit" "$BT_DEPOSIT" "$EA_INI"
fi

# Sets currency/volume digits if present.
if [ -n "$BT_DIGITS" ]; then
  echo "Configuring digits ($BT_DIGITS)..." >&2
  set_digits $BT_DIGITS
fi

# Sets a lot step if present.
if [ -n "$BT_LOTSTEP" ]; then
  echo "Configuring lot step ($BT_LOTSTEP)..." >&2
  set_lotstep $BT_LOTSTEP
fi

# Sets a test report if present.
if [ -n "$EA_FILE" ]; then
  TEST_REPORT_NAME=${TEST_REPORT_NAME:-tester/${EA_FILE##*/}-Report}
  echo "Configuring test report ($TEST_REPORT_NAME)..." >&2
  ini_set "^TestReport" "$TEST_REPORT_NAME" "$TESTER_INI"
fi

# Sets a spread if present.
if [ -n "$BT_SPREAD" ]; then
  echo "Configuring spread ($BT_SPREAD)..." >&2
  set_spread $BT_SPREAD
fi

# Sets the optimization mode if present.
if [ -n "$OPT_OPTIMIZATION" ]; then
  echo "Configuring optimization mode..." >&2
  ini_set "^TestOptimization" true "$TESTER_INI"
fi

# Sets the visual mode if present.
if [ -n "$VISUAL_MODE" ]; then
  echo "Enabling visual mode..." >&2
  ini_set "^TestVisualEnable" true "$TESTER_INI"
fi

# Checks the destination folder (if run EA, not a script).
if [ -n "$EA_FILE" -a -n "$BT_DEST" ]; then
  echo "Checking destination directory ($BT_DEST)..." >&2
  [ -d "$BT_DEST" ] || mkdir -p $VFLAG "$BT_DEST"
  [ -f /.dockerenv -a -w "$BT_DEST" ] || {
    echo "Warning: No write access! Attempting fixing the destination directory permissions ($BT_DEST)..." >&2
    timeout 1 sudo id && chmod $VFLAG a=rwx "$BT_DEST" || true
  }
  [ -w "$BT_DEST" ] || {
    echo "Error: Destination directory ($BT_DEST) not writeable!" >&2
    stat "$BT_DEST" >&2
    exit 1
  }
fi

# Download backtest data if required.
BT_PERIOD=$(ini_get ^TestPeriod)
if [ -n "$TEST_EXPERT" ]; then
  echo "Checking backtest data (${BT_SRC:-DS})..."
  bt_key=$BT_SYMBOL-$(join_by - ${BT_YEARS[@]:-2017})-${BT_SRC:-DS}
  bt_data=$(ini_get "bt_data" "$CUSTOM_INI")
  # Generate backtest files if not present.
  if [ -z "$(find "$TERMINAL_DIR" -name "${BT_SYMBOL}*_0.fxt" -print -quit)" ] || [ "${bt_data%.*}" != "$bt_key" ]; then
    env SERVER=$SERVER OPT_VERBOSE=$OPT_VERBOSE OPT_TRACE=$OPT_TRACE \
      $SHELL $SCR/get_bt_data.sh $BT_SYMBOL "$(join_by - ${BT_YEARS[@]:-2017})" ${BT_SRC:-DS} ${BT_PERIOD} ${BT_TESTMODE}
    if [ -n "$OPT_VERBOSE" ]; then
      cd "$TERMINAL_DIR"
      find . '(' -name "*.hst" -o -name "*.fxt" ')' -ls
      cd - &>/dev/null
    fi
  fi
  # Assign variables.
  FXT_FILE=$(find "$TICKDATA_DIR" -name "*.fxt" -print -quit)
fi

# Prepare before test run.
if [ -n "$TEST_EXPERT" ]; then
  [ -n "$(find "$TERMINAL_DIR" '(' -name "*.hst" -o -name "*.fxt" ')' -size +1 -print -quit)" ] \
    || { echo "ERROR: Missing backtest data files." >&2; exit 1; }
fi
clean_files

if [ -z "$TEST_EXPERT" -a -z "$EXPERT" -a -z "$SCRIPT" ]; then
  echo "ERROR: You need to specify TestExpert (-e), Expert (-E) or Script (-s)." >&2;
  exit 1
fi

if [ -n "$EA_FILE" ] && [[ ${EA_PATH##*.} =~ 'mq' ]]; then
  # Compile EA when source code file is specified.
  echo "Compiling EA ($EA_PATH)..." >&2
  compile_ea ${EA_PATH##*/}
elif [ -n "$SCRIPT" ] && [[ ${SCR_PATH##*.} =~ 'mq' ]]; then
  # Compile script when source code file is specified.
  echo "Compiling script ($SCR_PATH)..." >&2
  compile_script ${SCR_PATH##*/}
fi

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
echo "Starting..." >&2
{
  time wineconsole --backend=curses "$TERMINAL_EXE" $TERMINAL_ARG "config/$CONF_TEST"
} 2>> "$TERMINAL_LOG" && exit_status=$? || exit_status=$?

# Check the results.
[ ${exit_status} -eq 0 ] && on_success $@ || on_failure $@

# Invoke shutdown/final code.
if [ -n "$RUN_ON_EXIT" ]; then
  echo "Running code on exit ($RUN_ON_EXIT)..." >&2
  eval "$RUN_ON_EXIT"
fi

[ -n "$OPT_VERBOSE" ] && times >&2 && echo "$0 done" >&2
exit $exit_status
