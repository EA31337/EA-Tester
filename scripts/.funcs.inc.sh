#!/usr/bin/env bash
# .funcs.inc.sh file
#

[ "$VERBOSE" ] && echo "Loading $0... " >&2

#
## Define common functions. ##
#

# Init shell settings.
initialize() {

  # Handle bash errors. Exit on error. Trap exit.
  # Trap normal exit signal (exit on all errors).
  trap onexit EXIT
  # Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR (9/KILL cannot be trapped).
  trap onerror 1 2 3 15 ERR

  # Expand aliases in shell.
  shopt -s expand_aliases

  # Activate trace on demand.
  [ "$TRACE" ] && set -x
  # Exit immediately if a command exits with a non-zero status.
  [ ! "$NOFAIL" ] && set -e

}

# Clean traps which are in use.
clean_traps() {
  trap - 1 2 3 15 ERR EXIT
}

# Join string by delimiter (see: http://stackoverflow.com/a/17841619).
join_by() {
  local d=$1; shift;
  echo -n "$1"; shift;
  printf "%s" "${@/#/$d}";
}

# Configure display and wine.
configure_display() {
  export DISPLAY=:0.0 # Select screen 0.
  export WINEDLLOVERRIDES="mscoree,mshtml=,winebrowser.exe=" # Disable gecko and default browser in wine.
  export WINEDEBUG="warn-all,fixme-all,err-alsa,-ole,-toolbar" # For debugging, try: WINEDEBUG=trace+all
  sleep 1
  pgrep Xvfb || Xvfb $DISPLAY -screen 0 1024x768x16 &
}

# Display recent logs.
show_logs() {
  find "$TERMINAL_DIR" -name "*.log" $VPRINT -exec tail -n20 "{}" +
}

# Check logs for specific text.
check_logs() {
  local filter=$1
  find "$TERMINAL_DIR" -name "*.log" $VPRINT -exec grep --color -C1 -iw "$filter" ${@:2} "{}" +
}

