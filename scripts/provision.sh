#!/bin/sh -e

#
# Provisioning script
#

# Initialize script.
if [ ! -d /vagrant ] && [ ! -d /home/travis ] && [ ! -f /.dockerinit ]; then
  echo "This script needs to be run within VM."
  exit 1
fi
whoami && lsb_release -a && pwd
type curl || apt-get -y install curl
type dpkg apt-get

# Init variables.
ARCH=$(dpkg --print-architecture)
id travis  && USER="travis"
id vagrant && USER="vagrant"

# Detect proxy.
GW=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
curl -s localhost:3128 --connect-timeout 2 > /dev/null && export http_proxy="http://localhost:3128"
curl -s       $GW:3128 --connect-timeout 2 > /dev/null && export http_proxy="http://$GW:3128"

# Perform an unattended installation of a Debian packages.
export DEBIAN_FRONTEND=noninteractive
ex +"%s@DPkg@//DPkg" -scwq /etc/apt/apt.conf.d/70debconf
dpkg-reconfigure debconf -f noninteractive
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections

dpkg --add-architecture i386 || true                                                  # Add i386 architecture for Wine
add-apt-repository -y ppa:ubuntu-wine/ppa                                             # Add PPA/Wine repository
sudo find /etc/apt -type f -name '*.list' -execdir sed -i 's/^\(deb-src\)/#\1/' {} +  # Omit source repositories from updates

# Update APT repositories
apt-get -qq update

# Install necessary packages
apt-get install -qy language-pack-en                                          # Language pack to prevent an invalid locale.
apt-get install -qy binutils coreutils moreutils cabextract                   # Common CLI utils.
apt-get install -qy dbus                                                      # Required for Debian AMI on EC2.
apt-get install -qy git realpath links html2text tree pv                      # Required commands.
apt-get install -qy software-properties-common python-software-properties     # APT dependencies (required for a docker image).
apt-get install -qy wine1.8 winbind xvfb xdotool                              # Wine from PPA/Wine and tools for MT4 installer.

# Set-up hostname.
grep $(hostname) /etc/hosts && echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Set-up git.
git config --system user.name $USER
git config --system user.email "$USER@$HOSTNAME"
git config --system core.sharedRepository group

# Add version control for /opt.
git init /opt

# Give user write permission for /opt.
chown -R $USER /opt

echo "$0 done."
