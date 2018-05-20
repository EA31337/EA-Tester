#!/usr/bin/env bash
# Script to invoke custom functions.
# Usage: eval.sh code to invoke
# For help, run: eval.sh help
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# Initialize settings.
. $CWD/.vars.inc.sh
. $CWD/.funcs.cmds.inc.sh
eval "$@"
