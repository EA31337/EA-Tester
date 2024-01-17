#!/usr/bin/env bash
# Test run_backtest.sh file.
set -ex -o pipefail

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.aliases.inc.sh
. ../.funcs.cmds.inc.sh

# Defines local variables.
file_stdout=/tmp/stdout
file_stderr=/tmp/stderr

# Defines global variables.
export OPT_TRACE=1
export RUN_ON_ERROR="tail $file_stdout $file_stderr"

# Enables trace messages.
[ -n "$OPT_TRACE" ] && set -x

## START TESTS

# Installs both platforms.
install_mt 4 /opt 1> $file_stdout 2> $file_stderr
install_mt 5 /opt 1> $file_stdout 2> $file_stderr

## Checks backtest with missing parameters.
! run_backtest -_ 1> $file_stdout 2> $file_stderr
grep ^"ERROR: You need to specify" $file_stdout

# Checks backtest with dummy script.
run_backtest -_ -s Dummy 1> $file_stdout 2> $file_stderr
grep "compiled: 1" $file_stdout
! grep ^ERROR $file_stderr

# Checks backtest with dummy script as EA.
run_backtest -_ -e Dummy 1> $file_stdout 2> $file_stderr
grep "compiled: 1" $file_stdout
! grep ^ERROR $file_stderr

echo "${BASH_SOURCE[0]} done."
