#!/usr/bin/env bash
set -e
type wget || { echo "Please install wget before continuing."; exit 1; }
TERMINAL_EXE="$(find /opt -name terminal.exe -print -quit)"
DIR="$(dirname "$TERMINAL_EXE")"

# Download EA.
wget -qNP $DIR/MQL4/Experts $1

# Add files to the git repository.
git --git-dir=/opt/.git add -A
git --git-dir=/opt/.git commit -m"$0: Downloaded EA." -a

echo "$0 done."
