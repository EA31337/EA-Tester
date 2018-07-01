#!/usr/bin/env bash
# Define shell functions for the external use.
#

## Initialize.
[ "$VERBOSE" ] && echo "Loading $0... " >&2
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
  find "$TERMINAL_DIR" -name "*.log" $VPRINT -exec grep --color -C1 -iw "$filter" ${@:2} "{}" +
}

# Display logs in real-time.
# Usage: live_logs [invert-match] [interval]
live_logs() {
  set +x
  local filter=${1:-modify}
  local interval=${2:-20}
  sleep $interval
  [ "$VERBOSE" ] && find "$TERMINAL_DIR" -type f -name "$(date +%Y)*.log" -print -exec tail {} ';'
  while sleep $interval; do
    if [ -n "$(find "$TESTER_DIR" -type f -name "*.log" -print -quit)" ]; then
      break;
    fi
  done
  echo "Showing live logs..." >&2
  tail -f "$TESTER_DIR"/*/*.log | grep -vw "$filter"
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

# Clean files.
# Usage: clean_files
clean_files() {
  # Remove previous log, dat, txt and htm files.
  exec 1>&2
  echo "Cleaning previous test data..."
  find "$TESTER_DIR" '(' -name "*.htm" -o -name "*.txt" ')' -type f $VPRINT -delete
  [ -d "$TESTER_DIR"/files ] && find "$TESTER_DIR"/files -type f $VPRINT -delete
  # Remove log files.
  find "$TERMINAL_DIR" '(' -name "*.log" -o -name "Report*.htm" -o -name "*.gif" ')' -type f $VPRINT -delete
  # Remove selected symbol and group files, so they can be regenerated.
  find "$HISTORY_DIR" '(' -name "symbols.sel" -o -name "symgroups.raw" ')' $VPRINT -delete
}

# Delete backtest data files.
# Usage: clean_bt
clean_bt() {
  # Remove previous backtest files for the current symbol.
  exec 1>&2
  echo "Cleaning backtest data for ${BT_SYMBOL}..." >&2
  find "$TERMINAL_DIR" '(' -name "${BT_SYMBOL}*.hst" -o -name "${BT_SYMBOL}*.fxt" ')' $VPRINT -delete
  ini_del "bt_data" "$CUSTOM_INI"
}

# Check the version of the given binary file.
# Usage: filever [file/terminal.exe]
filever() {
  type awk >/dev/null
  wine filever &>/dev/null || install_support_tools >&2
  local file=$1
  find "$PWD" "$TERMINAL_DIR" -type f -name "$file" -execdir wine filever /v "$file" ';' -quit \
    | grep ProductVersion | awk '{print $2}' | tr -d '\15'
}

# Install platform.
# Usage: install_mt [ver/4.0.0.1010]
install_mt() {
  type wget >/dev/null
  local mt_ver=$1
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
      cd -
    ;;
    *)
      echo "Error: Unknown platform version, try either 4 or 5." >&2
      exit 1
  esac
}

# Configure virtual display and wine.
# Usage: set_display
set_display() {
  export DISPLAY=:0.0 # Select screen 0.
  export WINEDLLOVERRIDES="mscoree,mshtml=,winebrowser.exe=" # Disable gecko and default browser in wine.
  export WINEDEBUG="warn-all,fixme-all,err-alsa,-ole,-toolbar" # For debugging, try: WINEDEBUG=trace+all
  sleep 1
  pgrep Xvfb || Xvfb $DISPLAY -screen 0 1024x768x16 &
}

# Detect and configure proxy.
# Usage: set_proxy
set_proxy() {
  local gw=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
  curl -s localhost:3128 > /dev/null || true && export http_proxy="http://localhost:3128"
  curl -s $gw:3128       > /dev/null || true && export http_proxy="http://$gw:3128"

  # Set proxy for wine registry if present.
  [ "$http_proxy" ] &&
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
  find "$TERMINAL_DIR" -name "*.log" $VPRINT -exec tail -n20 "{}" +
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
  srv_file=$(find "$ROOT" -name "$server.srv" -print -quit)
  if [ "$srv_file" ]; then
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

# Compile given EA name.
# Usage: compile_ea
compile_ea() {
  local name=${1:-$EA_NAME}
  cd "$TERMINAL_DIR"
  local rel_path=$(find $MQL_DIR/Experts -name "$name*")
  wine metaeditor.exe ${@:2} /log /compile:"$rel_path"
  [ -f "$TERMINAL_DIR"/MQL4.log ] && { iconv -f utf-16 -t utf-8 "$TERMINAL_DIR"/MQL?.log | grep -A10 "${name%.*}"; } || true
  cd -
}

# Copy ini settings from templates.
# Usage: ini_copy
ini_copy() {
  # Copy the configuration file, so platform can find it.
  exec 1>&2
  echo "Copying ini files..." >&2
  cp $VFLAG "$TPL_TEST" "$TESTER_INI"
  cp $VFLAG "$TPL_TERM" "$TERMINAL_INI"
}

# Find EA file and return path.
# Usage: ea_find [filename/pattern]
# Returns path relative to platform, or absolute otherwise.
ea_find() {
  local file="$1"
  [ -f "$file" ] && { echo "$file"; return; }
  local exact=$(find . "$ROOT" ~ -maxdepth 4 '(' -path "*/$1" -o -path "*/$1.mq?" -o -path "*/$1.ex?" ')' -print -quit)
  local match=$(find . "$ROOT" ~ -maxdepth 4 '(' -path "*$1*.mq?" -o -path "*$1*.ex?" -o -ipath "*$1*" ')' -print -quit)
  [ "$exact" ] && echo $exact || echo $match
}

