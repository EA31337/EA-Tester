#!/usr/bin/env bash
# .aliases.inc.sh file
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2

# Expand aliases in shell.
shopt -s expand_aliases

# Define aliases.
alias encode="base64"
alias decode="base64 -d"
