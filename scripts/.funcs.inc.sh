#!/usr/bin/env bash
# Define shell functions for internal use.
# Used by scripts such as run_backtest.sh.
# Note: To invoke them manually, you can use eval.sh script.
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2
CWD="${CWD:-$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)}"

#
## Define common functions. ##
#

# Init shell settings.
initialize() {

  # Handle bash errors. Exit on error. Trap exit.
  # Trap normal exit signal (exit on all errors).
  trap on_exit EXIT
  # Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR (9/KILL cannot be trapped).
  trap on_error 1 2 3 15 ERR

  # Activate trace on demand.
  [ -n "$OPT_TRACE" ] && set -x
  # Exit immediately if a command exits with a non-zero status.
  [ -z "$NOFAIL" ] && set -e

}

# Clean traps which are in use.
clean_traps() {
  trap - 1 2 3 15 ERR EXIT
}

# Install filever
install_support_tools() {
  type wget cabextract install wine >/dev/null
  wine filever >/dev/null && return
  local tools_url="https://github.com/EA31337/EA-Tester/releases/download/4.x/WindowsXP-KB838079-SupportTools-ENU.exe"
  local dtmp=$(mktemp -d)
  echo "Installing support tools..." >&2
  cd "$dtmp"
  wget -nv "$tools_url"
  cabextract -F support.cab *.exe
  cabextract -F filever.exe *.cab
  install -v filever.exe ~/.wine/drive_c/windows
  rm -fr "$dtmp"
  cd - &>/dev/null
}

# Join string by delimiter (see: http://stackoverflow.com/a/17841619).
join_by() {
  local d=$1
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}

# Check required files.
# Usage: check_files
check_files() {
  if [ "$SERVER" != "default" ] && [ -w "$HISTORY_DIR/$SERVER" ]; then
    [ -s "$symbols_raw" ] || cp $VFLAG "$HISTORY_DIR/default/symbols.raw" "$HISTORY_DIR/$SERVER/symbols.raw"
  fi
}

# Check platform required directories.
check_dirs() {
  local args="-p $VFLAG"
  for dir in \
    "$TERMINAL_DIR/$MQL_DIR" \
    "$EXPERTS_DIR" \
    "$FILES_DIR" \
    "$HISTORY_DIR/$SERVER" \
    "$LOG_DIR" \
    "$SCRIPTS_DIR" \
    "$TESTER_DIR" \
    "$TICKDATA_DIR"; do
    [ -d "$dir" ] || mkdir $args "$dir"
  done
}

# Get time from the terminal log in minutes.
# Usage: get_time
get_time() {
  if [ -f "$TERMINAL_LOG" ]; then
    echo $(grep -o "^real[^m]\+" "$TERMINAL_LOG" | cut -f 2)
  else
    echo 0
  fi
}

# Get the max of two values.
# Usage: get_min (int) (int)
get_min() {
  echo $(($1 < ${2:-0} ? $1 : ${2:-0}))
}

# Get the max of two values.
# Usage: get_max (int) (int)
get_max() {
  echo $(($1 > ${2:-0} ? $1 : ${2:-0}))
}

