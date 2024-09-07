#!/usr/bin/env bash
# Test compilation commands.
set -eE -o pipefail

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.funcs.cmds.inc.sh

# Installs both platforms.
install_mt 4 /opt
install_mt 5 /opt

# Load variables.
. ../.vars.inc.sh
[ -d "$TERMINAL_DIR" ]

echo INFO: Test compiling EA/script files.
clean_sources
[ "$(compile "$(ea_find Dummy)" /tmp/mql.log /s)" -eq 1 ]
[ "$(compile_ea "$(ea_find Dummy)" /tmp/mql.log /s)" -eq 1 ]
[ "$(compile_script "$(script_find Dummy)" /tmp/mql.log /s)" -eq 1 ]

echo INFO: Test copying EA files.
ea_copy "$(ea_find Dummy)"
ea_copy "$(ea_find TestBands)"

echo INFO: Test copying script files.
script_copy "$(script_find Dummy)"
script_copy "$(script_find PrintPaths)"

echo INFO: Test compiling EA/script files after copying.
[ "$(compile_ea Dummy)" -eq 1 ]
[ "$(compile_script Dummy)" -eq 1 ]

echo "${BASH_SOURCE[0]} done."
