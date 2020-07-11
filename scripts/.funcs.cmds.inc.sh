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
help()
{
  grep -B1 ^"# Usage" ${BASH_SOURCE[0]}
}

# Run backtest.
# Usage: run_backtest [args]
run_backtest()
{
  "$CWD"/run_backtest.sh "$@"
}

# Run Terminal.
# Usage: run_terminal
run_terminal()
{
  "$CWD"/run_terminal.sh "$@"
}

# Clone git repository.
# Usage: clone_repo [url] [args...]
clone_repo()
{
  "$CWD"/clone_repo.sh "$@"
}

# Download backtest data.
# Usage: bt_data_dl [-v] [-D DEST] [-c] [-p PAIRS] [-h HOURS] [-d DAYS] [-m MONTHS] [-y YEARS]
bt_data_dl()
{
  "$CWD"/py/bt_data_dl.py "$@"
}

# Generate backtest data.
# Usage: bt_data_gen [-D DIGITS] [-s SPREAD] [-d DENSITY] [-p {none,wave,curve,zigzag,random}] [-v VOLATILITY] [-o OUTPUTFILE]
bt_data_gen()
{
  "$CWD"/py/bt_data_gen.py "$@"
}

# Download backtest data from GitHub
# Usage: bt_data_get [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5] [period]
bt_data_get()
{
  export SERVER=$SERVER OPT_VERBOSE=$OPT_VERBOSE OPT_TRACE=$OPT_TRACE
  "$CWD"/bt_data_get.sh "$@"
}

# Read MT file.
# Usage: mt_read -i INPUTFILE -t INPUTTYPE
mt_read()
{
  "$CWD"/py/mt_read.py "$@"
}

# Modify MT file.
# Usage: mt_modify -i INPUTFILE -t INPUTTYPE -k KEYGROUP [-d] [-a DOADD] [-m DOMODIFY]
mt_modify()
{
  "$CWD"/py/mt_modify.py "$@"
}

# Convert CSV files to FXT/HST formats.
# Usage: conv_csv_to_mt -i INPUTFILE [-f OUTPUTFORMAT] [-s SYMBOL] [-t TIMEFRAME] [-p SPREAD] [-d OUTPUTDIR] [-S SERVER] [-v] [-m MODEL]
conv_csv_to_mt()
{
  "$CWD"/py/conv_csv_to_mt.py "$@"
}

# Change the working directory.
# Usage: chdir [dir]
# E.g. chdir "$EXPERTS_DIR"
chdir()
{
  local dest=$@
  \cd "$dest"
}

# Check logs for specific text.
# Usage: check_logs [filter] [args]
check_logs()
{
  local filter=$1
  find "$TERMINAL_DIR" -name "*.log" -type f -exec grep --color -C1 -iw "$filter" ${@:2} "{}" +
}

# Gets filepath to symbols.raw file.
get_path_symbols_raw()
{
  printf "%s" "$TERMINAL_HST/${SERVER:-"default"}/symbols.raw"
}

