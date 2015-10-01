#!/usr/bin/env bash
set -x
CWD="$(cd -P -- "$(dirname -- "$0")/../" && pwd -P)"
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
TERMINAL_DIR="$(dirname "$TERMINAL_EXE")"
TERMINAL_INI="$TERMINAL_DIR/config/mt4-tester.ini"
echo $TERMINAL_EXE
echo $TERMINAL_DIR
echo $TERMINAL_INI

# Check if backtest files are present.
[ "$(find "$OUT" -name '*.fxt')" ] || $CWD/scripts/dl_bt_data.sh

# Download EA.
$CWD/scripts/dl_ea.sh

# Copy and update the configuration files, so platform can find it.
cp -v "$TPL" "$TERMINAL_INI"
[ -s "$SETFILE" ] && cp -v "$SETFILE" "$TERMINAL_DIR/tester"
[ "$EXPERT" ]     && ex -s +"%s/^TestExpert=\zs.\+$/$EXPERT/" -cwq "$TERMINAL_INI"
[ "$SETFILE" ]    && ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq "$TERMINAL_INI"
[ "$SYMBOL" ]     && ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq "$TERMINAL_INI"
[ "$FROM" ]       && ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq "$TERMINAL_INI"
[ "$TO" ] 	      && ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq "$TERMINAL_INI"
[ "$REPORTDIR" ]  && ex -s +"%s#^TestReport=\zs.\+$#$REPORTDIR#" -cwq "$TERMINAL_INI"

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
