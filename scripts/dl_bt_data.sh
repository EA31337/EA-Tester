#!/usr/bin/env bash
set -e

TERMINAL_EXE="$(find ~ -name terminal.exe -print -quit)"
DIR="$(dirname "$TERMINAL_EXE")"

# Download backtest data files.
FXT_DIR="$(realpath "$DIR"/tester/history)"
FXT_URL="https://www.dropbox.com/s/31y3utndxjm1466/EURUSD1_0.fxt.gz"
wget -cNP "$FXT_DIR" $FXT_URL

HST_DIR="$(realpath "$DIR"/history/default)"
HST_URL="https://www.dropbox.com/s/ovtyo5atjp3zbvz/EURUSD1.hst.gz"
wget -cNP "$HST_DIR" $HST_URL

# Uncompress all .gz files.
find "$DIR" -name "*.gz" -execdir gunzip -vfd "{}" ';'

# Make the backtest files read-only.
find "$DIR" '(' -name '*.fxt' -or -name '*.hst' ')' -exec chmod -v 444 {} ';'

# Add files to the git repository.
if test -d "$DIR/.git"; then
  git --git-dir=$DIR/.git add -A
  git --git-dir=$DIR/.git commit -m"$0: Downloaded backtest files." -a
fi

echo "$0 done."