# Display logs in real-time.
live_logs() {
  set +x
  local filter=${1:-modify}
  while sleep 20; do
    if [ "$(find "$TESTER_DIR" -type f -name "*.log" -print -quit)" ]; then
      break;
    fi
  done
  echo "Showing live logs..." >&2
  tail -f "$TESTER_DIR"/*/*.log | grep -vw "$filter"
}
# Display performance stats in real-time.
live_stats() {
  set +x
  while sleep 60; do
    # TERM=vt100 top | head -n4
    winedbg --command 'info wnd' | grep -v Empty | cut -c67- | grep -e : -e / | paste -sd,
  done
}

# Check required files.
check_files() {
  if [ "$SERVER" != "default" ]; then
    local symbols_raw_default="$HISTORY_DIR/default/symbols.raw"
    local symbols_raw="$HISTORY_DIR/$SERVER/symbols.raw"
    [ -d "$HISTORY_DIR/$SERVER" ] || mkdir $VFLAG "$HISTORY_DIR/$SERVER"
    [ -s "$symbols_raw" ] || cp $VFLAG "$symbols_raw_default" "$symbols_raw"
  fi
}

# Clean files.
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
clean_bt() {
  # Remove previous backtest files for the current symbol.
  exec 1>&2
  echo "Cleaning backtest data for ${SYMBOL}..." >&2
  find "$TERMINAL_DIR" '(' -name "${SYMBOL}*.hst" -o -name "${SYMBOL}*.fxt" ')' $VPRINT -delete
}

# Delete compiled EAs.
clean_ea() {
  exec 1>&2
  echo "Cleaning compiled EAs and scripts..." >&2
  find "$TERMINAL_DIR/$MQL_DIR" '(' -name '*.ex4' -or -name '*.ex5' ')' -type f $VPRINT -delete
}

# Set input value in the SET file.
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
    echo "Value for '$key' is empty, ignoring."
  fi
}

# Get input value from the SET file.
input_get() {
  local key="$1"
  local value="$2"
  local file="${3:-$(echo $TESTER_DIR/$SETFILE)}"
  local vargs="-u NONE"
  [ -f "$SETFILE" ] && file="$SETFILE"
  [ -f "$file" ]
  value="$(grep -om1 "$key=[.0-9a-zA-Z-]\+" "$file" | cut -d= -f2-)"
  echo $value
}

# Set value in the INI file.
ini_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$(echo $TESTER_INI)}"
  local vargs="-u NONE"
  [ ! -f "$file" ] && [ -f "$TESTER_INI" ] && file="$TESTER_INI"
  [ -f "$file" ]
  vargs+=$EXFLAG
  if [ ! -z "$value" ]; then
    echo "Setting '$key' to '$value' in $(basename "$file")" >&2
    ex +'%s#'"$key"'=\zs.*$#'"$value"'#' -scwq $vargs "$file" || exit 1
  else
    echo "Value for '$key' is empty, ignoring."
  fi
}

# Set value in the EA INI file.
# Usage: ini_set_ea key value
ini_set_ea() {
  local key=$1
  local value=$2
  grep -q ^$key "$EA_INI" \
    && ini_set ^$key $value "$EA_INI" \
    || ex +"%s/<inputs>/<inputs>\r$key=$value/" -scwq "$EA_INI"
}

# Set inputs in the EA INI file.
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
ini_get() {
  local key="$1"
  local file="${2:-$(echo $TESTER_INI)}"
  local value="$(grep -om1 "$key=[ ./0-9a-zA-Z_-]\+" "$file" | head -1 | cut -d= -f2-)"
  echo "Getting '$key' from $(basename "$file"): $value" >&2
  echo $value
}

# Set tag value in the file.
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
get_values() {
  local file="$1"
  grep -o '\S\+[^_]=[^;]\+' "$file"
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

# Get value from symbols file.
# Usage: get_symbol_value (hex-offset) (len)
# Returns value in hex format.
get_symbol_value() {
  local rel_offset=$((16#$1))
  local length=${2:-1}
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  echo $(read_data "$file" $abs_offset $length)
}

# Get double value from symbols file.
# Usage: get_symbol_double (hex-offset) (len)
# Returns value in hex format.
get_symbol_double() {
  local rel_offset=$((16#$1))
  local length=${2:-8}
  local file="$HISTORY_DIR/${SERVER:-default}/symbols.raw"
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${SYMBOL:-EURUSD} | grep -o "^[^:]\+")
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
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${SYMBOL:-EURUSD} | grep -o "^[^:]\+")
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
  local symbol_offset=$(xxd -g1 -c 121 "$file" | grep -w ${SYMBOL:-EURUSD} | grep -o "^[^:]\+")
  local abs_offset="$(( $((16#$symbol_offset)) + $rel_offset))"
  [ -n "$symbol_offset" ]
  write_double "$file" $value $abs_offset
  return $TRUE
}

# Set spread in ini and FXT files.
# Usage: set_spread 10
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
# Usage: set_lotstep 1
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
# Usage: set_digits 5
set_digits() {
  local digits=$1
  [ -n "$digits" ]
  echo "Setting digits to $digits..." >&2
  set_symbol_value $digits $SRAW_OFF_DIGITS
  psize="0.$(for ((i=1;i<=digits-1;i++)); do printf 0; done)1"
  set_symbol_double $psize $SRAW_OFF_PSIZE
  cp $VFLAG "$ROOT/conf/accounts-d${digits}.ini" "$TERMINAL_DIR"/config/accounts.ini
}

# Get time from terminal log in h.
get_time() {
  echo $(grep -o "^real[^m]\+" "$TERMINAL_LOG" | cut -f 2)
}

# Save time and store in rule file if exists.
save_time() {
  local htime=$(($(eval get_time) / 60))
  [ "$VERBOSE" ] && echo "ETA: $((get_time / 60))h" >&2
  [ -f "$INCLUDE" ] && tag_set ETA $htime "$INCLUDE"
}

# Set read permissions for test files.
set_read_perms() {
  # Make the backtest files read-only.
  echo "Setting read-only permissions for backtest files..." >&2
  find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' -or -name '*.exe' ')' -print0 | while IFS= read -r -d '' file; do
    chmod $VFLAG ugo-w "$file"
  done
}

# Set write permissions for test files.
set_write_perms() {
  echo "Setting write permissions for backtest files..." >&2
  find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' ')' -print0 | while IFS= read -r -d '' file; do
    chmod $VFLAG u+w "$file"
  done
}

# Detect and configure proxy.
configure_proxy() {
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

# Copy ini settings from templates.
copy_ini() {
  # Copy the configuration file, so platform can find it.
  exec 1>&2
  echo "Copying ini files..."
  cp $VFLAG "$TPL_TEST" "$TESTER_INI"
  cp $VFLAG "$TPL_TERM" "$TERMINAL_INI"
}

# Find EA file and return path.
find_ea() {
  local file="$1"
  [ -f "$file" ] && { echo "$file"; return; }
  local exact=$(find "$TERMINAL_DIR" "$ROOT" ~ -maxdepth 3 '(' -name "$1.mq?" -o -name "$1.ex?" -o -name "$1" ')' -print -quit)
  local match=$(find "$TERMINAL_DIR" "$ROOT" ~ -maxdepth 3 '(' -name "*$1*.mq?" -o -name "*$1*.ex?" -o -name "$1" ')' -print -quit)
  [ "$exact" ] && echo $exact || echo $match
}

# Copy EA file given the file path.
copy_ea() {
  local file=$1
  local dest="$EXPERTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(find_ea "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$EXPERTS_DIR"/
}

# Copy script file given the file path.
copy_script() {
  local file="$1"
  local dest="$SCRIPTS_DIR/$(basename "$file")"
  [ ! -s "$file" ] && file=$(find_ea "$file")
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$SCRIPTS_DIR"/
}

# Copy library file (e.g. dll) given the file path.
copy_lib() {
  local file="$1"
  local dest="$LIB_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$LIB_DIR"/
}

# Copy a file given the file path.
copy_file() {
  local file="$1"
  local dest="$FILES_DIR/$(basename "$file")"
  [ "$(dirname "$file")" == "$(dirname "$dest")" ] && return
  exec 1>&2
  cp $VFLAG "$file" "$FILES_DIR"/
}

# Copy srv files into terminal dir.
copy_srv() {
  local server="$(ini_get Server)"
  srv_file=$(find "$ROOT" -name "$server.srv" -print -quit)
  if [ "$srv_file" ]; then
    cp $VFLAG "$srv_file" "$TERMINAL_CNF"/
  fi
}

# Download the file.
dl_file() {
  local url="$1"
  local dest="${2:-$DOWNLOAD_DIR}"
  wget -cP "$dest" $url
}

# Compile given EA name.
compile_ea() {
  local name=${1:-$EA_NAME}
  cd "$TERMINAL_DIR"
  local rel_path=$(find $MQL_DIR/Experts -name "$name*")
  wine metaeditor.exe ${@:2} /log /compile:"$rel_path"
  [ -f "$TERMINAL_DIR"/MQL4.log ] && { iconv -f utf-16 -t utf-8 "$TERMINAL_DIR"/MQL?.log | grep -A10 "${name%.*}"; } || true
  cd -
}

# Convert html to txt format.
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
convert_html2txt_full() {
  local file_in=$1
  local file_out=$2
  grep -v mso-number "$file_in" | html2text -nobs -width 105 -o "$file_out"
}

# Compile given script name.
compile_script() {
  local name="$1"
  cd "$TERMINAL_DIR"
  wine metaeditor.exe ${@:2} /log /compile:"$MQL_DIR/Scripts/$name"
  cd -
}

# Sort optimization test result values by profit factor.
# Usage: sort_opt_results report.html
sort_opt_results() {
  local file="$1"
  # Note: {1} - Profit; {2} - Profit factor; {3} - Expected Payoff; {4} - Drawdown $; {5} - Drawdown %
  ex +':/<table\_.\{-}<tr bgcolor\_.\{-}\zs<tr/;,/table>/sort! rn /\%(\(<td\).\{-}\)\{1}\1[^>]\+.\zs.*/' -scwq "$file"
}

