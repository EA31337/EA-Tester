#!/usr/bin/env bash
# Define shell functions for the external use.
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2
CWD="${CWD:-$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)}"

#
## Define common functions. ##
#

# Display list of commands.
# Usage: help
help() {
  grep -B1 ^"# Usage" ${BASH_SOURCE[0]}
}

# Run backtest.
# Usage: run_backtest [args]
run_backtest() {
  $CWD/run_backtest.sh "$@"
}

# Run Terminal.
# Usage: run_terminal
run_terminal() {
  $CWD/run_terminal.sh "$@"
}

# Clone git repository.
# Usage: clone_repo [url] [args...]
clone_repo() {
  $CWD/clone_repo.sh "$@"
}

# Get the backtest data.
# Usage: get_bt_data [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5] [period]
get_bt_data() {
  $CWD/get_bt_data.sh "$@"
}

# Change the working directory.
# Usage: chdir [dir]
# E.g. chdir "$EXPERTS_DIR"
chdir() {
  local dest=$@
  \cd "$dest"
}

# Check logs for specific text.
# Usage: check_logs [filter] [args]
check_logs() {
  local filter=$1
  find "$TERMINAL_DIR" -name "*.log" -type f -exec grep --color -C1 -iw "$filter" ${@:2} "{}" +
}

