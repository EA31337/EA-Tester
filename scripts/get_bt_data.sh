#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. $CWD/.configrc

# Check dependencies.
set -e
type git wget zip unzip pv xargs tee
xargs=$(which gxargs || which xargs)
[ $# -ne 3 ] && { echo "Usage: $0 [currency] [year] [DS/MQ/N1-5/W1-5/C1-5/Z1-5/R1-5]"; exit 1; }
symbol=$1
year=$2
bt_src=$3

bt_url=$(printf "https://github.com/FX31337/FX-BT-Data-%s-%s/archive/%s-%d.zip" $symbol $bt_src $symbol $year)
dest="$TERMINAL_DIR/history/downloads"
bt_csv="$dest/$bt_src-$symbol-$year"
scripts="https://github.com/FX31337/FX-BT-Scripts.git"
test ! -d "$dest/scripts" && git clone "$scripts" "$dest/scripts" # Download scripts.
mkdir -v "$bt_csv" || true

echo "Getting data..." >&2
case $bt_src in

  "DS")
    test -s "$bt_csv/$symbol-$year.zip" || wget -cNP "$bt_csv" "$bt_url"  # Download backtest data files.
    find "$bt_csv" -name "*.zip" -execdir unzip -qn {} ';' # Extract the backtest data.
  ;;
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

du -hs "$bt_csv" || { echo "ERROR: Missing backtest data."; exit 1; }
bt_size=$(find "$bt_csv" -name '*.csv' -print0 | du -bc --files0-from=- | tail -n1 | cut -f1)  # Count only size of CSV files

# Convert CSV tick files to backtest files.
echo "Converting data..."
find "$bt_csv" -name '*.csv' -print0 |
  sort -z |
  $xargs -r0 cat |
  tee &> /dev/null \
  >(pv -N 'Converting FXT & HST data' -s $bt_size |
    "$dest/scripts/convert_csv_to_mt.py" -v -i /dev/stdin -f hst4 -s $symbol -t M1 -p 10 -S default -d "$TERMINAL_DIR/history/default") \
  >("$dest/scripts/convert_csv_to_mt.py" -v -i /dev/stdin -f fxt4 -s $symbol -t M1 -p 10 -S default -d "$TERMINAL_DIR/tester/history")

# Make the backtest files read-only.
find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' ')' -exec chmod -v 444 {} ';'

# Add files to the git repository.
#if test -d "$DIR/.git"; then
#  git --git-dir=$DIR/.git add -A
#  git --git-dir=$DIR/.git commit -m"$0: Downloaded backtest files." -a
#fi

echo "$0 done."
