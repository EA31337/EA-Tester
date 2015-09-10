#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Download backtest data files.
wget -qP /opt/MetaTrader\ 4/tester/history https://www.dropbox.com/s/fkjalsjhqk9p5vm/EURUSD1_0.fxt.gz
gunzip -vfd /opt/**/tester/history/*.gz

wget -qP /opt/MetaTrader\ 4/history/FX https://www.dropbox.com/s/rag8ky8kub9eum9/EURUSD1.hst.gz
gunzip -vfd /opt/**/history/FX/*.gz

# We need R+W access to .fxt files.
#sudo chown -R vagrant:vagrant /opt
#sudo chmod -R 777 /opt

echo "$0 done."
