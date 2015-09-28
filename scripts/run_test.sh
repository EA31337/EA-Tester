#!/bin/bash -xe
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
OUT="/opt"

REPORTDIR="$1"
SETFILE="$2"
MODE="$3"
SYMBOL="$4"
DEPOSIT="$5"
YEAR="$6"
SPREAD="$7"
SOURCE="$8"

EXPERT=EA31337-$MODE
FROM=$YEAR.01.01
TO=$YEAR.01.02

# Enable globbing.
shopt -s globstar

# Check if terminal is present.
[ "$(find $OUT/**/terminal.exe)" ] || $CWD/dl_mt4.sh

# Check if backtest files are present.
[ "$(find "$OUT" -name \*.fxt)" ] || $CWD/dl_bt_data.sh

# Download EA.
$CWD/dl_ea.sh

# Download set files.
[ "$(find $OUT -type d -name sets)" ] || $CWD/dl_sets.sh https://github.com/EA31337/EA31337-Sets

# Update configuration.
ex -s +"%s/^TestExpert=\zs.\+$/$EXPERT/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s#^TestReport=\zs.\+$#$REPORTDIR#" -cwq /vagrant/conf/mt4-tester.ini

# Copy and update the configuration file.
cp -vf /vagrant/conf/mt4-tester.ini $OUT/**/config/
ex -s +"%s/^TestReplaceReport=\zs.\+$/true/" -cwq /vagrant/conf/mt4-tester.ini

# Copying ini file to MT's directory so MT can find it.
sudo cp /vagrant/conf/mt4-tester.ini /opt/MetaTrader\ 4/mt4-tester.ini

# Monitor logs in the background.
find "$OUT" '(' -name "*.log" -or -name "*.dat" ')' -delete
sleep 5 && tail -f $OUT/**/*.log &
trap "killall tail" EXIT # Clean up after exit.

# Configure wine.
export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
export DISPLAY=:0.0 # Select screen 0.
export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all

# Run terminal.
wine $OUT/**/terminal.exe config/mt4-tester.ini && html2text $OUT/**/Report.htm
