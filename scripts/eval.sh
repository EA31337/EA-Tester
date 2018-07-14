#!/usr/bin/env bash
# Script to invoke custom functions.
# Usage: eval.sh code to invoke
# For help, run: eval.sh help
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cd "$CWD" || exit 1

# Initialize settings.
. .vars.inc.sh
. .aliases.inc.sh
. .funcs.inc.sh
. .funcs.cmds.inc.sh

initialize
if [[ "$*" =~ ";" ]]; then
  eval "$*"
elif [ -n "$*" ]; then
  "$*"
fi
