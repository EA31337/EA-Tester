#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Download EA.
wget -qNP /opt/**/MQL4/Experts "https://www.dropbox.com/s/gukjb229sv2ilpn/MACD.ex4"

echo "$0 done."