# Enhance a GIF report file.
# Usage: enhance_gif -c1 color_name -c2 color_name -t "Text with \\\n new lines"
# @see: https://www.imagemagick.org/script/color.php
enhance_gif() {
  local file="$1"
  local text=''
  local negate=0
  local font=$(fc-match --format=%{file} Arial.ttf)
  local text_color=${GIF_TEXT_COLOR:-gray}
  type convert > /dev/null
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

## Install platform.
install_mt() {
  type wget > /dev/null
  local mt_ver=$1
  configure_display
  case $mt_ver in
    4)
      . $CWD/install_mt4.sh
    ;;
    4x)
      . $CWD/install_mt4-xdot.sh
    ;;
    5)
      . $CWD/install_mt5.sh
    ;;
    4.0.0.*|5.0.0.*)
      [ ! -d "$WINE_PATH" ] && mkdir $VFLAG -p "$WINE_PATH"
      cd "$WINE_PATH"
      wget -nv -c "$REPO_URL/releases/download/${mt_ver:0:1}.x/mt-$mt_ver.zip"
      unzip -ou mt*.zip
      cd -
    ;;
    *)
      echo "Error: Unknown platform version, try either 4 or 5." >&2
      exit 1
  esac
}

# Validate platform dirs.
validate_dirs() {
  for dir in \
    "$TESTER_DIR" "$TERMINAL_DIR/$MQL_DIR" \
    "$EXPERTS_DIR" "$SCRIPTS_DIR" \
    "$FILES_DIR" "$LIB_DIR" \
    "$LOG_DIR" "$TICKDATA_DIR"
  do
    [ -d "$dir" ] || mkdir $VFLAG "$dir"
   #[ -d "$dir" ] || { quick_run; return; }
  done
}

