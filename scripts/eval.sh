#!/usr/bin/env bash
# Script to invoke custom code.
# Usage: eval.sh code to invoke
# E.g.: eval.sh check_logs ExpertRemove
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
# Initialize settings.
. $CWD/.vars.inc.sh
. $CWD/.funcs.inc.sh
eval $@
