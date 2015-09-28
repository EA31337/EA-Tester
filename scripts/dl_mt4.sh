#!/bin/bash -x

OUT="/opt"

# Download and install MT4/MT5 platforms.
# @todo: 1. Download platform.
#wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
#wget https://fx.instaforex.com/i/downloads/itc4setup.exe https://fx.instaforex.com/i/downloads/itc5setup.exe

# @todo: 2. Install platform (use xdotool to fake keyboard to navigate through the installator).
#export DISPLAY=:0
# wine mt4setup.exe
#xdotool key Space n
#wineserver -k # Kill leftover wine sessions.

# Otherwise download already pre-installed platform.
URL="https://www.dropbox.com/s/2te5670pkscf2eg/mt4-890.tgz"
wget -qO- "$URL" | tar zxvf - -C "$OUT"
# Other links:
# - https://www.dropbox.com/s/1d38i4vwkfw89g9/mt4-old.tgz
# - https://www.dropbox.com/s/udkwfvpxscb70kz/mt5-old.tgz
# - https://www.dropbox.com/s/plxv8xerc7y2686/mt4.tgz
# - https://www.dropbox.com/s/mprcq2pc48ro8gd/mt5.tgz

#sudo chmod -R u+rwX,go+rX,go-w /opt
#sudo chown -R vagrant:vagrant /opt

# Clean up the logs.
find "$OUT" '(' -name "*.log" -or -name "*.dat" ')' -delete

# Add files to the git repository.
git --git-dir=/opt/.git add -A
git --git-dir=/opt/.git commit -m"$0: Downloaded MT4." -a

echo "$0 done."
