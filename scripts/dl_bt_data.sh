#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Download backtest data files.
#FXT_URL="https://www.dropbox.com/s/fkjalsjhqk9p5vm/EURUSD1_0.fxt.gz" # Original
FXT_DIR="$(realpath /opt/**/tester/history)"
FXT_URL="https://www.dropbox.com/s/31y3utndxjm1466/EURUSD1_0.fxt.gz"
wget -qNP "$FXT_DIR" $FXT_URL

#HST_URL="https://www.dropbox.com/s/rag8ky8kub9eum9/EURUSD1.hst.gz" # Original
HST_DIR="$(realpath /opt/**/history/default)"
HST_URL="https://www.dropbox.com/s/ovtyo5atjp3zbvz/EURUSD1.hst.gz"
wget -qNP "$HST_DIR" $HST_URL # To test: --show-progress 

# Uncompress all .gz files.
find . -name "*.gz" -execdir gunzip -vfd "{}" ';'

# Make the backtest files read-only.
find . '(' -name '*.fxt' -or -name '*.hst' ')' -exec chmod -v 444 {} ';'

# Add files to the git repository.
git --git-dir=/opt/.git add -A
git --git-dir=/opt/.git commit -m"$0: Downloaded backtest files." -a

echo "$0 done."
