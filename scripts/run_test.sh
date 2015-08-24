#!/bin/bash

# Enable globbing.
shopt -s globstar

# Download EA.
wget -NP /opt/**/MQL4/Experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4"

# Update configuration.
ex -s +"%s/^TestExpert=\zs.\+$/MACD/" -cwq /vagrant/conf/mt4-tester.ini

# Copying ini file to MT's directory so MT can find it.
sudo cp /vagrant/conf/mt4-tester.ini /opt/MetaTrader\ 4/mt4-tester.ini

# Monitor logs in the background.
sleep 5 && tail -f /opt/**/*.log &

# Disable gecko in wine.
export WINEDLLOVERRIDES="mscoree,mshtml="

# Run X virtual framebuffer on screen 0.
Xvfb :0 -screen 0 1024x768x16 &

# Select screen 0.
export DISPLAY=:0.0

# Run terminal.
wine /opt/**/terminal.exe mt4-tester.ini