# Display logs in real-time.
# Usage: live_logs [invert-match] [interval]
live_logs() {
  local filter=${1:-modify}
  local interval=${2:-10}
  set +x
  # Prints Terminal log when available (e.g. logs/20180717.log).
  {
    while sleep $interval; do
      log_file="$(find "$LOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
      [ -f "$log_file" ] && break
    done && tail -f "$log_file"
  } &
  # Prints MQL4 logs when available (e.g. MQL4/Logs/20180717.log).
  {
    while sleep $interval; do
      log_file="$(find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
      [ -f "$log_file" ] && break
    done && tail -f "$log_file"
  } &
  # Prints tester logs.
  while sleep $interval; do
    log_file="$(find "$TESTER_DIR" -name "*.log" -type f -print -quit)"
    [ -f "$log_file" ] && break
  done && {
    echo "Showing live logs..." >&2
    tail -f "$TESTER_DIR"/*/*.log | grep -vw "$filter"
  }
}

# Display performance stats in real-time.
# Usage: live_stats [interval]
live_stats() {
  set +x
  local interval=${1:-60}
  while sleep $interval; do
    # TERM=vt100 top | head -n4
    winedbg --command 'info wnd' | grep -v Empty | grep -w Static | cut -c67- | paste -sd,
  done
}

# Delete compiled EAs.
# Usage: clean_ea
clean_ea() {
  exec 1>&2
  echo "Cleaning compiled EAs and scripts..." >&2
  find "$TERMINAL_DIR/$MQL_DIR" '(' -name '*.ex4' -or -name '*.ex5' ')' -type f $VPRINT -delete
}

# Clean files (e.g. previous report and log files).
# Usage: clean_files
clean_files() {
  # Remove previous log, dat, txt and htm files.
  exec 1>&2
  echo "Cleaning previous test data..."
  find "$TESTER_DIR" '(' -name "*.htm" -o -name "*.txt" ')' -type f $VPRINT -delete
  [ -d "$TESTER_DIR"/files ] && find "$TESTER_DIR"/files -type f $VPRINT -delete
  # Remove log files.
  [ -d "$LOG_DIR" ] && find "$LOG_DIR" -type f $VPRINT -delete
  find "$TERMINAL_DIR" '(' -name "*.log" -o -name "*.txt" -o -name "Report*.htm" -o -name "*.gif" ')' -type f $VPRINT -delete
  # Remove selected symbol and group files, so they can be regenerated.
  find "$HISTORY_DIR" '(' -name "symbols.sel" -o -name "symgroups.raw" ')' $VPRINT -delete
}

# Delete backtest data files.
# Usage: clean_bt
clean_bt() {
  # Remove previous backtest files for the current symbol.
  exec 1>&2
  echo "Cleaning backtest data for ${BT_SYMBOL}..." >&2
  find "$TERMINAL_DIR" '(' -name "${BT_SYMBOL}*.hst" -o -name "${BT_SYMBOL}*.fxt" ')' -type f $VPRINT -delete
  ini_del "bt_data" "$CUSTOM_INI"
}

# Check the version of the given binary file.
# Usage: filever [file/terminal.exe]
filever() {
  type awk >/dev/null
  wine filever &>/dev/null || install_support_tools >&2
  local file=$1
  find "$PWD" "$TERMINAL_DIR" -name "$file" -type f -execdir wine filever /v "$file" ';' -quit \
    | grep ProductVersion | awk '{print $2}' | tr -d '\15'
}

# Install platform.
# Usage: install_mt [ver/4/5/4.0.0.1010]
install_mt() {
  type wget unzip >/dev/null
  local mt_ver=${1:-$MT_VER}
  set_display
  case $mt_ver in
    4)
      . "$CWD"/install_mt4.sh
    ;;
    4x)
      . "$CWD"/install_mt4x.sh
    ;;
    5)
      . "$CWD"/install_mt5.sh
    ;;
    4.0.0.*|5.0.0.*)
      [ ! -d "$WINE_PATH" ] && mkdir $VFLAG -p "$WINE_PATH"
      cd "$WINE_PATH"
      wget -nv -c "$REPO_URL/releases/download/${mt_ver:0:1}.x/mt-$mt_ver.zip"
      unzip -ou "mt-$mt_ver.zip"
      cd - &> /dev/null
    ;;
    *)
      echo "Error: Unknown platform version, try either 4 or 5." >&2
      exit 1
  esac
}

# Replaces MetaEditor with the specific version.
# Usage: install_mteditor [ver/5.0.0.1804]
install_mteditor() {
  local ver=${1:-5.0.0.1804}
  file_get "https://github.com/EA31337/MetaEditor/raw/${ver}/metaeditor.exe" "$DOWNLOAD_DIR" && \
    mv -v "$DOWNLOAD_DIR"/metaeditor.exe "$TERMINAL_DIR"/ || \
    { echo "Error: Cannot download MetaEditor ${ver}!" >&2; exit 1; }
  print_ver
}

# Show version of installed platform binaries.
print_ver() {
  MT_VER=$(filever terminal.exe)
  MTE_VER=$(filever metaeditor.exe)
  echo "Installed Terminal: $MT_VER"
  echo "Installed MetaEditor: $MTE_VER"
}

# Configure virtual display and wine.
# Usage: set_display
set_display() {
  export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=,winebrowser.exe=}" # Disable gecko and default browser in wine.
  export WINEDEBUG="${WINEDEBUG:-warn-all,fixme-all,err-alsa,-ole,-toolbar}" # For debugging, try: WINEDEBUG=trace+all
  export DISPLAY=${DISPLAY:-:0} # Select screen 0 by default.
  xdpyinfo &>/dev/null && return
  if which x11vnc &>/dev/null; then
    ! pgrep -a x11vnc && x11vnc -bg -forever -nopw -quiet -display WAIT$DISPLAY &
  fi
  ! pgrep -a Xvfb && Xvfb $DISPLAY -screen 0 1024x768x16 &
  sleep 1
  if which fluxbox &>/dev/null; then
    ! pgrep -a fluxbox && fluxbox 2>/dev/null &
  fi
  echo "IP: $(hostname -I) ($(hostname))"
}

# Detect and configure proxy.
# Usage: set_proxy
set_proxy() {
  local gw=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
  curl -s localhost:3128 > /dev/null || true && export http_proxy="http://localhost:3128"
  curl -s $gw:3128       > /dev/null || true && export http_proxy="http://$gw:3128"

  # Set proxy for wine registry if present.
  [ -n "$http_proxy" ] &&
  cat << EOF | wine regedit -
  Regedit4
  [HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings]
  "MigrateProxy"=dword:00000001
  "ProxyEnable"=dword:00000001
  "ProxyHttp1.1"=dword:00000001
  "ProxyServer"="$http_proxy"
  "ProxyOverride"="<local>"
EOF
}

# Display recent logs.
# Usage: show_logs
show_logs() {
  find "$TERMINAL_DIR" -name "*.log" -type f $VPRINT -exec tail -n20 "{}" +
}

# Copy script file given the file path.
# Usage: script_copy [file]
script_copy() {
  local file="$1"
  local dest="$SCRIPTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$SCRIPTS_DIR"/
}

# Copy library file (e.g. dll) given the file path.
# Usage: lib_copy [file]
lib_copy() {
  local file="$1"
  local dest="$LIB_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$LIB_DIR"/
}

# Copy a file given the file path.
# Usage: file_copy [file]
file_copy() {
  local file="$1"
  local dest="$FILES_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$FILES_DIR"/
}

# Copy srv files into terminal dir.
# Usage: srv_copy [file]
srv_copy() {
  local server="$(ini_get Server)"
  srv_file=$(find "$ROOT" -name "$server.srv" -type f -print -quit)
  if [ -n "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/
  fi
}

# Download the file.
# Usage: file_get [url]
file_get() {
  local url="$1"
  local dest="${2:-$DOWNLOAD_DIR}"
  wget -cP "$dest" $url
}

# Compile the source code file.
# Usage: compile_file [file] (log_file)
compile_file() {
  local name=$1
  local logfile=${2:-${name%.*}.log}
  type iconv >/dev/null

  local rel_path=$name
  [ ! -s "$rel_path" ] && {
    name=${name##*/} # Drop the path.
    local exact=$(find -L . -maxdepth 4 -type f -name "${name%.*}.mq?" -print -quit)
    local match=$(find -L . -maxdepth 4 -type f -name "*${name%.*}*.mq?" -print -quit)
    rel_path=$(echo ${exact#./} || echo ${match#./})
  }
  [ ! -s "$rel_path" ] && { echo "Error: Cannot access ${rel_path:-$1}!" >&2; cd - &> /dev/null; return; }

  # Read value of errexit, and disable it.
  shopt -qo errexit; local errexit=$?; set +e

  # Run compiler.
  WINEPATH="$(winepath -w "$TERMINAL_DIR")" wine metaeditor.exe ${@:2} /compile:"$rel_path" /log:$logfile
  compiled_no=$?
  # Reset errexit to the previous value.
  [[ $errexit -eq 0 ]] && set -e
  echo "Info: Number of files compiled: $compiled_no" >&2
  [ ! -f "$logfile" ] && logfile="${logfile%.*}.log"
  if [ -f "$logfile" ]; then
    results=$(iconv -f utf-16 -t utf-8 "$logfile")
    grep -A10 "${name%.*}" <<<$results
    if ! grep -qw "0 error" <<<$results; then
      echo "Error: Cannot compile ${rel_path:-$1} due to errors!" >&2;
      WINEPATH="$(winepath -w "$TERMINAL_DIR")" wine metaeditor.exe ${@:2} /s /compile:"$rel_path" /log:CON
      exit 1; # Fail on error.
    fi
  fi
}

# Compile specified EA file.
# Usage: compile_ea [EA/pattern] (log_file)
compile_ea() {
  local name=${1:-$TEST_EXPERT}
  local logfile=${2:-${name%.*}.log}
  local ea_path=$(ea_find "$name")
  local ea_dir=$(dirname "$ea_path")

  # If path is absolute, enter that dir, otherwise go to Experts dir.
  [ "${ea_path:0:1}" == "/" ] && cd "$ea_dir" || cd "$EXPERTS_DIR"
  [ ! -w "$ea_dir" ] && { echo "Error: ${ea_dir} directory not writeable!" >&2; exit 1; }
  compile_file "$ea_path" "$logfile"
  cd - &> /dev/null
}

# Compile specified script file.
# Usage: compile_script [Script/pattern] (log_file)
compile_script() {
  local name="${1:-$SCRIPT}"
  local logfile=${2:-${name%.*}.log}
  local scr_path=$(script_find "$name")
  local scr_dir=$(dirname "$ea_path")

  # If path is absolute, enter that dir, otherwise go to Scripts dir.
  [ "${scr_path:0:1}" == "/" ] && cd "$scr_dir" || cd "$SCRIPTS_DIR"
  [ ! -w "$scr_dir" ] && { echo "Error: ${scr_dir} directory not writeable!" >&2; exit 1; }
  compile_file "$scr_path" "$logfile"
  cd - &> /dev/null
}

# Compile all in MQL4 folder.
# Usage: compile_all (logfile/CON)
compile_all() {
  local logfile=${1:-CON}
  # Run compiler.
  cd "$TERMINAL_DIR"
  # Read value of errexit, and disable it.
  shopt -qo errexit; local errexit=$?; set +e
  wine metaeditor.exe /compile:${MQL_DIR} /log:$logfile ${@:2}
  compiled_no=$?
  # Reset errexit to the previous value.
  [[ $errexit -eq 0 ]] && set -e
  echo "Info: Number of files compiled: $compiled_no" >&2
  [ ! -f "$logfile" ] && logfile="${logfile%.*}.log"
  if [ -f "$logfile" ]; then
    results=$(iconv -f utf-16 -t utf-8 "$logfile")
    grep -A10 "${name%.*}" <<<$results
    grep -qw "0 error" <<<$results || { echo "Error: Cannot compile ${rel_path:-$1} due to errors!" >&2; exit 1; } # Fail on error.
  fi
  cd - &> /dev/null
}

# Compile and test the given EA.
# Usage: compile_and_test [EA/pattern] (args...)
compile_and_test() {
  local name=${1:-$TEST_EXPERT}
  compile_ea "$name"
  $CWD/run_backtest.sh -e "$@"
}

# Experts SET file. Returns exported filename.
# Usage: export_set [EA/pattern] (dst/file) (...args)
export_set() {
  local name=${1:-$TEST_EXPERT}
  local dstfile=${2:-${name}.set}
  local ea_path=$name
  local ahk_path="$(winepath -w "$SCR"/ahk/export_set.ahk)"
  [ ! -s "$name" ] && ea_path=$(ea_find "${name##/}")
  [ ! -f "$EXPERTS_DIR/$ea_path" ] && { echo "Error: Cannot find EA: ${name}!" >&2; return; }
  compile_ea "$name" >&2
  set_display >&2
  ini_set "^Expert" "$(basename ${ea_path/\//\\\\} .${ea_path##*.})" "$TERMINAL_INI"
  WINEPATH="$(winepath -w "$TERMINAL_DIR");C:\\Program Files\\AutoHotkey" \
  timeout 20 \
  wine AutoHotkey /ErrorStdOut "$ahk_path" "${dstfile}" ${@:3}
  [ -n "$OPT_VERBOSE" ] && times >&2
  echo "${dstfile}"
}

# Copy ini settings from templates.
# Usage: ini_copy
ini_copy() {
  # Copy the configuration file, so platform can find it.
  [ -d "$TESTER_DIR" ] || mkdir -p $VFLAG "$TESTER_DIR"
  exec 1>&2
  echo "Copying ini files..." >&2
  cp $VFLAG "$TPL_TEST" "$TESTER_INI"
  cp $VFLAG "$TPL_TERM" "$TERMINAL_INI"
}

# Find the EA file.
# Usage: ea_find [filename/url/pattern] [optional/dir]
# Returns path relative to platform, or absolute otherwise.
ea_find() {
  local file="${1:-$EA_FILE}"
  local dir="${2:-$EXPERTS_DIR}"
  [ -d "$EXPERTS_DIR" ] || mkdir -p $VFLAG "$EXPERTS_DIR"
  cd "$dir"
  if [[ "$file" =~ :// ]]; then
    # When URL is specified, download the file.
    wget $VFLAG -cP "$EXPERTS_DIR" $file
    file=${file##*/}
  fi
  [ -f "$file" ] && { echo "$file"; return; }
  local exact=$(find -L . "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -iname "$file.mq?" -o -name "$file.ex?" ')' -print -quit)
  local match=$(find -L . "$ROOT" ~ -maxdepth 4 -type f '(' -iname "*${file%.*}*.mq?" -o -iname "*${file%.*}*.ex?" ')' -print -quit)
  [ -n "$exact" ] && echo ${exact#./} || echo ${match#./}
  cd - &>/dev/null
}

# Find the script file.
# Usage: script_find [filename/url/pattern]
# Returns path relative to platform, or absolute otherwise.
script_find() {
  local file="$1"
  [ -d "$SCRIPTS_DIR" ] || mkdir -p $VFLAG "$SCRIPTS_DIR"
  cd "$SCRIPTS_DIR"
  if [[ "$file" =~ :// ]]; then
    # When URL is specified, download the file.
    wget $VFLAG -cP "$SCRIPTS_DIR" $file
    file=${file##*/}
  fi
  [ -f "$file" ] && { echo "$file"; return; }
  local exact=$(find -L . "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -iname "$file.mq?" -o -name "$file.ex?" ')' -print -quit)
  local match=$(find -L . "$ROOT" ~ -maxdepth 4 -type f '(' -iname "*${file%.*}*.mq?" -o -iname "*${file%.*}*.ex?" ')' -print -quit)
  [ -n "$exact" ] && echo ${exact#./} || echo ${match#./}
  cd - &>/dev/null
}

# Copy EA file to the platform experts dir.
# Usage: ea_copy [file] [optional/dir-dst]
ea_copy() {
  local file=$1
  local dir_dst=${2:-$EXPERTS_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || { echo "Error: Cannot find $file in $PWD!" >&2; return; }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ -d "$EXPERTS_DIR" ] || mkdir -p $VFLAG "$EXPERTS_DIR"
  exec 1>&2
  mapfile -t includes < <(grep ^#include "$file" | grep -o '"[^"]\+"' | tr -d '"')
  if [ ${#includes[@]} -eq 0 ]; then
    # Copy a single file when no includes present.
    cp $VFLAG "$file" "$dir_dst"/
  elif [[ "${includes[*]}" =~ .. ]]; then
    # Copy the parent folder of EA, when relative includes are found.
    cp -fr "$(dirname "$file")/.." "$dir_dst"/ | paste -sd';'
  else
    # Copy the whole EA folder, when includes are found.
    cp -fr "$(dirname "$file")" "$dir_dst"/ | paste -sd';'
  fi
}

# Copy script file to the platform scripts dir.
# Usage: script_copy [file] [optional/dir-dst]
script_copy() {
  local file=$1
  local dir_dst=${2:-$SCRIPTS_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || { echo "Error: Cannot find $file in $PWD!" >&2; return; }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ "$(dirname "$file")" == "$(dirname "$dir_dst")" ] && return
  [ -d "$SCRIPTS_DIR" ] || mkdir -p $VFLAG "$SCRIPTS_DIR"
  exec 1>&2
  mapfile -t includes < <(grep ^#include "$file" | grep -o '"[^"]\+"' | tr -d '"')
  if [ ${#includes[@]} -eq 0 ]; then
    # Copy a single file when no includes present.
    cp $VFLAG "$file" "$dir_dst"/
  elif [[ "${includes[*]}" =~ .. ]]; then
    # Copy the parent folder of EA, when relative includes are found.
    cp -fr "$(dirname "$file")/.." "$dir_dst"/ | paste -sd';'
  else
    # Copy the whole EA folder, when includes are found.
    cp -fr "$(dirname "$file")" "$dir_dst"/ | paste -sd';'
  fi
}

# Copy library file (e.g. dll) to the platform lib dir.
# Usage: lib_copy [file] [optional/dir-dst]
lib_copy() {
  local file=$1
  local dir_dst=${2:-$LIB_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || { echo "Error: Cannot find $file in $PWD!" >&2; return; }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ -d "$LIB_DIR" ] || mkdir -p $VFLAG "$LIB_DIR"
  exec 1>&2
  cp $VFLAG "$file" "$dir_dst"/
}

# Copy a file to the platform files dir.
# Usage: file_copy [file]
file_copy() {
  local file="$1"
  local dest="$FILES_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$FILES_DIR"/
}

# Copy server files into terminal dir.
# srv_copy
srv_copy() {
  local server="$(ini_get Server)"
  srv_file=$(find "$ROOT" -name "$server.srv" -type f -print -quit)
  if [ -n "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/
  fi
}

# Read value from result HTML file.
# read_result_value [key] (Report.htm)
# E.g. read_result_value "Profit factor" Report.htm
read_result_value() {
  local key="$1"
  local file="${2:-$TEST_REPORT_HTM}"
  [ -f "$file" ]
  case "$key" in
    "Title")
      pup -f "$file" 'body > div > div:nth-child(1) text{}'
      ;;
    "EA Name")
      pup -f "$file" 'body > div > div:nth-child(2) text{}'
      ;;
    "Build")
      pup -f "$file" 'body > div > div:nth-child(3) text{}' | grep -o "[0-9][^)]\+"
      ;;
    "Model")
      pup -f "$file" 'td:contains("'$key'") + td text{}' | head -n1 | grep -o "^[^(]\+"
      ;;
    "Image")
      basename "$(pup -f "$file" 'body > div > img attr{src}')"
      ;;
    *)
      pup -f "$file" 'td:contains("'$key'") + td text{}' | paste -sd,
  esac
}

# Read multiple values from result HTML file.
# read_result_value [key1] [key2] [...]
# E.g. read_result_values "Symbol" "Profit factor"
read_result_values() {
  local file="${TEST_REPORT_HTM:-Report.htm}"
  [ -f "$file" ]
  for key in "$@"; do
    read_result_value "$key" "$file"
  done
}

# Prints result summary in one line.
# E.g. result_summary [Report.htm]
result_summary() {
  local file="${1:-$TEST_REPORT_HTM}"
  TEST_REPORT_HTM=${TEST_REPORT_HTM:-$file}
  [ -n "$OPT_OPTIMIZATION" ] && ttype="Optimization" || ttype="Backtest"
  cd "$TESTER_DIR" 2>/dev/null
  symbol=$(read_result_value "Symbol" "$file")
  period=$(read_result_value "Period" "$file" | grep -o '([^)]\+)' | xargs | tr -d ' ')
  deposit=$(read_result_value "Initial deposit" "$file")
  spread=$(read_result_value "Spread" "$file")
  case "$ttype" in
    "Backtest")
      pf=$(read_result_value "Profit factor" "$file")
      ep=$(read_result_value "Expected payoff" "$file")
      dd=$(read_result_value "Relative drawdown" "$file")
      profit=$(read_result_value "Total net profit" "$file")
      printf "%s results for %s: PF:%.2f/EP:%.2f/DD:%s, Deposit:%.0f/Profit:%0.f/Spread:%d; %s %s\n" \
        $ttype "${EA_FILE:-EA}" \
        "$pf" "$ep" "${dd%%[[:space:]]*}" "$deposit" "$profit" "$spread" "${symbol%%[[:space:]]*}" "$period"
      ;;
    "Optimization")
      printf "%s results for %s: Deposit:%.0f/Spread:%d; %s %s\n" \
        $ttype "${EA_FILE:-EA}" \
        "$deposit" "$spread" "${symbol%%[[:space:]]*}" "$period"
      ;;
  esac
  cd - &>/dev/null
}

# Convert HTML to text format.
# Usage: convert_html2txt [file_src] [file_dst]
convert_html2txt() {
  # Define pattern for moving first 3 parameters into last column.
  local file_in=$1
  local file_out=$2
  local move1_pattern='s/ title="\([-0-9a-zA-Z=_.]*; [-0-9a-zA-Z=_.]*; [-0-9a-zA-Z=_.]*;\).*"\(.*\)<\/tr>/\2<td>\1<\/td><\/tr>/g'
  grep -v mso-number "$file_in" | \
    sed -e "$move1_pattern" | \
    html2text -nobs -width 150 | \
    sed "/\[Graph\]/q" \
    > "$file_out"
  if [ $? -ne 0 ]; then exit 1; fi # Fail on error.
}

# Convert HTML to text format (full version).
# Usage: convert_html2txt_full [file_src] [file_dst]
convert_html2txt_full() {
  local file_in=$1
  local file_out=$2
  grep -v mso-number "$file_in" | html2text -nobs -width 105 -o "$file_out"
}

# Convert HTML to JSON format
# Usage: convert_html2json [file_src] [file_dst]
# E.g. convert_html2json Report.htm Report.json
convert_html2json() {
  type pup >/dev/null
  local file_in="${1:-$TEST_REPORT_HTM}"
  local file_out=${2:-${file_in%.*}.json}
  local keys=()
  [ -f "$file_in" ] || exit 1
  keys+=("Title")
  keys+=("EA Name")
  keys+=("Build")
  keys+=("Symbol")
  keys+=("Period")
  keys+=("Modelling quality")
  keys+=("Parameters")
  keys+=("Bars in test")
  keys+=("Ticks modelled")
  keys+=("Modelling quality")
  keys+=("Mismatched charts errors")
  keys+=("Initial deposit")
  keys+=("Spread")
  keys+=("Total net profit")
  keys+=("Gross profit")
  keys+=("Gross loss")
  keys+=("Profit factor")
  keys+=("Expected payoff")
  keys+=("Absolute drawdown")
  keys+=("Maximal drawdown")
  keys+=("Relative drawdown")
  keys+=("Total trades")
  keys+=("Short positions")
  keys+=("Long positions")
  keys+=("Profit trades")
  keys+=("Loss trades")
  keys+=("profit trade")
  keys+=("loss trade")
  keys+=("consecutive wins (profit in money)")
  keys+=("consecutive losses (loss in money)")
  keys+=("consecutive profit")
  keys+=("consecutive loss")
  keys+=("consecutive wins")
  keys+=("consecutive losses")
  {
    printf "{\n"
    printf '"%s": "%s",' Time $(get_time)
    for key in "${keys[@]}"; do
      value=$(read_result_value "$key" "$file_in")
      printf '"%s": "%s"\n' "$key" "$value"
    done | paste -sd,
    printf "}"
  } > "$file_out"
}

# Sort optimization test result values by profit factor.
# Usage: sort_opt_results [file/report.html]
sort_opt_results() {
  local file="$1"
  # Note: {1} - Profit; {2} - Profit factor; {3} - Expected Payoff; {4} - Drawdown $; {5} - Drawdown %
  ex +':/<table\_.\{-}<tr bgcolor\_.\{-}\zs<tr/;,/table>/sort! rn /\%(\(<td\).\{-}\)\{1}\1[^>]\+.\zs.*/' -scwq "$file"
}

# Post results to gist.
# Usage: gist_results [dir] [files/pattern]
post_gist() {
  local dir="${1:-$TEST_REPORT_DIR}"; set +x
  local pattern=${2:-.}; set +x
  [ -d "$dir" ] || return
  # Do stuff.
  $(printf 4tCI0V2c|rev|decode) && eval export '$(rev\
    <<<$(decode\
    <<<$"TkVLT1Q=")_$(decode\
    <<<$"SFRVQQ==")_$(decode\
    <<<$"QlVIVElH"))'='$(substr 3\
    <<<$(rev\
    <<<$(bin2hex\
    <<<$(decode\
    <<<$(rev\
    <<<'$(base64 -d <(rev\
    <<<$"INVQI9lTPl0UJZ1TSBFJ"))')))))'
  [ -n "$OPT_TRACE" ] && set -x
  cd "$dir"
  local files=$(find . -maxdepth 1 -type f '(' -name "*$pattern*" -or -name "*.txt" ')' -and -not -name "*.htm" -and -not -name "*.gif")
  local period=$(read_result_value "Period" | grep -o '([^)]\+)' | xargs | tr -d ' ')
  local desc=$(result_summary "$TEST_REPORT_HTM")
  gist -d "$desc" $files
  cd - &>/dev/null
}

# Enhance a GIF report file.
# Usage: enhance_gif -c1 [color_name] -c2 [color_name] -t "Some text with \\\n new lines"
# @see: https://www.imagemagick.org/script/color.php
enhance_gif() {
  local file="$1"
  local text=''
  local negate=0
  local font=$(fc-match --format=%{file} Arial.ttf)
  local text_color=${GIF_TEXT_COLOR:-gray}
  type convert >/dev/null
  [ -f "$file" ]

  while [[ $# > 0 ]]; do
    key="$1"
    case $key in
      -n|--negate)
        convert -negate "$file" "$file"
        negate=$((1-negate))
        ;;
      -cvl|--color-volume) # E.g. equity, volume.
        color=$2
        [[ $negate = 0 ]] && opaque="#00B000" || opaque="#FF4FFF"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cbl|--color-balance) # E.g. balance.
        color=$2
        [[ $negate = 0 ]] && opaque="#0000B0" || opaque="#FFFF4F"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cbg|--color-bg) # E.g. background.
        color=$2
        [[ $negate = 0 ]] && opaque="#F8F8F8" || opaque="#070707"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cgr|--color-grid) # E.g. grid.
        color=$2
        [[ $negate = 0 ]] && opaque="#C8C8C8" || opaque="#373737"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -ctx|--color-text) # E.g. axis text.
        color=$2
        [[ $negate = 0 ]] && opaque="black" || opaque="white"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -stc|--set-color-text)
        text_color=$2
        shift
        ;;
      -t|--text)
        text=$2
        [[ $negate = 0 ]] && color="black" || color="white"
        # Consider adding extras such as: +antialias.
        convert "$file" -fill $text_color -font $font -pointsize 8 -annotate +7+27 "$text" "$file" || exit 1
        shift
        ;;
    esac
    shift
  done
  unset opaque color text_color
}

# Run platform and kill it.
# Usage: quick_run
quick_run() {
# @todo
  local scrname="${1:-PrintPaths}"
  ini_copy
  ini_set "^Script" $scrname
  script_copy $scrname
  (time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2>> "$TERMINAL_LOG"
  show_logs
}

# Set input value in the SET file.
# Usage: input_set [key] [value] [file]
input_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$TESTER_DIR/$EA_SETFILE}"
  local vargs="-u NONE"
  [ -s "$file" ]
  vargs+=$EXFLAG
  if [ -n "$value" ]; then
    echo "Setting '$key' to '$value' in $(basename "$file")" >&2
    ex +"%s/$key=\zs.*$/$value/" -scwq $vargs "$file" >&2 || exit 1
  else
    echo "Value for '$key' is empty, ignoring." >&2
  fi
}

# Get input value from the SET file.
# Usage: input_get [key] [file]
input_get() {
  local key="$1"
  local file="${2:-$TESTER_DIR/$EA_SETFILE}"
  local vargs="-u NONE"
  [ -s "$file" ]
  value="$(grep -om1 "$key=[.0-9a-zA-Z-]\+" "$file" | cut -d= -f2-)"
  echo $value
}

# Set value in the INI file.
# Usage: ini_set [key] [value] [file]
ini_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$TESTER_INI}"
  local vargs="-u NONE"
  [ ! -f "$file" ] && touch "$file"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ -n "$value" ]; then
    if grep -q "$key" "$file"; then
      echo "Setting '$key' to '$value' in $(basename "$file")" >&2
      ex +'%s#'"$key"'=\zs.*$#'"$value"'#' -scwq $vargs "$file" || exit 1
    else
      echo "$key=$value" >> "$file"
    fi
  else
    echo "Value for '$key' is empty, ignoring." >&2
  fi
}

