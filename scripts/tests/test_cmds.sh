#!/usr/bin/env bash
# Test .funcs.cmds.inc.sh file.
set -e

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.funcs.cmds.inc.sh

# Asserts.
help

echo "${BASH_SOURCE[0]} done."
