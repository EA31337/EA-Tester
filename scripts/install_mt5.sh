#!/bin/sh
# Script to install MT platform using winetricks.
set -e
type winetricks
$(which winetricks) winetricks_mt5.verb