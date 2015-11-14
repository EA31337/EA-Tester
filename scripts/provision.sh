#!/bin/sh -e

#
# Provisioning script
#

# Initialize script.
if [ ! -d "/vagrant" ] && [ ! -d "/home/travis" ]; then
  echo "This script needs to be run within VM."
  exit 1
fi
whoami && pwd

# Init variables.
ARCH=$(dpkg --print-architecture)
id travis  && USER="travis"
id vagrant && USER="vagrant"

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
add-apt-repository -y ppa:ubuntu-wine/ppa
find /etc/apt/sources.list.d -type f -name '*.list' -exec apt-get update -o Dir::Etc::sourcelist="{}" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" ';'
apt-get -d update
apt-get install -y wine1.7 winetricks

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

# Give user write permission for /opt.
chown -R $USER /opt

echo "$0 done."