# Copy EA file to the platform experts dir.
# Usage: ea_copy [file]
ea_copy() {
  local file=$1
  local dest="$EXPERTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$EXPERTS_DIR"/
  # Copy local include files.
  set -x
  includes=$(grep ^#include "$file" | grep -o '"[^"]\+"' | tr -d '"')
  for file in $includes; do
    ea_copy "$file"
  done
}

# Copy script file to the platform scripts dir.
# Usage: script_copy [file]
script_copy() {
  local file="$1"
  local dest="$SCRIPTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(ea_find "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$SCRIPTS_DIR"/
}

# Copy library file (e.g. dll) to the platform lib dir.
# Usage: lib_copy [file]
lib_copy() {
  local file="$1"
  local dest="$LIB_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$LIB_DIR"/
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
  srv_file=$(find "$ROOT" -name "$server.srv" -print -quit)
  if [ "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/
  fi
}

# Convert html to txt format.
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

# Convert html to txt format (full version).
# Usage: convert_html2txt_full [file_src] [file_dst]
convert_html2txt_full() {
  local file_in=$1
  local file_out=$2
  grep -v mso-number "$file_in" | html2text -nobs -width 105 -o "$file_out"
}

# Compile given script name.
# Usage: compile_script
compile_script() {
  local name="$1"
  cd "$TERMINAL_DIR"
  wine metaeditor.exe ${@:2} /log /compile:"$MQL_DIR/Scripts/$name"
  cd -
}

# Sort optimization test result values by profit factor.
# Usage: sort_opt_results [file/report.html]
sort_opt_results() {
  local file="$1"
  # Note: {1} - Profit; {2} - Profit factor; {3} - Expected Payoff; {4} - Drawdown $; {5} - Drawdown %
  ex +':/<table\_.\{-}<tr bgcolor\_.\{-}\zs<tr/;,/table>/sort! rn /\%(\(<td\).\{-}\)\{1}\1[^>]\+.\zs.*/' -scwq "$file"
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
  local file="${3:-$(echo $TESTER_DIR/$SETFILE)}"
  local vargs="-u NONE"
  [ -f "$SETFILE" ] && file="$SETFILE"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ ! -z "$value" ]; then
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
  local file="${2:-$(echo $TESTER_DIR/$SETFILE)}"
  local vargs="-u NONE"
  [ -f "$SETFILE" ] && file="$SETFILE"
  [ -f "$file" ]
  value="$(grep -om1 "$key=[.0-9a-zA-Z-]\+" "$file" | cut -d= -f2-)"
  echo $value
}

# Set value in the INI file.
# Usage: ini_set [key] [value] [file]
ini_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$(echo $TESTER_INI)}"
  local vargs="-u NONE"
  [ ! -f "$file" ] && touch "$file"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ ! -z "$value" ]; then
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
  local file="${2:-$(echo $TESTER_INI)}"
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
  local sfile="${1:-$(echo $TESTER_DIR/$SETFILE)}"
  local dfile="${2:-$(echo $EA_INI)}"
  local vargs="-u NONE"
  [ -f "$sfile" ]
  [ -f "$dfile" ]
  vargs+=$EXFLAG
  echo "Setting values from set file ($SETFILE) into in $(basename "$dfile")" >&2
  ex +'%s#<inputs>\zs\_.\{-}\ze</inputs>#\=insert(readfile("'"$sfile"'"), "")#' -scwq $vargs "$dfile"
}

# Get value from the INI/HTM file.
# Usage: ini_get [key] [file]
ini_get() {
  local key="$1"
  local file="${2:-$(echo $TESTER_INI)}"
  local value="$(grep -om1 "$key=[ ./0-9a-zA-Z_-]\+" "$file" | head -1 | cut -d= -f2-)"
  echo "Getting '$key' from $(basename "$file"): $value" >&2
  echo $value
}

# Set tag value in the file.
# tag_set [key] [value] [file]
tag_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$(echo $INCLUDE)}"
  local vargs="-u NONE"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ ! -z "$value" ]; then
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
  local spread=$1
  [ -n "$spread" ]
  ini_set "^Spread" "$SPREAD" "$TERMINAL_INI"
  ini_set "^TestSpread" "$SPREAD" "$TESTER_INI"
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
