#!/usr/bin/env bash
#
# Provisioning script.
# Note: Needs to be run as root within VM environment.
#

# Initialize script.
[ -n "$TRACE" ] && set -x
[ -n "$NOERR" ] || set -e
if [ ! -d /vagrant ] && [ ! -d /home/travis -a ! -f /.dockerenv ]; then
  echo "Error: This script needs to be run within container." >&2
  exit 1
elif [ -f ~/.provisioned ]; then
  echo "Note: System already provisioned, skipping." >&2
  exit 0
fi

#--- onerror()
##  @param $1 integer (optional) Exit status. If not set, use '$?'
onerror() {
  local exit_status=${1:-$?}
  local frame=0
  echo "ERROR: Exiting $0 with $exit_status" >&2
  # Show simple stack trace.
  while caller $((n++)); do :; done; >&2
  exit $exit_status
}

# Handle bash errors. Exit on error. Trap exit.
# Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR (9/KILL cannot be trapped).
trap onerror 1 2 3 15 ERR

# Check the Linux distribution.
echo "OS: $(uname -a)"
. /etc/*-release 2>/dev/null

# Detect proxy via curl.
(</dev/tcp/localhost/3128) 2> /dev/null && export http_proxy="http://localhost:3128"
GW=$(netstat -rn 2> /dev/null | grep "^0.0.0.0 " | cut -d " " -f10) && (</dev/tcp/$GW/3128) 2> /dev/null && export http_proxy="http://$GW:3128"

set -x
case "$(uname -s)" in

  Linux)

    # For Ubuntu/Debian.
    if which dpkg-reconfigure > /dev/null; then

        # Perform an unattended installation of a Debian packages.
        export DEBIAN_FRONTEND=noninteractive
        which ex > /dev/null && [ -f /etc/apt/apt.conf.d/70debconf ] && timeout 2 ex +"%s@DPkg@//DPkg" -scwq /etc/apt/apt.conf.d/70debconf
        dpkg-reconfigure debconf -f noninteractive
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

        # Omit source repositories from updates for performance reasons.
        which sed > /dev/null && find /etc/apt -type f -name '*.list' -execdir sed -i 's/^\(deb-src\)/#\1/' {} +

        # Enable 32 bit architecture for 64 bit systems (required for Wine).
        dpkg --add-architecture i386
    fi

    # Update APT index.
    [ -z "$NO_APT_UPDATE" ] && apt-get -qq update

    # Install basic utils (such as curl, wget and Vim).
    apt-get install -qy curl wget vim

    # Add PPA/Wine repository.
    # APT dependencies (for the add-apt-repository).
    apt-get install -qy software-properties-common python-software-properties
    # Adds GPG release key.
    apt-key add < <(curl -sq https://dl.winehq.org/wine-builds/winehq.key)
    # Adds APT Wine repository.
    add-apt-repository -y "deb http://dl.winehq.org/wine-builds/ubuntu/ ${DISTRIB_CODENAME:-xenial} main"

    # Update APT index.
    [ -z "$NO_APT_UPDATE" ] && apt-get -qq update

    # Install necessary packages
    apt-get install -qy language-pack-en                                          # Language pack to prevent an invalid locale.
    apt-get install -qy less binutils coreutils moreutils cabextract zip unzip    # Common CLI utils.
    apt-get install -qy imagemagick                                               # ImageMagick.
    apt-get install -qy dbus                                                      # Required for Debian AMI on EC2.
    apt-get install -qy git realpath links html2text tree pv bc                   # Required commands.
    apt-get install -qy ca-certificates

    # Install wine and dependencies.
    # @see: https://wiki.winehq.org/Ubuntu
    apt-get install -qy winehq-stable --install-recommends                        # Install Wine.
    apt-get install -qy xvfb xdotool x11-utils xterm                              # Virtual frame buffer and X11 utils.

    # Install required gems.
    apt-get install -qy ruby
    gem install gist
    # Apply a patch (https://github.com/defunkt/gist/pull/232).
    patch -d "$(gem env gemdir)"/gems/gist-* -p1 < <(curl -s https://github.com/defunkt/gist/commit/5843e9827f529cba020d08ac764d70c8db8fbd71.patch)

    # Setup SSH if requested.
    if [ -n "$PROVISION_SSH" ]; then
      apt-get install -y openssh-server
      [ ! -d /var/run/sshd ] && mkdir -v /var/run/sshd
      sed -i'.bak' 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
    fi

    # Setup sudo if requested.
    if [ -n "$PROVISION_SUDO" ]; then
      apt-get install sudo
      sed -i'.bak' "s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" /etc/sudoers
    fi

    # Erase downloaded archive files.
    apt-get clean

    # Install pup parser.
    install -v -m755 <(curl -sL https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_amd64.zip | gunzip) /usr/local/bin/pup

    # Setup swap file if none (exclude Docker image).
    if [ ! -f /.dockerenv -a -z "$(swapon -s)" ]; then
      if [ -f /var/cache/swap/swapfile ]; then
        swapon /var/cache/swap/swapfile
      else
        mkdir -pv /var/cache/swap
        cd /var/cache/swap
        dd if=/dev/zero of=swapfile bs=1K count=4M
        chmod 600 swapfile
        mkswap swapfile
        swapon swapfile
        cd - &>/dev/null
      fi
    fi
    ;;
  Darwin)
    brew install git
    brew install wine
  ;;
esac
set +x

# Set-up hostname.
grep "$(hostname)" /etc/hosts && echo "127.0.0.1 $(hostname)" >> /etc/hosts

# Find not a privileged user.
id travis  2>/dev/null && user="travis"
id vagrant 2>/dev/null && user="vagrant"
id ubuntu  2>/dev/null && user="ubuntu"

# Set-up git.
git config --system user.name $user
git config --system user.email "$user@$HOSTNAME"
git config --system core.sharedRepository group

# Add version control for /opt.
git init /opt

# Give user write permission for /opt.
chown -R $user /opt

# Mark system as provisioned.
> ~/.provisioned

echo "$0 done." >&2
