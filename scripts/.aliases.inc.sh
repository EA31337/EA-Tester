#!/usr/bin/env bash
# .aliases.inc.sh file
#

## Initialize.
[ "$OPT_VERBOSE" ] && echo "Loading $0... " >&2

# Expand aliases in shell.
shopt -s expand_aliases

# Define aliases.
alias encode="base64"
alias decode="base64 -d"
