#!/usr/bin/env bash
set -e
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Check dependencies.
type git wget zip unzip pv xargs tee
xargs=$(which gxargs || which xargs)

# Initialize functions and variables.
. $CWD/.funcs.inc.sh
. $CWD/.vars.inc.sh

# Check user input.
[ $# -ne 3 ] && { echo "Usage: $0 [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5]"; exit 1; }
[ "$TRACE" ] && set -x
symbol=$1
year=$2
bt_src=$3
bt_key="$1-$2-$3"
convert=1

bt_url=$(printf "https://github.com/FX31337/FX-BT-Data-%s-%s/archive/%s-%d.zip" $symbol $bt_src $symbol $year)
rel_url=$(printf "https://github.com/FX31337/FX-BT-Data-%s-%s/releases/download/%d" $symbol $bt_src $year)
dest="$TERMINAL_DIR/history/downloads"
bt_csv="$dest/$bt_key"
scripts="https://github.com/FX31337/FX-BT-Scripts.git"
fxt_files=( ${symbol}1_0.fxt ) # ${symbol}5_0.fxt ${symbol}15_0.fxt ${symbol}30_0.fxt ${symbol}60_0.fxt ${symbol}240_0.fxt ${symbol}1440_0.fxt ${symbol}10080_0.fxt ${symbol}43200_0.fxt )
hst_files=( ${symbol}1.hst ) # ${symbol}5.hst ${symbol}15.hst ${symbol}30.hst ${symbol}60.hst ${symbol}240.hst ${symbol}1440.hst ${symbol}10080.hst ${symbol}43200.hst )

csv2data() {
  if [ $convert -eq 0 ]; then return; fi
  echo "Converting data..."
  du -hs "$bt_csv" || { echo "ERROR: Missing backtest data."; exit 1; }
  conv=$dest/scripts/convert_csv_to_mt.py
  conv_args="-v -i /dev/stdin -s $symbol -p 10 -S default"
  tmpfile=$(mktemp)
  find "$bt_csv" -name '*.csv' -print0 | sort -z | $xargs -r0 cat > "$tmpfile"
  "$conv" $conv_args -i "$tmpfile" -t M1,M5,M15,M30,H1,H4,D1,W1,MN -f hst4 -d "$HISTORY_DIR/${SERVER:-default}"
  "$conv" $conv_args -i "$tmpfile" -t M1,M5,M15,M30,H1,H4,D1,W1,MN -f fxt4 -d "$TICKDATA_DIR"
  rm -v "$tmpfile"
}

test ! -d "$dest/scripts" && git clone "$scripts" "$dest/scripts" # Download scripts.
mkdir -p $VFLAG "$bt_csv" || true

set_write_perms
clean_bt
echo "Getting data..." >&2
case $bt_src in

  "DS")
    dest="$DOWNLOAD_DIR/$bt_key"
    echo "Downloading..." >&2
    for url in $(printf "${rel_url}/%s.gz " "${fxt_files[@]}") $(printf "${rel_url}/%s.gz " "${hst_files[@]}"); do
      wget -nv -c -P "$dest" "$url" &
    done
    wait # Wait for the background tasks to finish.
    echo "Extracting..." >&2
    gunzip -kh >& /dev/null && keep="-k" || true # Check if gunzip supports -k parameter.
    find "$dest" -type f -name "*.gz" -print0 | while IFS= read -r -d '' file; do
      gunzip $VFLAG $keep "$file"
    done
    find "$dest" -type f -name "*.fxt" -exec mv $VFLAG "{}" "$TICKDATA_DIR" ';'
    find "$dest" -type f -name "*.hst" -exec mv $VFLAG "{}" "$HISTORY_DIR/${SERVER:-default}" ';'
    convert=0
  ;;
# "DS-raw") @fixme: 404 Not Found
#   test -s "$bt_csv/$symbol-$year.zip" || wget -cNP "$bt_csv" "$bt_url"  # Download backtest data files.
#   find "$bt_csv" -name "*.zip" -execdir unzip -qn {} ';' # Extract the backtest data.
# ;;
  "N0") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "N1") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "N2") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "N3") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "N4") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 1.0 3.0 -v40 ;;
  "N5") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p none "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "W0") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "W1") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "W2") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "W3") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "W4") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "W5") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p wave "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "C0") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "C1") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "C2") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "C3") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "C4") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "C5") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p curve "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "Z0") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "Z1") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 2.0 ;;
  "Z2") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "Z3") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "Z4") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "Z5") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p zigzag "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  "R0") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 0.1 0.1 ;;
  "R1") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 0.1 1.0 ;;
  "R2") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 1.0 2.0 -v20 ;;
  "R3") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 3.0 1.0 -v30 ;;
  "R4") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 1.0 4.0 -v40 ;;
  "R5") "$dest/scripts/gen_bt_data.py" -o "$bt_csv/$year.csv" -p random "$year.01.01" "$year.12.30" 5.0 1.0 -v50 ;;
  *)
    echo "ERROR: Unknown backtest data type: $bt_src" >&2
    exit 1
esac

# Convert CSV tick files to backtest files.
csv2data

# Store the backtest data type.
[ ! -f "$CUSTOM_INI" ] && touch "$CUSTOM_INI"
ini_set "bt_data" "$bt_key" "$CUSTOM_INI"

echo "$0 done."
