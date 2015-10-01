#!/usr/bin/env bash
set -x
shopt -s globstar # Enable globbing.

# Download EA.
wget -qNP /opt/**/MQL4/Experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4"

# Add files to the git repository.
git --git-dir=/opt/.git add -A
git --git-dir=/opt/.git commit -m"$0: Downloaded EA." -a

echo "$0 done."
