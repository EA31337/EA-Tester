#!/usr/bin/env bash
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
. $CWD/.configrc

# Check dependencies.
set -e
type git realpath wget zip unzip pv
[ $# -ne 3 ] && { echo "Usage: $0 [currency] [year] [DS/MQ]"; exit 1; }

symbol=$1
year=$2
bt_src=$3
bt_url=$(printf "https://github.com/FX31337/FX-BT-Data-%s-%s/archive/%s-%d.zip" $symbol $bt_src $symbol $year)
scripts="https://github.com/FX31337/FX-BT-Scripts.git"
dest="$TERMINAL_DIR/history/downloads"

# Download scripts.
test ! -d "$dest/scripts" && git clone "$scripts" "$dest/scripts"

# Download backtest data files.
zip -T "$dest/$symbol-$year.zip" || wget -cNP "$dest" "$bt_url"

# Extract the backtest data.
find "$dest" -name "*.zip" -execdir unzip -n {} ';'

find "$TERMINAL_DIR" -name "*.csv" -exec cat {} ';' | pv -N "Sorting data" -s $(du -sb "$dest"/*$symbol-$year | awk '{print $1}') | sort > "$dest/$symbol-$year.csv"
"$dest/scripts/convert_csv_to_mt.py" -i "$dest/$symbol-$year.csv" -f fxt4 -s $symbol -t M1 -p 10 -S default -d "$TERMINAL_DIR/tester/history"
"$dest/scripts/convert_csv_to_mt.py" -i "$dest/$symbol-$year.csv" -f hst4 -s $symbol -t M1 -p 10 -S default -d "$TERMINAL_DIR/history/default"

# Make the backtest files read-only.
find "$TERMINAL_DIR" '(' -name '*.fxt' -or -name '*.hst' ')' -exec chmod -v 444 {} ';'

# Add files to the git repository.
#if test -d "$DIR/.git"; then
#  git --git-dir=$DIR/.git add -A
#  git --git-dir=$DIR/.git commit -m"$0: Downloaded backtest files." -a
#fi

echo "$0 done."
