#!/usr/bin/env bash
# Define shell functions for dealing with SET file.
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2
CWD="${CWD:-$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)}"

#
## Define SET functions. ##
#

# Set optimization params
# Usage: set_opt_params [param] [start] [end] (step)
set_opt_params() {
  # Optimization settings (F-On, 1-Min, 2-Step, 3-Max).
  input_set ^"$1",F 1         # On.
  input_set ^"$1",1 "$2"      # Min.
  input_set ^"$1",2 "${4:-1}" # Step.
  input_set ^"$1",3 "$3"      # Max.
}

# Disables optimization params
# Usage: dis_opt_params [param]
dis_opt_params() {
  input_set ^"$1",F 0       # Off.
}

# Set input value in the SET file.
# Usage: input_set [key] [value] [file]
input_set() {
  local key="$1"
  local value="$2"
  local file="${3:-$TESTER_DIR/$EA_SETFILE}"
  [ -s "$file" ]
  read -ra vargs <<<$EX_ARGS
  vargs+=("-u NONE")
  if [ -n "$value" ]; then
    echo "Setting '$key' to '$value' in $(basename "$file")" >&2
    ex +"%s/$key=\\zs.*$/$value/" -scwq! ${vargs[@]} "$file" >&2 || exit 1
  else
    echo "Value for '$key' is empty, ignoring." >&2
  fi
}

# Get input value from the SET file.
# Usage: input_get [key] [file]
input_get() {
  local key="$1"
  local file="${2:-$TESTER_DIR/$EA_SETFILE}"
  [ -s "$file" ]
  value="$(grep -om1 "$key=[.0-9a-zA-Z-]\\+" "$file" | cut -d= -f2-)"
  echo "$value"
}

# Copy input value from the SET file to MQL file.
# Usage: input_copy [key] [src_file] [dst_file] (dst_file2...)
input_copy() {
  local key=$1
  local file_src=$2
  local retries=5
  read -ra files <<<${@:3}
  read -ra vargs <<<$EX_ARGS
  vargs+=("-u NONE")
  [ -s "$file_src" ]
  for file_dst in "${files[@]}"; do
    [ -s "$file_dst" ]
    value=$(input_get "^$key" "$file_src")
    echo "Setting '$key' to '$value' in $(basename "$file_dst")" >&2
    retries=5
    while ! ex +"%s/\\s${key}[^=]=[^0-9]\\zs[^;]\\+/${value}/" -scwq! ${vargs[@]} "$file_dst" >&2; do
      sleep 1
      ((retries-=1))
      echo "Retrying ($retries left)..." >&2
      [ $retries -le 0 ] && break
    done
  done
}

# Experts SET file. Returns exported filename.
# Usage: export_set [EA/pattern] (dst/file) (...args)
export_set() {
  local name=${1:-$TEST_EXPERT}
  local dstfile=${2:-${name}.set}
  local ea_path=$name
  ahk_path="$(winepath -w "$SCR"/ahk/export_set.ahk)"
  [ ! -s "$name" ] && ea_path=$(ea_find "${name##/}")
  [ ! -f "$EXPERTS_DIR/$ea_path" ] && { echo "Error: Cannot find EA: ${name}!" >&2; return; }
  [[ "$ea_path" =~ 'mq' ]] && compile_ea "$name" >&2
  set_display >&2
  ini_set "^Expert" "$(basename "${ea_path/\//\\\\}" ."${ea_path##*.}")" "$TERMINAL_INI"
  WINEPATH="$(winepath -w "$TERMINAL_DIR");C:\\Apps\\AHK" \
  timeout 60 \
  wine AutoHotkey /ErrorStdOut "$ahk_path" "${dstfile}" "${@:3}"
  [ -n "$OPT_VERBOSE" ] && times >&2
  echo "${dstfile}"
}
