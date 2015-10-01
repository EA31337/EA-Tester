#!/usr/bin/env bash

#
# Provisioning script
#

# Initialize script.
set -x
if [ ! -d "/vagrant/scripts" ]; then
  echo "This script needs to be run within vagrant VM."
  exit 1
fi

whoami && pwd
shopt -s globstar # Enable globbing.

# Perform an unattended installation of a Debian packages.
ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
dpkg-reconfigure debconf -f noninteractive -p critical

# Configure locale (http://serverfault.com/a/500778/130437).
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#locale-gen en_US.UTF-8
#dpkg-reconfigure locales

# Install the locale packate to prevent an invalid locale.
apt-get install -y language-pack-en

# Install basic utils.
apt-get install -y links html2text tree

# Install and run X virtual framebuffer.
apt-get install -y Xvfb xdotool

# Install wine
dpkg --add-architecture i386
add-apt-repository -y ppa:ubuntu-wine
apt-get update
apt-get install -y wine # wine-gecko2.36\* wine-mono4.5.6\* winbind

# Upgrade manually some packages from the source.
apt-get install -y libx11-dev libxtst-dev libxinerama-dev libxkbcommon-dev

# Install composer (https://getcomposer.org/) via PHP.
#apt-get install php5-cli
#curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install xdotool.
git clone https://github.com/jordansissel/xdotool && make -C xdotool

# Run X virtual framebuffer on screen 0.
Xvfb :0 -screen 0 1024x768x16 & # Run X virtual framebuffer on screen 0.

# Set-up git.
git config --system user.name "Vagrant"
git config --system user.email "vagrant@localhost"
git config --system core.sharedRepository group

# Add version control for /opt.
git init /opt

# Give vagrant write permission for /opt.
chown -R vagrant:vagrant /opt

# Install VM specific binaries.
install -v /vagrant/scripts/run_backtest.sh /usr/local/bin/run_backtest
install -v /vagrant/scripts/run_optimizer.sh /usr/local/bin/run_optimizer

# Append extra settings into bashrc file.
ex +':$s@$@\ralias run_backtest=/vagrant/scripts/run_backtest.sh@' -cwq /etc/bash.bashrc

echo "$0 done."
