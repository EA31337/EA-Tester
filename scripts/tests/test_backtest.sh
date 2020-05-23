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
set -x

## Checks backtest with missing parameters.
! run_backtest -_ 1>$file_stdout 2>$file_stderr
grep ^ERROR $file_stdout

## Checks backtest with dummy script.
#run_backtest -_ -s Dummy 1>$file_stdout 2>$file_stderr
#grep "compiled: 1" $file_stdout
#! grep ^ERROR $file_stderr

## Checks backtest with dummy script as EA.
#run_backtest -_ -x -e Dummy 1>$file_stdout 2>$file_stderr
#grep "compiled: 1" $file_stdout
#! grep ^ERROR $file_stderr

echo "${BASH_SOURCE[0]} done."
