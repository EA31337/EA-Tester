#!/bin/bash -x

#
# Provisioning script
#

# Initialize script.
if [ ! -d "/vagrant/scripts" ]; then
  echo "This script needs to be run within vagrant VM."
  exit 1
fi

shopt -s globstar # Enable globbing.

# Perform an unattended installation of a Debian packages.
sudo ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
sudo dpkg-reconfigure debconf -f noninteractive -p critical

# Configure locale (http://serverfault.com/a/500778/130437).
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#sudo locale-gen en_US.UTF-8
#sudo dpkg-reconfigure locales

# Install the locale packate to prevent an invalid locale.
sudo apt-get install -y language-pack-en

# Install basic utils.
sudo apt-get install -y links html2text

# Install and run X virtual framebuffer.
sudo apt-get install -y Xvfb xdotool

# Install wine
sudo dpkg --add-architecture i386
sudo add-apt-repository -y ppa:ubuntu-wine
sudo apt-get update
sudo apt-get install -y wine # wine-gecko2.36\* wine-mono4.5.6\*

# Install dependencies.
sudo apt-get install -y winbind

# Upgrade manually some packages from the source.
sudo apt-get install -y libx11-dev libxtst-dev libxinerama-dev libxkbcommon-dev

# Install xdotool.
git clone https://github.com/jordansissel/xdotool && make -C xdotool

# Run X virtual framebuffer on screen 0.
Xvfb :0 -screen 0 1024x768x16 & # Run X virtual framebuffer on screen 0.

# Give vagrant write permission for /opt.
sudo chown vagrant:vagrant /opt

echo "$0 done."
