#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Download EA.
wget -nNP /opt/**/MQL4/Experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4"

# Copy and update the configuration file.
cp -vf /vagrant/conf/mt4-tester.ini /opt/**/config/
ex -s +"%s/^TestExpert=\zs.\+$/MACD/" -cwq /opt/**/config/mt4-tester.ini

# Monitor logs in the background.
rm /opt/**/*.log # Remove old logs.
sleep 5 && tail -f /opt/**/*.log &
trap "killall tail" EXIT # Clean up after exit.

# Configure wine.
export WINEDLLOVERRIDES="mscoree,mshtml=" # Disable gecko in wine.
export DISPLAY=:0.0 # Select screen 0.

# Run terminal.
WINEDEBUG=warn+all wine /opt/**/terminal.exe config/mt4-tester.ini