# Check logs for errors.
# Usage: check_log_errors
check_log_errors() {
  local errors=()
  errors+=("cannot open")
  errors+=("not initialized")
  errors+=("initialization failed")
  errors+=("TestGenerator: .\+ not found")
  errors+=(".\+ no history data")
  errors+=(".\+ cannot start")
  errors+=(".\+ cannot open")
  errors+=(".\+ rate cannot")
  errors+=(".\+ not initialized")
  errors+=(".\+ file error")
  errors+=(".\+ data error")
  errors+=(".\+ deficient data")
  errors+=("stop button .\+")
  errors+=("incorrect casting .\+")
  errors+=("Error: .\+")
  errors+=("Configuration issue .\+")
  errors+=("Assert fail on .\+")
  errors+=("Testing pass stopped .\+")
  cd "$TERMINAL_DIR"
  # shellcheck disable=SC2251
  ! check_logs ".\+ no history data" || { ini_del "bt_data" "$CUSTOM_INI"; }
  # shellcheck disable=SC2251
  ! eval grep --color -iw -C2 "$(printf -- '-e "%s" ' "${errors[@]}")" */*.log */*/*.log
}

# Check logs for warnings.
# Usage: check_log_warns
check_log_warns() {
  local errors=()
  errors+=("leaked memory")
  errors+=("objects of type")
  errors+=("undeleted objects left")
  cd "$TERMINAL_DIR"
  # shellcheck disable=SC2251
  ! check_logs ".\+ no history data" || { ini_del "bt_data" "$CUSTOM_INI"; }
  # shellcheck disable=SC2251
  ! eval grep --color -iw -C2 "$(printf -- '-e "%s" ' "${errors[@]}")" */*.log */*/*.log
}

# Save time (in hours) and store in rule file if exists.
save_time() {
  mtime=$(eval get_time)
  htime=$((${mtime:-1} / 60))
  [ -n "$OPT_VERBOSE" ] && echo "ETA: ${htime}h" >&2
  [ -w "$INCLUDE" ] && tag_set ETA ${htime} "$INCLUDE" || true
}

# Read decimal value at given offset from the file.
# Usage: read_value (file) (hex-offset) (length)
read_value() {
  local file=$1
  local offset=$((16#$2))
  local length="${3:-1}"
  [ -s "$file" ]
  [ -n "$offset" ]
  echo $((16#$(xxd -p -l $length -s $offset "$file")))
}

# Read bytes in hex format at given offset from the file.
# Usage: read_data file.bin (offset) (length)
read_data() {
  [ -n $offset ]
  local file="$1"
  local offset="$2"
  local length="${3:-1}"
  xxd -p -l $length -s $offset "$file"
}

# Read double value at given offset from the file.
# Usage: read_double (file) (dec-offset) (length)
read_double() {
  local file=$1
  local offset=$2
  local length="${3:-8}"
  [ -s "$file" ]
  [ -n "$offset" ]
  od -F -An -N $length -j $offset "$file" | xargs
}

# Write double value at given offset in the file.
# Usage: write_double (file) (double) (dec-offset) (length)
write_double() {
  local file=$1
  local value="$2" # In decimal format.
  local offset=$3
  local length="${4:-8}"
  [ -s "$file" ]
  [ -n "$offset" ]
  perl -i -0777pe"substr(\$_, $offset, 8, pack('d', $value))" "$file"
}

# Modify binary file given value in hex format at given offset.
# Usage: write_data file.bin (hex-values) (hex-offset)
# E.g. write_data file.bin $(printf "%02x\n" 123) "FC"
write_data() {
  local file="$1"
  local value="$2" # In hex format.
  local offset="$3"
  local len="${4:-1}"
  local writable=$(
    test -w "$file"
    echo $?
  )
  [ -s "$file" ]
  [ -n "$value" ]
  [ -n "$offset" ]
  [ $writable = $FALSE ] && chmod $VFLAG u+w "$file"
  xxd -r - "$file" <<<"$offset: $value"
  [ $writable = $FALSE ] && chmod $VFLAG u-w "$file"
  return $TRUE
}

# Set read permissions for the test files.
# Usage: set_read_perms
set_read_perms() {
  # Make the backtest files read-only.
  echo "Setting read-only permissions for backtest files..." >&2
  find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' -or -name '*.exe' ')' -print0 | while IFS= read -r -d '' file; do
    chmod $VFLAG ugo-w "$file"
  done
}

# Set write permissions for the test files.
# Usage: set_write_perms
set_write_perms() {
  echo "Setting write permissions for backtest files..." >&2
  find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' ')' -print0 | while IFS= read -r -d '' file; do
    chmod $VFLAG u+w "$file"
  done
}

# Returns substring.
# Usage: substr start end <input
# e.g. substr 2 2 <<<$"12345"
substr() {
  set +x
  tail -c+${1:-0} | head -c-${2:-0}
}

# Convert binary to hex string.
# Usage: bin2hex <input
# E.g. bin2hex <<<$"abc"
bin2hex() {
  perl -ne 'print unpack "H*", $_'
}

# Convert hex string to binary.
# Usage: hex2bin <input
# E.g. hex2bin <<<$"616263"
hex2bin() {
  perl -ne 'print pack "H*", $_'
}

# Convert stream from one encoding into another.
# Usage: conv from to <input
# E.g.: conv utf-16 utf-8 <input
function conv() {
  local from=${1:-utf-16}
  local to=${2:-utf-8}
  iconv -f "$from" -t "$to" | tr -d \\r
}

# Restore IFS.
restore_ifs() {
  IFS=$' \t\n'
}

# Show simple stack trace.
show_trace() {
  while caller $((n++)); do :; done
  >&2
}

# Check logs in real-time and kill platform on pattern match.
# Usage: kill_on_match (interval)
kill_on_match() {
  local interval=${1:-10}
  local errors=("cannot open" "not initialized" "initialization failed" "uninit reason")
  # Check MQL4 logs for errors (e.g. MQL4/Logs/20180717.log).
  {
    set +x
    while sleep $interval; do
      log_file="$(find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
      [ -f "$log_file" ] && break
    done
    while sleep $interval; do
      # Check for each error.
      if eval grep --color -iw -C2 "$(printf -- '-e "%s" ' "${errors[@]}")" \"$log_file\"; then
        # In case of error, kill the wine process.
        kill_wine
      fi
    done &
  }
}

# Kill any remaining background jobs.
# Usage: kill_jobs
kill_jobs() {
  kill_wine
  sleep 10 &# Run dummy process.
  # Kill any remaining background jobs.
  kill $(jobs -p) 2>/dev/null || true
}

# Kill the currently running wineserver.
# Usage: kill_wine
kill_wine() {
  type wineserver &>/dev/null || {
    true
    return
  }
  wineserver -k || true
}

# Kill display.
# Usage: kill_display
kill_display() {
  (
    pkill -e Xvfb
    [ -w /tmp/.X0-lock ] && rm $VFLAG /tmp/.X0-lock
  ) || true
}

#--- on_exit()
##  @param $1 integer (optional) Exit status. If not set, use '$?'
on_exit() {
  local exit_status=${1:-$?}
  # Invoke custom code on exit.
  if [ -n "$RUN_ON_EXIT" ]; then
    echo "Running code on exit ($RUN_ON_EXIT)..." >&2
    eval "$RUN_ON_EXIT"
  fi
  kill_jobs
  kill_wine
  [ -n "$OPT_VERBOSE" ] && echo "Exiting $0 with $exit_status" >&2
  exit $exit_status
}

#--- on_error()
##  @param $1 integer (optional) Exit status. If not set, use '$?'
on_error() {
  local exit_status=${1:-$?}
  local frame=0
  # Invoke custom code on error.
  if [ -n "$RUN_ON_ERROR" ]; then
    echo "Running code on error ($RUN_ON_ERROR)..." >&2
    eval "$RUN_ON_ERROR"
  fi
  kill_jobs
  kill_wine
  kill_display
  echo "ERROR: Exiting $0 with $exit_status" >&2
  show_trace
  exit $exit_status
}

# Invoke on test fail.
on_fail() {
  # Invoke custom code on test failure.
  if [ -n "$RUN_ON_FAIL" ]; then
    echo "Running code on failure ($RUN_ON_FAIL)..." >&2
    eval "$RUN_ON_FAIL"
  fi
}

# Invoke on test warnings.
on_warn() {
  # Invoke custom code on test warnings.
  if [ -n "$RUN_ON_WARN" ]; then
    echo "Running code on failure ($RUN_ON_WARN)..." >&2
    eval "$RUN_ON_WARN"
  fi
}

# Invoke on test finish.
on_finish() {
  kill_jobs
  kill_wine
  kill_display
}
