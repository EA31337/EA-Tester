#!/bin/bash -x

# Enable globbing.
shopt -s globstar

# Download backtest data files.
#FXT_URL="https://www.dropbox.com/s/fkjalsjhqk9p5vm/EURUSD1_0.fxt.gz" # Original
FXT_URL="https://www.dropbox.com/s/31y3utndxjm1466/EURUSD1_0.fxt.gz"
wget -qNP /opt/**/tester/history $FXT_URL
gunzip -vfd /opt/**/tester/history/*.gz

#HST_URL="https://www.dropbox.com/s/rag8ky8kub9eum9/EURUSD1.hst.gz" # Original
HST_URL="https://www.dropbox.com/s/ovtyo5atjp3zbvz/EURUSD1.hst.gz"
wget -qNP /opt/**/history/FX $HST_URL
gunzip -vfd /opt/**/history/FX/*.gz

# We need R+W access to .fxt files.
#sudo chown -R vagrant:vagrant /opt
#sudo chmod -R 777 /opt

echo "$0 done."
