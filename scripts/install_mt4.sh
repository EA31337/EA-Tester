#!/usr/bin/env bash
# Script to install MT4 platform using winetricks.
[ -n "$OPT_NOERR" ] || set -e
[ -n "$OPT_TRACE" ] && set -x
CWD="$(
  cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" 2> /dev/null
  pwd -P
)"
type ansible > /dev/null
type ansible-galaxy > /dev/null
type winetricks > /dev/null

# Load variables.
export WINETRICKS_DOWNLOADER_RETRIES=${WINETRICKS_DOWNLOADER_RETRIES:-10}
export WINETRICKS_DOWNLOADER=curl

# Initializing
echo "Initializing..." >&2
curl -s ifconfig.me/all.json

# Load the shell functions.
. "$CWD/.funcs.inc.sh"
. "$CWD/.funcs.cmds.inc.sh"

# Install Ansible Galaxy requirements.
ansible-galaxy install -r /opt/ansible/galaxy-requirements.yml

# Install platform.
echo "Installing platform..." >&2
ansible-playbook -c local -i "localhost," /opt/ansible/install-mt4.yml -v

. "$CWD"/.vars.inc.sh
if [ -n "$TERMINAL4_DIR" ]; then
  echo "Terminal path: $TERMINAL4_DIR" >&2
  echo "Installation successful." >&2
else
  echo "Installation failed!" >&2
  exit 1
fi

echo "${BASH_SOURCE[0]} done." >&2
