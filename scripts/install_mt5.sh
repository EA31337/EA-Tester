#!/bin/sh -e
# Script to install MT platform using winetricks.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
export WINEDLLOVERRIDES="mscoree,mshtml="

# Check the dependencies.
type winetricks

echo "Installing platform..." >&2
winetricks $CWD/winetricks_mt5.verb

echo "Installation successful." >&2
echo "$0 done." >&2
