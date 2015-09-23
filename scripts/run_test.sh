#!/bin/bash -xe
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

# Enable globbing.
shopt -s globstar

# Check if terminal is present.
[ "$(find /opt/**/terminal.exe)" ] || $CWD/dl_mt4.sh

# Check if backtest files are present.
[ "$(find /opt -name \*.fxt)" ] || $CWD/dl_bt_data.sh

# Download EA.
$CWD/dl_ea.sh

# Download set files.
[ "$(find /opt -type d -name sets)" ] || $CWD/dl_sets.sh https://github.com/EA31337/EA31337-Sets

# Copy and update the configuration file.
cp -vf /vagrant/conf/mt4-tester.ini /opt/**/config/
ex -s +"%s/^TestExpert=\zs.\+$/MACD/" +"%s/TestReplaceReport=\zs.\+$/true/" -cwq /opt/**/config/mt4-tester.ini

# Monitor logs in the background.
rm /opt/**/*.log # Remove old logs.
sleep 5 && tail -f /opt/**/*.log &
trap "killall tail" EXIT # Clean up after exit.

# Configure wine.
export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
export DISPLAY=:0.0 # Select screen 0.
export WINEDEBUG=warn+all # For debugging, try: WINEDEBUG=trace+all

# Run terminal.
wine /opt/**/terminal.exe config/mt4-tester.ini && html2text /opt/**/Report.htm