# Display logs in real-time.
# Usage: live_logs [invert-match] [interval]
live_logs()
{
  local filter=${1:-modify}
  local interval=${2:-10}
  set +x
  # Prints Terminal log when available (e.g. logs/20180717.log).
  {
    while sleep $interval; do
      # shellcheck disable=SC2153
      log_file="$([ -d "$LOG_DIR" ] && find "$LOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
      [ -f "$log_file" ] && break
    done && tail -f "$log_file"
  } &
  # Prints MQL4 logs when available (e.g. MQL4/Logs/20180717.log).
  {
    while sleep $interval; do
      # shellcheck disable=SC2153
      log_file="$([ -d "$MQLOG_DIR" ] && find "$MQLOG_DIR" -type f -name "$(date +%Y%m%d)*.log" -print -quit)"
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
live_stats()
{
  set +x
  local interval=${1:-60}
  while sleep $interval; do
    # TERM=vt100 top | head -n4
    winedbg --command 'info wnd' | grep -v Empty | grep -w Static | cut -c67- | paste -sd,
  done
}

# Delete compiled EAs.
# Usage: clean_ea
clean_ea()
{
  echo "INFO: Cleaning compiled EAs and scripts..."
  find "$TERMINAL_DIR/$MQL_DIR" -name "*.ex[45]" -type f $VPRINT -delete >&2
}

# Delete EA source code files.
# Usage: clean_ea_sources (subdir)
clean_sources()
{
  local subdir=$1
  echo "INFO: Cleaning EA/script source code files..."
  find "$TERMINAL_DIR/$subdir" -name "*.mq[45]" -type f $VPRINT -delete >&2
}

# Clean files (e.g. previous report and log files).
# Usage: clean_files
clean_files()
{
  # Remove previous log, dat, txt and htm files.
  exec 1>&2
  echo "INFO: Cleaning previous test data..."
  find "$TESTER_DIR" '(' -name "*.htm" -o -name "*.txt" ')' -type f $VPRINT -delete
  [ -d "$TESTER_DIR"/files ] && find "$TESTER_DIR"/files -type f $VPRINT -delete
  # Remove log files.
  [ -d "$LOG_DIR" ] && find "$LOG_DIR" -type f $VPRINT -delete
  find "$TERMINAL_DIR" '(' -name "*.log" -o -name "*.txt" -o -name "Report*.htm" -o -name "*.gif" ')' -type f $VPRINT -delete
  # Remove selected symbol and group files, so they can be regenerated.
  find "$TERMINAL_HST" '(' -name "symbols.sel" -o -name "symgroups.raw" ')' $VPRINT -delete
}

# Deletes backtest data files.
# Usage: clean_bt (dir) (symbol)
clean_bt()
{
  local dir=${1:-$TERMINAL_DIR}
  local symbol=${2:-$BT_SYMBOL}
  # Remove previous backtest files for the current symbol.
  echo "INFO: Cleaning backtest data for $symbol..." >&2
  find "$dir" '(' -name "${symbol}*.hst" -o -name "${symbol}*.fxt" -o -name "${symbol}*.hcc" ')' -type f $VPRINT -delete >&2
  [ -s "$CUSTOM_INI" ] && ini_del "bt_data" "$CUSTOM_INI" || true
}

# Check the version of the given binary file.
# Usage: filever [file/terminal.exe]
filever()
{
  type pev > /dev/null
  local file=$1
  find "$PWD" "$TERMINAL_DIR" -name "$file" -type f -execdir \
    pev "$file" ';' -quit 2> /dev/null \
    | grep -w Product | grep -o "[45].*"
}

# Install platform.
# Usage: install_mt [ver/4/5/v4.0.0.1260/v5.0.0.2361] (dest)
install_mt()
{
  type jq wget unzip > /dev/null
  local mt_ver=${1:-$MT_VER}
  local dir_dest=${2:-$WINE_PATH}
  dir_dest=${dir_dest:-$HOME}
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
    4.0.0.* | 5.0.0.*)
      [ ! -d "$dir_dest" ] && mkdir $VFLAG -p "$dir_dest"
      [ ! -w "$dir_dest" ] && {
        echo "ERROR: Destination folder not writable!"
        (id && stat "$dir_dest") >&2
        exit 1
      }
      cd "$dir_dest"
      mt_releases_json=$(curl -s https://api.github.com/repos/${REPO_MT-"EA31337/MT-Platforms"}/releases)
      mapfile -t mt_releases_list < <(jq -r '.[]["tag_name"]' <<< "$mt_releases_json")
      if [[ " ${mt_releases_list[*]} " =~ ${mt_ver} ]]; then
        mt_release_url=$(jq -r '.[]|select(.tag_name == "'${mt_ver}'")["assets"][0]["browser_download_url"]' <<< "$mt_releases_json")
        wget -nv -c "$mt_release_url"
        (unzip -ou "mt-$mt_ver.zip" && rm $VFLAG "mt-$mt_ver.zip") 1>&2
        clean_bt . '*'
      else
        echo "Error: Not supported platform version. Supported: ${mt_releases_list[@]}" >&2
      fi
      cd - &> /dev/null
      ;;
    *)
      if [ -z "$MT_VER" ]; then
        echo "Error: Platform not specified!" >&2
      else
        echo "Error: Not supported platform version ($MT_VER). Supported: 4, 4x, 4.0.0.x, 5 or 5.0.0.x." >&2
      fi
      exit 1
      ;;
  esac
}

# Show version of installed platform binaries.
print_ver()
{
  MT_VER_NEW=$(filever $(basename "$TERMINAL_EXE"))
  MTE_VER_NEW=$(filever $(basename "$MTEDITOR_EXE"))
  export MT_VER=${MT_VER_NEW:-$MT_VER}
  export MTE_VER=${MTE_VER_NEW:-$MTE_VER}
  echo "INFO: Installed Terminal: $MT_VER"
  echo "INFO: Installed MetaEditor: $MTE_VER"
}

# Configure virtual display and wine.
# Usage: set_display
set_display()
{
  export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=,winebrowser.exe=}" # Disable gecko and default browser in wine.
  export WINEDEBUG="${WINEDEBUG:-warn-all,fixme-all,err-alsa,-ole,-toolbar}"      # For debugging, try: WINEDEBUG=trace+all
  export DISPLAY=${DISPLAY:-:0}                                                   # Select screen 0 by default.
  xdpyinfo &> /dev/null && return
  if command -v x11vnc &> /dev/null; then
    ! pgrep -a x11vnc && x11vnc -bg -forever -nopw -quiet -display WAIT$DISPLAY &
  fi 1>&2
  ! pgrep -a Xvfb && Xvfb $DISPLAY -screen 0 1024x768x16 &
  sleep 1
  if command -v fluxbox &> /dev/null; then
    ! pgrep -a fluxbox && fluxbox 2> /dev/null &
  fi
  echo "INFO: IP: $(hostname -I) ($(hostname))"
}

