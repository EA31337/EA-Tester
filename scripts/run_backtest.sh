#!/bin/bash -xe
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)/.."
OUT="/opt"
TPL="/vagrant/conf/mt4-tester.ini"

REPORTDIR="$1"
SETFILE="$2"
MODE="$3"
SYMBOL="$4"
DEPOSIT="$5"
YEAR="$6"
SPREAD="$7"
SOURCE="$8"
FROM="$YEAR.01.01"
TO="$YEAR.01.02"
EXPERT="$(find "$CWD" '(' -name "*$MODE*.ex4" -or -name "*$MODE*.ex5" ')' -print -quit)"

# Check if terminal is present.
[ "$(find "$OUT" -name terminal.exe -print -quit)" ] || $CWD/scripts/dl_mt4.sh
TERMINAL_EXE="$(find "$OUT" -name terminal.exe -print -quit)"
TERMINAL_DIR="$(dirname "$TERMINAL")"
TERMINAL_INI="$TERMINAL_DIR/config/$TPL"

# Check if backtest files are present.
[ "$(find "$OUT" -name '*.fxt')" ] || $CWD/scripts/dl_bt_data.sh

# Download EA.
$CWD/scripts/dl_ea.sh

# Copy and update the configuration file.
cp -vf $TPL $TERMINAL_INI
[ ! -z "$EXPERT" ]    && ex -s +"%s/^TestExpert=\zs.\+$/$EXPERT/" -cwq $CONF
[ ! -z "$SETFILE" ]   && ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq $CONF
[ ! -z "$SYMBOL" ]    && ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq $CONF
[ ! -z "$FROM" ]      && ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq $CONF
[ ! -z "$TO" ] 	      && ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq $CONF
[ ! -z "$REPORTDIR" ] && ex -s +"%s#^TestReport=\zs.\+$#$REPORTDIR#" -cwq $CONF

# Copying ini file to MT's directory so MT can find it.
cp -v $TPL $TERMINAL_INI
cp -v $SETFILE $TERMINAL_DIR/tester

# Monitor logs in the background.
find "$OUT" '(' -name "*.log" -or -name '*.dat' ')' -delete
sleep 5 && tail -f $TERMINAL_DIR/*/*.log &
trap "killall tail" EXIT # Clean up after exit.

# Configure wine.
export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
export DISPLAY=:0.0 # Select screen 0.
export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all

# Run terminal.
wine $TERMINAL_EXE $TERMINAL_INI && html2text $TERMINAL_DIR/Report.htm