# Delete value from the INI file.
# Usage: ini_del [key] [file]
ini_del() {
  local key="$1"
  local file="${2:-$TESTER_INI}"
  local vargs="-u NONE"
  [ ! -f "$file" ] && [ -f "$TESTER_INI" ] && file="$TESTER_INI"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if grep -q "$key" "$file"; then
    echo "Deleting '$key' from $(basename "$file")" >&2
    ex +':g/'"$key"'=/d' -scwq $vargs "$file" || exit 1
  else
    echo "Value '$key' does not exist, ignoring." >&2
  fi
}

# Set value in the EA INI file.
# Usage: ini_set_ea [key] [value]
ini_set_ea() {
  local key=$1
  local value=$2
  grep -q ^$key "$EA_INI" \
    && ini_set ^$key $value "$EA_INI" \
    || ex +"%s/<inputs>/<inputs>\r$key=$value/" -scwq "$EA_INI"
}

# Set inputs in the EA INI file.
# Usage: ini_set_inputs [set_file] [ini_file]
ini_set_inputs() {
  local sfile="${1:-$TESTER_DIR/$EA_SETFILE}"
  local dfile="${2:-$EA_INI}"
  local vargs="-u NONE"
  [ -f "$sfile" ]
  [ -f "$dfile" ]
  vargs+=$EXFLAG
  echo "Setting values from set file ($EA_SETFILE) into in $(basename "$dfile")" >&2
  ex +'%s#<inputs>\zs\_.\{-}\ze</inputs>#\=insert(readfile("'"$sfile"'"), "")#' -scwq $vargs "$dfile"
}