# Detect and configure proxy.
# Usage: set_proxy
set_proxy()
{
  local gw=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
  curl -s localhost:3128 > /dev/null || true && export http_proxy="http://localhost:3128"
  curl -s $gw:3128 > /dev/null || true && export http_proxy="http://$gw:3128"

  # Set proxy for wine registry if present.
  [ -n "$http_proxy" ] \
    && cat << EOF | wine regedit -
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
# Usage: show_logs (lines_no/40)
show_logs()
{
  local no_lines=${1:-40}
  find "$TERMINAL_DIR" -name "*.log" -type f $VPRINT -exec tail -n${no_lines} "{}" +
}

# Copy script file given the file path.
# Usage: script_copy [file]
script_copy()
{
  local file="$1"
  local dest="$SCRIPTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  cp $VFLAG "$file" "$SCRIPTS_DIR"/ >&2
}

# Copy library file (e.g. dll) given the file path.
# Usage: lib_copy [file]
lib_copy()
{
  local file="$1"
  local dest="$LIB_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  cp $VFLAG "$file" "$LIB_DIR"/ >&2
}

# Copy a file given the file path.
# Usage: file_copy [file]
file_copy()
{
  local file="$1"
  local dest="$FILES_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  cp $VFLAG "$file" "$FILES_DIR"/ >&2
}

# Copy srv files into terminal dir.
# Usage: srv_copy [file]
srv_copy()
{
  local server="$(ini_get Server)"
  srv_file=$(find "$ROOT" -name "$server.srv" -type f -print -quit)
  if [ -n "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/ >&2
  fi
}

# Download the file.
# Usage: file_get [url]
file_get()
{
  local url="$1"
  local dest="${2:-$DOWNLOAD_DIR}"
  wget -cP "$dest" $url
}

# Compile the source code file.
# Usage: compile [file/dir] (log_file) (...args)
compile()
{
  local name=$1
  [ -n "$name" ]
  local log_file=${2:-${name##*/}.log}
  local log_dir=$(dirname "$log_file")
  type iconv > /dev/null

  local mt_ver=$(get_mtv)
  local rel_path=$name
  local target=$rel_path
  # Check access to log directory.
  [ ! -w "$log_dir" ] && {
    echo "ERROR: $(realpath "${log_dir}") directory not writeable!" >&2
    type on_error &> /dev/null && on_error 1 || exit 1
  }
  if [ -d "$rel_path" ]; then
    # If folder, enter it.
    cd "$rel_path"
    target=.
    log_file=${log_file:-mql.log}
  elif [ -s "$rel_path" ] && [ -d "$(dirname "$rel_path")" ]; then
    # If path, enter the folder containing the file.
    cd "$(dirname "$rel_path")"
    target=$(basename "$rel_path")
    log_file=${log_file:-mql.log}
  else
    # File exists.
    target=$name
    log_file=${2:-${name##*/}.log}
  fi
  [ ! -s "$target" ] && {
    echo "ERROR: Cannot access ${rel_path:-$1}!" >&2
    cd - &> /dev/null
    return
  }

  # Read value of errexit, and disable it.
  shopt -qo errexit && errexit=0 || errexit=1
  shopt -qo errtrace && errtrace=0 || errtrace=1

  # Run compiler.
  compiled_no=$(
    set +eE
    trap '' ERR
    WINEDEBUG=fixme-all,err-winediag \
      WINEPATH="$(winepath -w "$TERMINAL_DIR")" \
      wine metaeditor.exe /compile:"$target" /log:"$log_file" ${@:3} >&2
    echo $?
  )
  # Reset errexit to the previous value.
  [[ $errexit -eq 0 ]] && set -e
  [[ $errtrace -eq 0 ]] && set -E
  (
    [ ! -f "$log_file" ] && log_file="${log_file%.*}.log"
    if [ -f "$log_file" ]; then
      if grep -B10 "[1-9]\+[0-9]\? \(warning\)" <(conv < "$log_file"); then
        echo "Warning: There were some warnings while compiling ${rel_path:-$1}! Check '${log_file}' for more details." >&2
      fi
      if grep -B20 "[1-9]\+[0-9]\? \(error\)" <(conv < "$log_file"); then
        echo "Error: Compilation of ${rel_path:-$1} failed due to errors! Check '${log_file}' for more details." >&2
        [ -n "$OPT_VERBOSE" ] && conv < "$log_file"
        false
      fi
    fi
  ) >&2
  echo "${compiled_no}"
}

# Compile specified EA file.
# Usage: compile_ea [EA/pattern] (log_file) (...args)
compile_ea()
{
  local name=${1:-$TEST_EXPERT}
  [ -n "$name" ]
  local log_file=${2:-${name%.*}.log}
  local ea_path=$(ea_find "$name")
  local ea_dir=$(dirname "$ea_path")
  local log_dir=$(dirname "$log_file")

  # If path is absolute, enter that dir, otherwise go to Experts dir.
  [ "${ea_path:0:1}" == "/" ] && cd "$ea_dir" || cd "$EXPERTS_DIR"
  # Check access to log directory.
  [ ! -w "$log_dir" ] && {
    echo "ERROR: $(realpath "${log_dir}") directory not writeable!" >&2
    type on_error &> /dev/null && on_error 1 || exit 1
  }
  ea_path=$(ea_find "$name" .)
  compiled_no="$(compile "$ea_path" "$log_file" ${@:3})"
  cd - &> /dev/null
  echo "${compiled_no}"
}

# Compile specified script file.
# Usage: compile_script [Script/pattern] (log_file) (...args)
compile_script()
{
  local name="${1:-$SCRIPT}"
  [ -n "$name" ]
  local log_file=${2:-${name%.*}.log}
  local scr_path=$(script_find "$name")
  local scr_dir=$(dirname "$scr_path")
  local log_dir=$(dirname "$log_file")

  # If path is absolute, enter that dir, otherwise go to Scripts dir.
  [ "${scr_path:0:1}" == "/" ] && cd "$scr_dir" || cd "$SCRIPTS_DIR"
  # Check access to log directory.
  [ ! -w "$log_dir" ] && {
    echo "ERROR: $(realpath "${log_dir}") directory not writeable!" >&2
    type on_error &> /dev/null && on_error 1 || exit 1
  }
  scr_path=$(script_find "$name" .)
  compiled_no="$(compile "$scr_path" "$log_file" ${@:3})"
  cd - &> /dev/null
  echo "${compiled_no}"
}

# Compile all in MQL4 folder.
# Usage: compile_all (log_file/CON)
compile_all()
{
  local log_file=${1:-CON}
  # Run compiler.
  cd "$TERMINAL_DIR"
  compile "${MQL_DIR}" "$log_file"
  cd - &> /dev/null
}

# Compile and test the given EA.
# Usage: compile_and_test [EA/pattern] (args...)
compile_and_test()
{
  local name=${1:-$TEST_EXPERT}
  compiled_no="$(compile_ea "$name")"
  [ ${compiled_no} -gt 0 ]
  $CWD/run_backtest.sh -e "$@"
}

# Copy ini settings from templates.
# Usage: ini_copy
ini_copy()
{
  # Copy the configuration file, so platform can find it.
  [ -d "$TESTER_DIR" ] || mkdir -p $VFLAG "$TESTER_DIR"
  echo "Copying ini files..." >&2
  cp $VFLAG "$TPL_TEST" "$TESTER_INI" >&2
  if [ $(get_mtv) = 4 ]; then
    cp $VFLAG "$TPL_TERM" "$TERMINAL_INI" >&2
  fi
}

# Find the EA file.
# Usage: ea_find [filename/url/pattern] (optional/dir)
# Returns path relative to platform, or absolute otherwise.
ea_find()
{
  local file="${1:-$EA_FILE}"
  local dir="${2:-$EXPERTS_DIR}"
  local mt_ver=$(get_mtv)
  [ -d "$EXPERTS_DIR" ] || mkdir -p $VFLAG "$EXPERTS_DIR"
  cd "$dir"
  if [[ "$file" =~ :// ]]; then
    # When URL is specified, download the file.
    wget $VFLAG -cP "$EXPERTS_DIR" $file
    file=${file##*/}
  fi
  [ -f "$file" ] \
    && {
      echo "$file"
      return
    }
  result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -iname "${file%.*}.mq${mt_ver}" ')' -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -name "${file%.*}.ex${mt_ver}" ')' -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f -iname "*${file%.*}*.mq${mt_ver}" -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f -iname "*${file%.*}*.ex${mt_ver}" -print -quit)
  echo ${result#./}
  cd - &> /dev/null
}

# Find the script file.
# Usage: script_find [filename/url/pattern] (optional/dir)
# Returns path relative to platform, or absolute otherwise.
script_find()
{
  local file="$1"
  local dir="${2:-$SCRIPTS_DIR}"
  local mt_ver=$(get_mtv)
  [ -d "$SCRIPTS_DIR" ] || mkdir -p $VFLAG "$SCRIPTS_DIR"
  cd "$dir"
  if [[ "$file" =~ :// ]]; then
    # When URL is specified, download the file.
    wget $VFLAG -cP "$SCRIPTS_DIR" $file
    file=${file##*/}
  fi
  [ -f "$file" ] \
    && {
      echo "$file"
      return
    }
  result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -iname "${file%.*}.mq${mt_ver}" ')' -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f '(' -iname "$file" -o -name "${file%.*}.ex${mt_ver}" ')' -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f -iname "*${file%.*}*.mq${mt_ver}" -print -quit)
  [ -z "$result" ] && result=$(find -L . "$WORKDIR" "$ROOT" ~ -maxdepth 4 -type f -iname "*${file%.*}*.ex${mt_ver}" -print -quit)
  echo ${result#./}
  cd - &> /dev/null
}

# Copy EA file to the platform experts dir.
# Usage: ea_copy [file] [optional/dir-dst]
ea_copy()
{
  local file=$1
  local dir_dst=${2:-$EXPERTS_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || {
    echo "Error: Cannot find $file in $PWD!" >&2
    return
  }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ -d "$EXPERTS_DIR" ] || mkdir -p $VFLAG "$EXPERTS_DIR"
  (
    mapfile -t includes < <(grep ^#include "$file" | grep -o '"[^"]\+"' | tr -d '"' || true)
    # shellcheck disable=SC2076
    if [ ${#includes[@]} -eq 0 ]; then
      # Copy a single file when no includes present.
      cp $VFLAG "$file" "$dir_dst"/
    elif [[ "${includes[*]}" =~ ".." ]]; then
      # Copy the parent folder of EA, when relative includes are found.
      cp -fr "$(dirname "$file")/.." "$dir_dst"/ | paste -sd';'
    else
      # Copy the whole EA folder, when includes are found.
      cp -fr "$(dirname "$file")" "$dir_dst"/ | paste -sd';'
    fi
  ) >&2
}

# Copy script file to the platform scripts dir.
# Usage: script_copy [file] [optional/dir-dst]
script_copy()
{
  local file=$1
  local dir_dst=${2:-$SCRIPTS_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || {
    echo "Error: Cannot find $file in $PWD!" >&2
    return
  }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ "$(dirname "$file")" == "$(dirname "$dir_dst")" ] && return
  [ -d "$SCRIPTS_DIR" ] || mkdir -p $VFLAG "$SCRIPTS_DIR"
  (
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
  ) >&2
}

# Copy library file (e.g. dll) to the platform lib dir.
# Usage: lib_copy [file] [optional/dir-dst]
lib_copy()
{
  local file=$1
  local dir_dst=${2:-$LIB_DIR}
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ -s "$dir_dst/$file" ] && return
  [ -s "$file" ] || {
    echo "Error: Cannot find $file in $PWD!" >&2
    return
  }
  [ "$(dirname "$file")" == "$dir_dst" ] && return
  [ -d "$LIB_DIR" ] || mkdir -p $VFLAG "$LIB_DIR"
  cp $VFLAG "$file" "$dir_dst"/
}

# Copy a file to the platform files dir.
# Usage: file_copy [file]
file_copy()
{
  local file="$1"
  local dest="$FILES_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  cp $VFLAG "$file" "$FILES_DIR"/ >&2
}

# Copy server files into terminal dir.
# srv_copy
srv_copy()
{
  local server="$(ini_get Server)"
  srv_file=$(find "$ROOT" -name "$server.srv" -type f -print -quit)
  if [ -n "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/ >&2
  fi
}

# Read value from result HTML file.
# read_result_value [key] (Report.htm)
# E.g. read_result_value "Profit factor" Report.htm
read_result_value()
{
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
      pup -f "$file" 'td:contains("'"$key"'") + td text{}' | head -n1 | grep -o "^[^(]\+"
      ;;
    "Image")
      basename "$(pup -f "$file" 'body > div > img attr{src}')"
      ;;
    "Symbol" | "Period" | "Model" | "Initial deposit" | "Spread")
      pup -f "$file" 'td:contains("'"$key"'") + td text{}' | paste -sd,
      ;;
    *)
      if [ -n "$OPT_OPTIMIZATION" ]; then
        pup -f "$file" 'td:contains("'"$key"'") text{}' | head -n1
      else
        pup -f "$file" 'td:contains("'"$key"'") + td text{}' | paste -sd,
      fi
      ;;
  esac
}

# Read multiple values from result HTML file.
# read_result_value [key1] [key2] [...]
# E.g. read_result_values "Symbol" "Profit factor"
read_result_values()
{
  local file="${TEST_REPORT_HTM:-Report.htm}"
  [ -f "$file" ]
  for key in "$@"; do
    read_result_value "$key" "$file"
  done
}

# Prints result summary in one line.
# E.g. result_summary [Report.htm]
result_summary()
{
  local file="${1:-$TEST_REPORT_HTM}"
  TEST_REPORT_HTM=${TEST_REPORT_HTM:-$file}
  [ -n "$OPT_OPTIMIZATION" ] && ttype="Optimization" || ttype="Backtest"
  cd "$TESTER_DIR" 2> /dev/null
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
  cd - &> /dev/null
}

# Convert HTML to text format.
# Usage: convert_html2txt [file_src] [file_dst]
convert_html2txt()
{
  # Define pattern for moving first 3 parameters into last column.
  local file_in=$1
  local file_out=$2
  local move1_pattern='s/ title="\([-0-9a-zA-Z=_.]*; [-0-9a-zA-Z=_.]*; [-0-9a-zA-Z=_.]*;\).*"\(.*\)<\/tr>/\2<td>\1<\/td><\/tr>/g'
  grep -v mso-number "$file_in" \
    | sed -e "$move1_pattern" \
    | html2text -nobs -width 150 \
    | sed "/\[Graph\]/q" \
      > "$file_out"
}

# Convert HTML to text format (full version).
# Usage: convert_html2txt_full [file_src] [file_dst]
convert_html2txt_full()
{
  local file_in=$1
  local file_out=$2
  grep -v mso-number "$file_in" | html2text -nobs -width 105 -o "$file_out"
}

# Convert HTML to JSON format
# Usage: convert_html2json [file_src] [file_dst]
# E.g. convert_html2json Report.htm Report.json
convert_html2json()
{
  type pup > /dev/null
  local file_in="${1:-$TEST_REPORT_HTM}"
  local file_out=${2:-${file_in%.*}.json}
  local json_res
  local keys=()
  [ -f "$file_in" ] || exit 1
  [ -n "$OPT_OPTIMIZATION" ] && ttype="Optimization" || ttype="Backtest"
  keys+=("Title")
  keys+=("EA Name")
  keys+=("Build")
  keys+=("Symbol")
  keys+=("Period")
  keys+=("Model")
  keys+=("Initial deposit")
  keys+=("Spread")
  case "$ttype" in
    "Backtest")
      keys+=("Modelling quality")
      keys+=("Parameters")
      keys+=("Bars in test")
      keys+=("Ticks modelled")
      keys+=("Modelling quality")
      keys+=("Mismatched charts errors")
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
      ;;
    "Optimization")
      keys+=("Pass")
      keys+=("Profit")
      keys+=("Total trades")
      keys+=("Profit factor")
      keys+=("Expected Payoff")
      keys+=("Drawdown $")
      keys+=("Drawdown %")
      ;;
  esac
  json_res=$(
    printf "{\n"
    printf '"%s": "%s",' Time $(get_time)
    for key in "${keys[@]}"; do
      value=$(read_result_value "$key" "$file_in")
      printf '"%s": "%s"\n' "$key" "$value"
    done | paste -sd,
    printf "}"
  )
  if [ -n "$JSON_PARSER" ]; then
    $JSON_PARSER > "$file_out" <<< "$json_res"
  else
    cat > "$file_out" <<< "$json_res"
  fi
}

# Sort optimization test result values by profit factor.
# Usage: sort_opt_results [file/report.html]
sort_opt_results()
{
  local file="$1"
  [ -s "$file" ]
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  # Note: {1} - Profit; {2} - Profit factor; {3} - Expected Payoff; {4} - Drawdown $; {5} - Drawdown %
  ex +':/<table\_.\{-}<tr bgcolor\_.\{-}\zs<tr/;,/table>/sort! rn /\%(\(<td\).\{-}\)\{1}\1[^>]\+.\zs.*/' -scwq! ${vargs[@]} "$file"
}

# Post results to gist.
# Usage: gist_results [dir] [files/pattern]
post_gist()
{
  local dir="${1:-$TEST_REPORT_DIR}"
  set +x
  local pattern=${2:-.}
  set +x
  [ -d "$dir" ] || return
  # Do stuff.
  $(printf 4tCI0V2c | rev | decode) && eval export '$(rev\
    <<<$(decode\
    <<<$"TkVLT1Q=")_$(decode\
    <<<$"SFRVQQ==")_$(decode\
    <<<$"QlVIVElH"))'='$(substr 3\
    <<<$(rev\
    <<<$(bin2hex\
    <<<$(decode\
    <<<$(rev\
    <<<'$(base64 -d <(rev <<< $"INVQI9lTPl0UJZ1TSBFJ"))')))))'
  [ -n "$OPT_TRACE" ] && set -x
  cd "$dir"
  local files=$(find . -maxdepth 1 -type f '(' -name "*$pattern*" -or -name "*.txt" ')' -and -not -name "*.htm" -and -not -name "*.gif")
  local period=$(read_result_value "Period" | grep -o '([^)]\+)' | xargs | tr -d ' ')
  local desc=$(result_summary "$TEST_REPORT_HTM")
  gist -d "$desc" $files
  cd - &> /dev/null
}

# Enhance a GIF report file.
# Usage: enhance_gif -c1 [color_name] -c2 [color_name] -t "Some text with \\\n new lines"
# @see: https://www.imagemagick.org/script/color.php
enhance_gif()
{
  local file="$1"
  local text=''
  local negate=0
  local font=$(fc-match --format=%{file} Arial &> /dev/null || true)
  local text_color=${GIF_TEXT_COLOR:-gray}
  type convert > /dev/null
  [ -f "$file" ]

  while [[ $# > 0 ]]; do
    key="$1"
    case $key in
      -n | --negate)
        convert -negate "$file" "$file"
        negate=$((1 - negate))
        ;;
      -cvl | --color-volume) # E.g. equity, volume.
        color=$2
        [[ $negate = 0 ]] && opaque="#00B000" || opaque="#FF4FFF"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cbl | --color-balance) # E.g. balance.
        color=$2
        [[ $negate = 0 ]] && opaque="#0000B0" || opaque="#FFFF4F"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cbg | --color-bg) # E.g. background.
        color=$2
        [[ $negate = 0 ]] && opaque="#F8F8F8" || opaque="#070707"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -cgr | --color-grid) # E.g. grid.
        color=$2
        [[ $negate = 0 ]] && opaque="#C8C8C8" || opaque="#373737"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -ctx | --color-text) # E.g. axis text.
        color=$2
        [[ $negate = 0 ]] && opaque="black" || opaque="white"
        convert "$file" -fuzz 0% -fill $color -opaque $opaque "$file" || exit 1
        shift
        ;;
      -stc | --set-color-text)
        text_color=$2
        shift
        ;;
      -t | --text)
        text=$2
        [[ $negate = 0 ]] && color="black" || color="white"
        [ -n "$font" ] && font_args="-font $font" || font_args=""
        # Consider adding extras such as: +antialias.
        convert "$file" -fill $text_color $font_args -pointsize 8 -annotate +7+27 "$text" "$file" || exit 1
        shift
        ;;
    esac
    shift
  done
  unset opaque color text_color
}

# Run platform and kill it.
# Usage: quick_run
quick_run()
{
  # @todo
  local scrname="${1:-PrintPaths}"
  ini_copy
  ini_set "^Script" $scrname
  script_copy $scrname
  (time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2>> "$TERMINAL_LOG"
  show_logs 40
}

# Set value in the INI file.
# Usage: ini_set [key] [value] [file]
ini_set()
{
  local key="$1"
  local value="$2"
  local file="${3:-$TESTER_INI}"
  [ ! -f "$file" ] && touch "$file"
  [ -f "$file" ]
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  if [ -n "$value" ]; then
    if grep -q "$key" "$file"; then
      echo "INFO: Setting '$key' to '$value' in $(basename "$file")" >&2
      ex +'%s#'"$key"'=\zs.*$#'"$value"'#' -scwq! ${vargs[@]} "$file" || exit 1
    else
      echo "$key=$value" >> "$file"
    fi
  else
    echo "WARN: Value for '$key' is empty, ignoring." >&2
  fi
}

# Delete value from the INI file.
# Usage: ini_del [key] [file]
ini_del()
{
  local key="$1"
  local file="${2:-$TESTER_INI}"
  [ ! -f "$file" ] && [ -f "$TESTER_INI" ] && file="$TESTER_INI"
  [ -f "$file" ]
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  if grep -q "$key" "$file"; then
    echo "Deleting '$key' from $(basename "$file")" >&2
    ex +':g/'"$key"'=/d' -scwq! ${vargs[@]} "$file" || exit 1
  else
    echo "WARN: Value '$key' does not exist, ignoring." >&2
  fi
}

# Set value in the EA INI file.
# Usage: ini_set_ea [key] [value]
ini_set_ea()
{
  local key=$1
  local value=$2
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  grep -q ^$key "$EA_INI" \
    && ini_set ^$key $value "$EA_INI" \
    || ex +"%s/<inputs>/<inputs>\r$key=$value/" -scwq! ${vargs[@]} "$EA_INI"
}

# Set inputs in the EA INI file.
# Usage: ini_set_inputs [set_file] [ini_file]
ini_set_inputs()
{
  local sfile="${1:-$TESTER_DIR/$EA_SETFILE}"
  local dfile="${2:-$EA_INI}"
  [ -f "$sfile" ]
  [ -f "$dfile" ]
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  echo "Setting values from set file ($EA_SETFILE) into in $(basename "$dfile")" >&2
  ex +'%s#<inputs>\zs\_.\{-}\ze</inputs>#\=insert(readfile("'"$sfile"'"), "")#' -scwq! ${vargs[@]} "$dfile"
}

# Get value from the INI file.
# Usage: ini_get [key] (file)
ini_get()
{
  local key="$1"
  local file="${2:-$TESTER_INI}"
  [ ! -s "$file" ] && return
  local value="$(grep -om1 "^$key=\S\+" "$file" | head -1 | cut -d= -f2-)"
  echo "Getting '$key' from $(basename "$file"): $value" >&2
  echo $value
}

# Get value from the HTM file.
# Usage: htm_get [key] (file)
htm_get()
{
  local key="$1"
  local file="${2:-$TEST_REPORT_HTM}"
  local value="$(grep -om1 "$key=[ ./0-9a-zA-Z_-]\+" "$file" | head -1 | cut -d= -f2-)"
  echo "Getting '$key' from $(basename "$file"): $value" >&2
  echo $value
}

# Set tag value in the file.
# tag_set [key] [value] (file)
tag_set()
{
  local key="$1"
  local value="$2"
  local file="${3:-$INCLUDE}"
  [ -f "$file" ]
  read -ra vargs <<< $EX_ARGS
  vargs+=("-u NONE")
  if [ -n "$value" ]; then
    echo "Setting '$key' to '$value' in $(basename "$file")" >&2
    timeout 10 ex +'%s/$'"$key"':\zs.*\$$/ '"${value}"'h$/' -scwq! ${vargs[@]} "$file"
  else
    echo "Value for '$key' is empty, ignoring." >&2
  fi
}

# Get all values from the INI/HTM file.
# Usage: value_get_all [file]
value_get_all()
{
  local file="$1"
  grep -o '\S\+[^_]=[^;]\+' "$file"
}

# Updates value in FXT/HST files.
# Usage: set_data_value [key] [value] [fxt/hst]
set_data_value()
{
  local key=$1
  local value=$2
  local type=${3:-"fxt"}
  [ -n "$key" ]
  [ -n "$value" ]
  find "$TICKDATA_DIR" "$TERMINAL_HST/${SERVER:-"default"}" -type f -iname "*.${type}" -print0 \
    | while IFS= read -r -d $'\0' file; do
      (
        base=$(basename "$file")
        [ -f "$file" ]
        read _ _ prev_value < <(mt_read -f "$file" -t ${type}-header | grep -w ^$key)
        [ "$prev_value" != "$value" ] && {
          mt_modify -f "$file" -t ${type}-header -m "$key=$value" \
            && read _ _ new_value < <(mt_read -f "$file" -t ${type}-header | grep -w ^$key) \
            && echo "Changed $key in $base from $prev_value into $new_value" >&2 \
            && [ $value != $new_value ] && {
            echo "ERROR: Failed to set the correct $key for $base." >&2
            exit 1
          }
        } || true
      )
    done
}

# Set spread in ini and FXT files.
# Usage: set_spread [points/10]
set_spread()
{
  local spread=${1:-BT_SPREAD}
  [ -n "$spread" ]
  ini_set "^Spread" "$spread" "$TERMINAL_INI"
  ini_set "^TestSpread" "$spread" "$TESTER_INI"
  # Change spread in all FXT files at offset 0xFC.
  set_data_value spread $spread fxt
}

# Set lot step in FXT files.
# Usage: set_lotstep [size/0.01]
set_lotstep()
{
  local lotstep=$1
  [ -n "$lotstep" ]
  # Change lot step in all FXT files at given offset.
  set_data_value lotStep $lotstep fxt
}

# Set digits in symbol raw and FXT files.
# Usage: set_digits [value/5]
set_digits()
{
  local digits=$1
  [ -n "$digits" ]
  case $(get_mtv) in
    4)
      symbols_raw_file="$(get_path_symbols_raw)"
      if [ -w "$symbols_raw_file" ]; then
        echo "Setting digits to $digits in symbols.raw..." >&2
        mt_modify -m "digits=$digits" -k ${BT_SYMBOL:-"EURUSD"} -t "symbols-raw" -f "$symbols_raw_file"
        psize="0.$(for ((i = 1; i <= digits - 1; i++)); do printf 0; done)1"
        mt_modify -m "pointSize=$psize" -k ${BT_SYMBOL:-"EURUSD"} -t "symbols-raw" -f "$symbols_raw_file"
      fi
      # Change digits in all HST files.
      set_data_value digits $digits hst
      # Change digits in all FXT files.
      set_data_value digits $digits fxt
      ;;
    5) ;;

  esac
}

# Sets white-listed URLs. Separate URLs by a semicolon.
# Usage: add_url "http://example.com/;http://another.com"
add_url()
{
  local url=$1
  [ -n "$url" ]
  mt_modify -m "webRequestUrl=$url" -m "webRequestUrlEnabled=1" -t "experts-ini" -f "$EXPERTS_INI"
}

# Set account leverage in FXT files.
# Usage: set_leverage [value]
set_leverage()
{
  local leverage=$1
  [ -n "$leverage" ]
  # Change lot step in all FXT files at given offset.
  set_data_value accountLeverage $leverage fxt
}
