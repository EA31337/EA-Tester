#!/bin/sh -e
# Script to install MT platform using winetricks.
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
type winetricks
winetricks $CWD/winetricks_mt5.verb
