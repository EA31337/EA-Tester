#!/bin/bash

# Enable globbing.
shopt -s globstar

# Download EA.
wget -NP /opt/**/experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4"

# Update configuration.
ex -s +"%s/^TestExpert=\zs.\+$/MACD/" -cwq /vagrant/conf/mt4-tester.ini

# Monitor logs in the background.
sleep 5 && tail -f /opt/**/*.log &

# Run terminal.
wine /opt/**/terminal.exe /vagrant/conf/mt4-tester.ini 
