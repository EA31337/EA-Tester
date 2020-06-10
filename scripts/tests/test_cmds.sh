#!/usr/bin/env bash
# Test .funcs.cmds.inc.sh file.
set -e

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.funcs.cmds.inc.sh

# Asserts.
help | grep "Usage" >/dev/null

# Load variables.
. ../.vars.inc.sh

# Test finding EA files.
[ -f "$(ea_find Dummy)" ]
[ -f "$(MT_VER=4 ea_find Dummy.mq4)" ]
[ -f "$(MT_VER=5 ea_find Dummy.mq5)" ]

# Test finding script files.
[ -f "$(script_find Dummy)" ]
[ -f "$(MT_VER=4 script_find Dummy.mq4)" ]
[ -f "$(MT_VER=5 script_find Dummy.mq5)" ]

# Test copying EA files.
ea_copy "$(ea_find Dummy)"
ea_copy "$(ea_find TestBands)"

# Test copying script files.
script_copy "$(script_find Dummy)"
script_copy "$(script_find PrintPaths)"

# Test compiling EA/script files.
script_find Dummy
[ "$(compile "$(script_find Dummy)" /tmp/mql.log /s)" -eq 1 ]
[ "$(compile_ea "$(script_find Dummy)" /tmp/mql.log /s)" -eq 1 ]
[ "$(compile_script "$(script_find Dummy)" /tmp/mql.log /s)" -eq 1 ]

echo "${BASH_SOURCE[0]} done."
