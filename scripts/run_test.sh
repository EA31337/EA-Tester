#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Check if terminal is present.
find /opt/**/terminal.exe || source ./dl_mt4.sh

# Check if backtest files are present.
find /opt -name \*.fxt || source ./dl_bt_data.sh

# Download EA.
source ./dl_ea.sh

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

# Run terminal.
WINEDEBUG=warn+all wine /opt/**/terminal.exe config/mt4-tester.ini && html2text /opt/**/Report.htm
