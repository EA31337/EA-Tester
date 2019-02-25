#!/usr/bin/env bash
# Define shell functions for internal use.
# Used by scripts such as run_backtest.sh.
# Note: To invoke them manually, you can use eval.sh script.
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2
CWD="${CWD:-$(cd -P -- "$(dirname -- "$0")" && pwd -P)}"

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
  wine filever > /dev/null && return
  local tools_url="https://github.com/EA31337/EA-Tester/releases/download/4.x/WindowsXP-KB838079-SupportTools-ENU.exe"
  local dtmp=$(mktemp -d)
  echo "Installing support tools..." >&2
  cd "$dtmp"
  wget -nv "$tools_url"
  cabextract -F support.cab *.exe
  cabextract -F filever.exe *.cab
  install -v filever.exe ~/.wine/drive_c/windows
  rm -fr "$dtmp"
  cd - &> /dev/null
}

# Join string by delimiter (see: http://stackoverflow.com/a/17841619).
join_by() {
  local d=$1; shift;
  echo -n "$1"; shift;
  printf "%s" "${@/#/$d}";
}

# Check required files.
check_files() {
  if [ "$SERVER" != "default" ]; then
    local symbols_raw_default="$HISTORY_DIR/default/symbols.raw"
    local symbols_raw="$HISTORY_DIR/$SERVER/symbols.raw"
    [ -s "$symbols_raw" ] || cp $VFLAG "$symbols_raw_default" "$symbols_raw"
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
    "$TICKDATA_DIR"
  do
    [ -d "$dir" ] || mkdir $args "$dir"
  done
}

# Get time from the terminal log in minutes.
# Usage: get_time
get_time() {
  if [ -f "$TERMINAL_LOG" ]; then
    echo $(grep -o "^real[^m]\+" "$TERMINAL_LOG" | cut -f 2)
  else
    echo ?
  fi
}

# Check logs for errors.
# Usage: check_log_errors [filter] [args]
check_log_errors() {
  set -x
  local log_file="$(find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
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
  ! check_logs ".\+ no history data" || { ini_del "bt_data" "$CUSTOM_INI"; }
  ! eval grep --color -iw -C2 "$(printf -- '-e "%s" ' "${errors[@]}")" \"$log_file\"
}

# Save time (in hours) and store in rule file if exists.
save_time() {
  local htime=$(($(eval get_time) / 60))
  [ -n "$OPT_VERBOSE" ] && echo "ETA: $((get_time / 60))h" >&2
  [ -f "$INCLUDE" ] && tag_set ETA $htime "$INCLUDE" || true
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
  local writable=$(test -w "$file"; echo $?)
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

# Get value from symbols file (in hex format).
# Usage: get_symbol_value (hex-offset) (len)
get_symbol_value() {
  local rel_offset=$((16#$1))
  local length=${2:-1}
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${BT_SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  echo $(read_data "$file" $abs_offset $length)
}

# Get double value from symbols file (in hex format)
# Usage: get_symbol_double (hex-offset) (len)
get_symbol_double() {
  local rel_offset=$((16#$1))
  local length=${2:-8}
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${BT_SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  echo $(read_double "$file" $abs_offset $length)
}

# Change values in symbols file.
# Usage: set_symbol_value (dec-value) (hex-offset)
set_symbol_value() {
  [ -n "$1" ]
  local value=$(printf "%02x" $1)
  local rel_offset=$((16#$2))
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${BT_SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  write_data "$file" $value "$(printf "%02x" $abs_offset)"
  return $TRUE
}

# Change double in symbols file.
# Usage: set_symbol_double (double) (hex-offset)
set_symbol_double() {
  [ -n "$1" ]
  local value=$1
  local rel_offset=$((16#$2))
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${BT_SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  write_double "$file" $value $abs_offset
  return $TRUE
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

# Restore IFS.
restore_ifs() {
  IFS=$' \t\n'
}

# Show simple stack trace.
show_trace() {
  while caller $((n++)); do :; done; >&2
}

# Check logs in real-time and kill platform on error match.
# Usage: kill_on_error (interval)
kill_on_error() {
  local interval=${1:-10}
  local errors=("cannot open" "not initialized" "initialization failed")
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
  sleep 10 & # Run dummy process.
  # Kill any remaining background jobs.
  kill $(jobs -p) 2> /dev/null || true
}

# Kill the currently running wineserver.
# Usage: kill_wine
kill_wine() {
  type wineserver &>/dev/null || { true; return; }
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
  kill_jobs
  kill_wine
  kill_display
  [ -n "$OPT_VERBOSE" ] && echo "Exiting $0 with $exit_status" >&2
  exit $exit_status
}

#--- on_error()
##  @param $1 integer (optional) Exit status. If not set, use '$?'
on_error() {
  local exit_status=${1:-$?}
  local frame=0
  kill_jobs
  kill_wine
  kill_display
  echo "ERROR: Exiting $0 with $exit_status" >&2
  show_trace
  exit $exit_status
}