# Run platform and kill it.
# @todo
quick_run() {
  local scrname="${1:-PrintPaths}"
  copy_ini
  ini_set "^Script" $scrname
  copy_script $scrname
  (time wine "$TERMINAL_EXE" "config/$CONF_TEST" $TERMINAL_ARG) 2>> "$TERMINAL_LOG"
  show_logs
}

## Install filever
install_support_tools() {
  type wget cabextract install wine >&2
  wine filever > /dev/null && return
  local tools_url="https://github.com/EA31337/FX-MT-VM/releases/download/4.x/WindowsXP-KB838079-SupportTools-ENU.exe"
  local dtmp=$(mktemp -d)
  echo "Installing support tools..." >&2
  cd "$dtmp"
  wget -nv "$tools_url"
  cabextract -F support.cab *.exe
  cabextract -F filever.exe *.cab
  install -v filever.exe ~/.wine/drive_c/windows
  rm -fr "$dtmp"
  cd -
}

# Check the version of the given binary file.
# Usage: filever terminal.exe
filever() {
  type awk > /dev/null
  wine filever >& /dev/null || install_support_tools >&2
  local file=$1
  find "$PWD" "$TERMINAL_DIR" -type f -name "$file" -execdir wine filever /v "$file" ';' -quit \
    | grep ProductVersion | awk '{print $2}' | tr -d '\15'
}

## Clean up.
clean_up() {
  kill_wine
  sleep 10 & # Run dummy process.
  # Kill any remaining background jobs.
  kill $(jobs -p) 2> /dev/null || true
}

## Kills the currently running wineserver.
kill_wine() {
  type wineserver > /dev/null || return
  wineserver -k || true
}

# Restore IFS.
restore_ifs() {
  IFS=$' \t\n'
}

# Show simple stack trace.
show_trace() {
  while caller $((n++)); do :; done; >&2
}

#--- onexit()
##  @param $1 integer  (optional) Exit status. If not set, use '$?'
onexit() {
  local exit_status=${1:-$?}
  clean_up
  [ "$VERBOSE" ] && echo "Exiting $0 with $exit_status" >&2
  exit $exit_status
}

#--- onerror()
##  @param $1 integer  (optional) Exit status. If not set, use '$?'
onerror() {
  local exit_status=1
  local frame=0
  echo "ERROR: Exiting $0 with $exit_status" >&2
  show_trace
  exit $exit_status
}

initialize
