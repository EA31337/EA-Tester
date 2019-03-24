#!/usr/bin/env bash
#
# Provisioning script.
# Note: Needs to be run as root within VM environment.
#

# Initialize script.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
if [ ! -d /vagrant -a ! -d /home/travis -a ! -f /.dockerenv ]; then
  echo "Error: This script needs to be run within container." >&2
  exit 1
elif [ -f ~/.provisioned -a -z "$OPT_FORCE" ]; then
  echo "Info: System already provisioned, skipping." >&2
  exit 0
fi

#--- on_error()
##  @param $1 integer (optional) Exit status. If not set, use '$?'
on_error() {
  local exit_status=${1:-$?}
  local frame=0
  echo "ERROR: Exiting $0 with $exit_status" >&2
  # Show simple stack trace.
  while caller $((n++)); do :; done; >&2
  exit $exit_status
}

# Handle bash errors. Exit on error. Trap exit.
# Trap non-normal exit signals: 1/HUP, 2/INT, 3/QUIT, 15/TERM, ERR (9/KILL cannot be trapped).
trap on_error 1 2 3 15 ERR

# Check the Linux distribution.
echo "OS: $(uname -a)"
. /etc/*-release 2>/dev/null

# Find a non-privileged user.
id travis  2>/dev/null && user="travis"
id vagrant 2>/dev/null && user="vagrant"
id ubuntu  2>/dev/null && user="ubuntu"
if [ -z "$user" ]; then
  echo "Error: Cannot detect non-provileged user. Use Docker instead." >&2
  exit 1
fi

# Detect proxy via curl.
(</dev/tcp/localhost/3128) 2> /dev/null && export http_proxy="http://localhost:3128"
GW=$(netstat -rn 2> /dev/null | grep "^0.0.0.0 " | cut -d " " -f10) && (</dev/tcp/$GW/3128) 2> /dev/null && export http_proxy="http://$GW:3128"

set -x
case "$(uname -s)" in

  Linux)

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
      echo "Swap file configured successfully." >&2
    fi &

    # For Ubuntu/Debian.
    echo "Configuring APT..." >&2
    if which dpkg-reconfigure > /dev/null; then

        # Perform an unattended installation of a Debian packages.
        export DEBIAN_FRONTEND=noninteractive
        # Disable pre-configuration of all packages with debconf before they are installed.
        which sed &> /dev/null && sed -i'.bak' "s@DPkg@//DPkg@" /etc/apt/apt.conf.d/70debconf
        dpkg-reconfigure debconf -f noninteractive
        # Accept EULA for MS Core Fonts.
        echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections

        # Omit source repositories from updates for performance reasons.
        which sed > /dev/null && find /etc/apt -type f -name '*.list' -execdir sed -i 's/^\(deb-src\)/#\1/' {} +

        # Enable 32 bit architecture for 64 bit systems (required for Wine).
        dpkg --add-architecture i386
    fi

    # Update APT index.
    [ -z "$NO_APT_UPDATE" ] && (
      echo "Updating APT packages..." >&2
      apt-get -qq update
    )

    # Install curl and wget if not present.
    which curl &>/dev/null || apt-get install -qq curl
    which wget &>/dev/null || apt-get install -qq wget

    # Add PPA/Wine repository.
    echo "Adding PPA/Wine repository..." >&2
    # Adds GPG release key.
    apt-key add < <(curl -sq https://dl.winehq.org/wine-builds/winehq.key)
    # APT dependencies (for the add-apt-repository).
    which add-apt-repository || apt-get install -qq software-properties-common python-software-properties
    # Adds APT Wine repository.
    add-apt-repository -y "deb http://dl.winehq.org/wine-builds/ubuntu/ ${DISTRIB_CODENAME:-xenial} main"

    # Update APT index.
    [ -z "$NO_APT_UPDATE" ] && (
      echo "Updating APT packages..." >&2
      apt-get -qq update
    )

    # Install necessary packages
    echo "Installing APT packages..." >&2
    apt-get install -qq build-essential                                           # Install C, C++ compilers and development (make).
    apt-get install -qq language-pack-en                                          # Language pack to prevent an invalid locale.
    apt-get install -qq ca-certificates
    apt-get install -qq dbus                                                      # Required for Debian AMI on EC2.

    # Install wine and dependencies.
    # @see: https://wiki.winehq.org/Ubuntu
    apt-get install -qq winehq-stable wine-gecko --install-recommends             # Install Wine.
    apt-get install -qq xvfb xdotool x11-utils xterm                              # Virtual frame buffer and X11 utils.

    # Setup display.
    DISPLAY=${DISPLAY:-:0}
    xdpyinfo &>/dev/null || (! pgrep -a Xvfb && Xvfb $DISPLAY -screen 0 1024x768x16) &

    # Install AHK.
    if [ -n "$PROVISION_AHK" ]; then
      echo "Installing AutoHotkey..." >&2
      su - $user -c "
        wget -qP /tmp -nc 'https://github.com/Lexikos/AutoHotkey_L/releases/download/v1.1.30.01/AutoHotkey_1.1.30.01_setup.exe' && \
        DISPLAY=$DISPLAY wine /tmp/AutoHotkey_*.exe /S && \
        rm -v /tmp/AutoHotkey_*.exe
      "
      ahk_path=$(su - $user -c 'winepath -u "c:\\Program Files\\AutoHotkey"');
      if [ -d "$ahk_path" ]; then
        echo "AutoHotkey installed successfully!" >&2
      else
        echo "Error: AutoHotkey installation failed!" >&2
        exit 1
      fi
    fi &

    # Setup VNC.
    if [ -n "$PROVISION_VNC" ]; then
      echo "Installing VNC..." >&2
      apt-get install -qq x11vnc fluxbox
    fi

    # Install other CLI tools.
    apt-get install -qq less binutils coreutils moreutils cabextract zip unzip    # Common CLI utils.
    apt-get install -qq git realpath links tree pv bc                             # Required commands.
    apt-get install -qq html2text jq                                              # Required parsers.
    apt-get install -qq imagemagick                                               # ImageMagick.
    apt-get install -qq vim                                                       # Vim.

    # Install required gems.
    apt-get install -qq ruby
    gem install gist
    # Apply a patch (https://github.com/defunkt/gist/pull/232).
    (
      patch -d "$(gem env gemdir)"/gems/gist-* -p1 < <(curl -s https://github.com/defunkt/gist/commit/5843e9827f529cba020d08ac764d70c8db8fbd71.patch)
    ) &

    # Setup SSH if requested.
    if [ -n "$PROVISION_SSH" ]; then
      apt-get install -qq openssh-server
      [ ! -d /var/run/sshd ] && mkdir -v /var/run/sshd
      sed -i'.bak' 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
    fi

    # Setup sudo if requested.
    if [ -n "$PROVISION_SUDO" ]; then
      apt-get install -qq sudo
      sed -i'.bak' "s/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD:ALL/g" /etc/sudoers
    fi

    # Install pup parser.
    (
      install -v -m755 <(curl -sL https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_v0.4.0_linux_amd64.zip | gunzip) /usr/local/bin/pup
    ) &

    # Erase downloaded archive files.
    apt-get clean

    ;;
  Darwin)
    brew install git
    brew install wine
  ;;
esac
set +x

# Set-up git.
(
  git config --system user.name $user
  git config --system user.email "$user@$HOSTNAME"
  git config --system core.sharedRepository group
) &

# Add version control for /opt.
git init /opt &

# Give user write permission for /opt.
chown -R $user /opt &

# Wait for background jobs to finish.
pkill Xvfb
jobs
wait

# Mark system as provisioned.
> ~/.provisioned

echo "$0 done." >&2