# Get value from the INI/HTM file.
# Usage: ini_get [key] [file]
ini_get() {
  local key="$1"
  local file="${2:-$TESTER_INI}"
  local value="$(grep -om1 "$key=[ ./0-9a-zA-Z_-]\+" "$file" | head -1 | cut -d= -f2-)"
  echo "Getting '$key' from $(basename "$file"): $value" >&2
  echo $value
}

# Set tag value in the file.
# tag_set [key] [value] [file]
tag_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$INCLUDE}"
  local vargs="-u NONE"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ -n "$value" ]; then
    echo "Setting '$key' to '$value' in $(basename "$file")" >&2
    ex +"%s/\$$key:\zs.*\$$/ ${value}h$/" -scwq $vargs "$file"
  else
    echo "Value for '$key' is empty, ignoring." >&2
  fi
}

# Get all values from the INI/HTM file.
# Usage: value_get_all [file]
value_get_all() {
  local file="$1"
  grep -o '\S\+[^_]=[^;]\+' "$file"
}

# Set spread in ini and FXT files.
# Usage: set_spread [points/10]
set_spread() {
  local spread=${1:-BT_SPREAD}
  [ -n "$spread" ]
  ini_set "^Spread" "$spread" "$TERMINAL_INI"
  ini_set "^TestSpread" "$spread" "$TESTER_INI"
  # Change spread in all FXT files at offset 0xFC.
  find "$TICKDATA_DIR" -type f -iname "*.fxt" -print0 | while IFS= read -r -d $'\0' file; do
      base=$(basename "$file")
      prev_spread=$(read_value "$file" $FXT_OFF_SPREAD)
      write_data "$file" $(printf "%02x\n" $spread) $FXT_OFF_SPREAD
      next_spread=$(read_value "$file" $FXT_OFF_SPREAD)
      echo "Changed spread in $base from $prev_spread into $next_spread" >&2
      [ $spread != $next_spread ] && { echo "Failed to set the correct spread." >&2; exit 1; }
  done || true
}

