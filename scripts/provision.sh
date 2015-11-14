#!/usr/bin/env bash

#
# Provisioning script
#

# Initialize script.
set -ex
if [ ! -d "/vagrant" ] && [ ! -d "/home/travis" ]; then
  echo "This script needs to be run within VM."
  exit 1
fi

whoami && pwd
shopt -s globstar # Enable globbing.

# Perform an unattended installation of a Debian packages.
ex +"%s@DPkg@//DPkg" -scwq /etc/apt/apt.conf.d/70debconf
dpkg-reconfigure debconf -f noninteractive -p critical

# Install the locale packate to prevent an invalid locale.
apt-get install -y language-pack-en

# Install basic utils.
apt-get install -y links html2text tree

# Install and run X virtual framebuffer and X utils.
apt-get install -y xvfb xdotool

# Install wine
#dpkg --add-architecture i386
add-apt-repository -y ppa:ubuntu-wine
# Skip unnecessary source indexes for a faster run
ex +'bufdo!%s/^deb-src/#deb-src/' -scxa /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu-wine-*.list
apt-get update
apt-get install -y wine

# Upgrade manually some packages from the source.
apt-get install -y libx11-dev libxtst-dev libxinerama-dev libxkbcommon-dev

# Install composer (https://getcomposer.org/) via PHP.
#apt-get install php5-cli
#curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Run X virtual framebuffer on screen 0.
export DISPLAY=:0
Xvfb $DISPLAY -screen 0 1024x768x16 & # Run X virtual framebuffer on screen 0.

# Set-up git.
git config --system user.name $USER
git config --system user.email "$USER@$HOSTNAME"
git config --system core.sharedRepository group

# Add version control for /opt.
git init /opt

# Give vagrant write permission for /opt.
chown -R vagrant:vagrant /opt

# Install VM specific binaries.
#install -v /vagrant/scripts/run_backtest.sh /usr/local/bin/run_backtest
#install -v /vagrant/scripts/run_optimizer.sh /usr/local/bin/run_optimizer

echo "$0 done."
