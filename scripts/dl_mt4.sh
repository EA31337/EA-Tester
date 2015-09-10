#!/bin/bash -x

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
wget -qO- https://www.dropbox.com/s/1obaq7wlk8h9sbu/mt4.tgz | sudo tar zxvf - -C /opt
# Other links:
# - https://www.dropbox.com/s/1d38i4vwkfw89g9/mt4-old.tgz
# - https://www.dropbox.com/s/udkwfvpxscb70kz/mt5-old.tgz
# - https://www.dropbox.com/s/plxv8xerc7y2686/mt4.tgz
# - https://www.dropbox.com/s/mprcq2pc48ro8gd/mt5.tgz

#sudo chmod -R u+rwX,go+rX,go-w /opt
#sudo chown -R vagrant:vagrant /opt

echo "$0 done."