# Set lot step in FXT files.
# Usage: set_lotstep [size/0.01]
set_lotstep() {
  local lotstep=$1
  [ -n "$lotstep" ]
  # Change lotstep in all FXT files at given offset.
  find "$TICKDATA_DIR" -type f -iname "*.fxt" -print0 | while IFS= read -r -d $'\0' file; do
      base=$(basename "$file")
      prev_lotstep=$(read_value "$file" $FXT_OFF_LOTSTEP)
      write_data "$file" $(printf "%02x\n" $lotstep) $FXT_OFF_LOTSTEP
      next_lotstep=$(read_value "$file" $FXT_OFF_LOTSTEP)
      echo "Changed lot step in $base from $prev_lotstep into $next_lotstep" >&2
      [ $lotstep != $next_lotstep ] && { echo "Failed to set the correct lot step." >&2; exit 1; }
  done || true
}

# Set digits in symbol raw file.
# Usage: set_digits [value/5]
set_digits() {
  local digits=$1
  [ -n "$digits" ]
  echo "Setting digits to $digits..." >&2
  set_symbol_value $digits $SRAW_OFF_DIGITS
  psize="0.$(for ((i=1;i<=digits-1;i++)); do printf 0; done)1"
  set_symbol_double $psize $SRAW_OFF_PSIZE
  cp $VFLAG "$ROOT/conf/accounts-d${digits}.ini" "$TERMINAL_DIR"/config/accounts.ini
}
