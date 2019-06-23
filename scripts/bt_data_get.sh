#!/usr/bin/env bash
# Script to download or generate the backtest data in MT4 platform format.
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
type git wget zip unzip xargs tee >/dev/null
xargs=$(command -v gxargs || command -v xargs)

# Initialize functions and variables.
. "$CWD"/.funcs.cmds.inc.sh
. "$CWD"/.funcs.inc.sh
. "$CWD"/.vars.inc.sh

# Check user input.
[ $# -lt 3 ] && { echo "Usage: $0 [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5] [period/M1] [mode/0]"; exit 1; }
[ -n "$OPT_VERBOSE" ] && vflag="-v"
[ -n "$OPT_TRACE" ] && set -x
read symbol year bt_src period mode <<<$@
bt_key="$symbol-$year-$bt_src"
convert=1

bt_url=$(printf "https://github.com/FX-Data/FX-Data-%s-%s/archive/%s-%s.zip" $symbol $bt_src $symbol $year)
rel_url=$(printf "https://github.com/FX-Data/FX-Data-%s-%s/releases/download/%s" $symbol $bt_src $year)
dl_dir="$TERMINAL_DIR/history/downloads"
dest_dir="$dl_dir/${bt_key%.*}"
scripts="https://github.com/FX31337/FX-BT-Scripts.git"
fxt_files=()
hst_files=()

csv2data() {
  if [ $convert -eq 0 ]; then return; fi
  echo "Converting data..."
  du -hs "$dest_dir" || { echo "ERROR: Missing backtest data."; exit 1; }
  conv_args="-v -i /dev/stdin -s $symbol -p 10 -S default"
  tmpfile=$(mktemp)
  find "$dest_dir" -name '*.csv' -print0 | sort -z | $xargs -r0 cat > "$tmpfile"
  conv_csv_to_mt $conv_args -i "$tmpfile" -t M1,M5,M15,M30,H1,H4,D1,W1,MN -f hst4 -d "$HISTORY_DIR/${SERVER:-default}"
  conv_csv_to_mt $conv_args -i "$tmpfile" -t M1,M5,M15,M30,H1,H4,D1,W1,MN -f fxt4 -d "$TICKDATA_DIR"
  rm $vflag "$tmpfile"
}

test ! -d "$dl_dir/scripts" && git clone "$scripts" "$dl_dir/scripts" # Download scripts.
mkdir -p $vflag "$dest_dir" || true

# Select tick data files based on the required timeframe.
case $period in
  "M1")
    mins=1
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "M5")
    mins=5
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "M15")
    mins=15
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "M30")
    mins=30
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "H1")
    mins=60
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "H4")
    mins=240
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "D1")
    mins=1440
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "W1")
    mins=10080
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  "MN")
    mins=43200
    case $mode in
      0|1|2) fxt_files=( ${symbol}${mins}_${mode}.fxt ) ;;
      *) fxt_files=( ${symbol}${mins}_0.fxt ${symbol}${mins}_1.fxt ${symbol}${mins}_2.fxt )
    esac
  ;;
  *)
    fxt_files=( ${symbol}1_${mode:-0}.fxt )
esac
for tf in 1 2 3 4 5 6 10 12 15 20 30 60 120 180 240 360 480 720 1440 10080 43200; do
  hst_files+=( ${symbol}${tf}.hst )
done

set_write_perms
clean_bt
check_dirs
echo "Getting data..." >&2
case $bt_src in

  "DS")
    echo "Downloading..." >&2
    for url in $(printf "${rel_url}/%s.gz " "${fxt_files[@]}") $(printf "${rel_url}/%s.gz " "${hst_files[@]}"); do
      wget -nv -c -P "$dest_dir" "$url" &
    done
    wait # Wait for the background tasks to finish.
    echo "Extracting..." >&2
    gunzip -kh >& /dev/null && keep="-k" || true # Check if gunzip supports -k parameter.
    cd "$dest_dir"
    gunzip $vflag $keep ${fxt_files[@]} ${hst_files[@]}
    cd - &> /dev/null
    echo "Moving..." >&2
    find "$dest_dir" -type f -name "*.fxt" -exec mv $vflag "{}" "$TICKDATA_DIR" ';'
    find "$dest_dir" -type f -name "*.hst" -exec mv $vflag "{}" "$HISTORY_DIR/${SERVER:-default}" ';'
    convert=0
  ;;

  "DS2")
    echo "Downloading..." >&2
    for url in $(printf "${rel_url/DS2/DS}/MQ-%s.gz " "${fxt_files[@]}") $(printf "${rel_url/DS2/DS}/MQ-%s.gz " "${hst_files[@]}"); do
      wget -nv -c -P "$dest_dir" "$url" &
    done
    wait # Wait for the background tasks to finish.
    echo "Extracting..." >&2
    gunzip -kh >& /dev/null && keep="-k" || true # Check if gunzip supports -k parameter.
    find "$dest_dir" -type f -name "*.gz" -print0 | while IFS= read -r -d '' file; do
      dstfile=${file%.gz}
      gunzip $vflag $keep "$file"
      mv $vflag "${dstfile}" "${dstfile/MQ-$symbol/$symbol}"
    done
    echo "Moving..." >&2
    find "$dest_dir" -type f -name "*.fxt" -exec mv $vflag "{}" "$TICKDATA_DIR" ';'
    find "$dest_dir" -type f -name "*.hst" -exec mv $vflag "{}" "$HISTORY_DIR/${SERVER:-default}" ';'
    convert=0
  ;;

# "DS-raw") @fixme: 404 Not Found
#   test -s "$dest_dir/$symbol-$year.zip" || wget -cNP "$dest_dir" "$bt_url"  # Download backtest data files.
#   find "$dest_dir" -name "*.zip" -execdir unzip -qn {} ';' # Extract the backtest data.
# ;;
  "N0") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "N1") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "N2") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "N3") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "N4") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 1.0 3.0 -v40 ;;
  "N5") bt_data_gen -o "$dest_dir/$year.csv" -p none "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "W0") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "W1") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "W2") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "W3") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "W4") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "W5") bt_data_gen -o "$dest_dir/$year.csv" -p wave "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "C0") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "C1") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "C2") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "C3") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "C4") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "C5") bt_data_gen -o "$dest_dir/$year.csv" -p curve "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "Z0") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "Z1") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 2.0 ;;
  "Z2") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "Z3") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "Z4") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "Z5") bt_data_gen -o "$dest_dir/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "R0") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "R1") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "R2") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "R3") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "R4") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "R5") bt_data_gen -o "$dest_dir/$year.csv" -p random "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  *)
    echo "ERROR: Unknown backtest data type: $bt_src" >&2
    exit 1
esac

# Convert CSV tick files to backtest files.
csv2data

# Store the backtest data type in INI file.
[ -f "$CUSTOM_INI" ] \
  && ini_set "bt_data" "$bt_key" "$CUSTOM_INI" \
  || echo "bt_data=$bt_key" > "$CUSTOM_INI"

echo "${BASH_SOURCE[0]} done." >&2
