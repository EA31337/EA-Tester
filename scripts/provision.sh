#!/bin/bash -x

#
# Provisioning script
#

if [ ! -d "/vagrant/scripts" ]; then
  echo "This script needs to be run within vagrant VM."
  exit 1
fi

# Initialize script.
shopt -s globstar

# Install basic utils.
sudo apt-get install -y links

# Install and run X virtual framebuffer.
sudo apt-get install -y Xvfb xdotool
Xvfb :0 -screen 0 1024x768x16 & # Run X virtual framebuffer on screen 0.

# Install wine
sudo dpkg --add-architecture i386
sudo add-apt-repository -y ppa:ubuntu-wine
sudo apt-get update
sudo apt-get install -y wine wine-gecko2.36\* wine-mono4.5.6\*

# Install dependencies.
sudo apt-get install -y winbind

# Upgrade manually some packages from the source.
sudo apt-get install -y libx11-dev libxtst-dev libxinerama-dev libxkbcommon-dev

# Install xdotool.
git clone https://github.com/jordansissel/xdotool && make -C xdotool

# Download and install MT4/MT5 platforms.
# @todo: 1. Download platform.
#wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
#wget https://fx.instaforex.com/i/downloads/itc4setup.exe https://fx.instaforex.com/i/downloads/itc5setup.exe

# @todo: 2. Install platform (use xdotool to fake keyboard to navigate through the installator).
# export DISPLAY=:0
# wine mt4setup.exe
#xdotool key Space n
#wineserver -k # Kill leftover wine sessions.

# Otherwise download already pre-installed platform.
wget -O- https://www.dropbox.com/s/chw6mn9gq36f9lo/mt4-old.tgz | sudo tar zxvf - -C /opt
# Other links:
# - https://www.dropbox.com/s/1d38i4vwkfw89g9/mt4-old.tgz
# - https://www.dropbox.com/s/udkwfvpxscb70kz/mt5-old.tgz
# - https://www.dropbox.com/s/plxv8xerc7y2686/mt4.tgz
# - https://www.dropbox.com/s/mprcq2pc48ro8gd/mt5.tgz
sudo chmod -R u+rwX,go+rX,go-w /opt
sudo chown -R vagrant:vagrant /opt

# Download backtest data files.
TESTDIR="/opt/**/tester"
wget -P $TESTDIR https://www.dropbox.com/s/fkjalsjhqk9p5vm/EURUSD1_0.fxt.gz
wget -P $TESTDIR https://www.dropbox.com/s/rag8ky8kub9eum9/EURUSD1.hst.gz
gunzip -vfd /opt/**/*.gz

echo "Done."
