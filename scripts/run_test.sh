#!/bin/bash

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

# Download EA.
wget -NP /opt/**/MQL4/Experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4" # -O "/opt/MetaTrader 4/MQL4/Experts/EA31337-Advanced.ex4"

cp /vagrant/MACD.ex4 "/opt/MetaTrader 4/MQL4/Experts/EA31337-Advanced.ex4"

# Update configuration.
ex -s +"%s/^TestExpert=\zs.\+$/$EXPERT/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestExpertParameters=\zs.\+$/$SETFILE/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestSymbol=\zs.\+$/$SYMBOL/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestFromDate=\zs.\+$/$FROM/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s/^TestToDate=\zs.\+$/$TO/" -cwq /vagrant/conf/mt4-tester.ini
ex -s +"%s#^TestReport=\zs.\+$#$REPORTDIR#" -cwq /vagrant/conf/mt4-tester.ini

cat /vagrant/conf/mt4-tester.ini | grep TestReport

ex -s +"%s/^TestReplaceReport=\zs.\+$/true/" -cwq /vagrant/conf/mt4-tester.ini

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
