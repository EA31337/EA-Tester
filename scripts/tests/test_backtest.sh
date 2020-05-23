#!/usr/bin/env bash
# Test run_backtest.sh file.
set -e

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.aliases.inc.sh
. ../.funcs.cmds.inc.sh

# Defines local variables.
file_stdout=/tmp/stdout
file_stderr=/tmp/stderr

# Asserts.

## Test script with missing parameters.
! run_backtest -_ 1>$file_stdout 2>$file_stderr
grep ^ERROR $file_stderr
wc -l "$file_stdout"
[ "$(wc -l "$file_stdout" | grep -o ^"[0-9]\+")" -eq 2 ]

echo "${BASH_SOURCE[0]} done."
