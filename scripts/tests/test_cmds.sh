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

echo INFO: Test finding EA files...
clean_sources
[ -f "$(ea_find Dummy)" ]
[ -f "$(MT_VER=4 ea_find Dummy.mq4)" ]
[ -f "$(MT_VER=5 ea_find Dummy.mq5)" ]

echo INFO: Test finding script files...
[ -f "$(script_find Dummy)" ]
[ -f "$(MT_VER=4 script_find Dummy.mq4)" ]
[ -f "$(MT_VER=5 script_find Dummy.mq5)" ]

echo INFO: Test copying EA files.
ea_copy "$(ea_find Dummy)"
ea_copy "$(ea_find TestBands)"

echo INFO: Test finding EA files after copying...
[ -f "$EXPERTS_DIR/$(ea_find Dummy)" ]
[ -f "$EXPERTS_DIR/$(MT_VER=4 ea_find Dummy.mq4)" ]
[ -f "$EXPERTS_DIR/$(MT_VER=5 ea_find Dummy.mq5)" ]

echo INFO: Test copying script files.
script_copy "$(script_find Dummy)"
script_copy "$(script_find PrintPaths)"

echo INFO: Test finding script files after copying...
[ -f "$SCRIPTS_DIR/$(script_find Dummy)" ]
[ -f "$SCRIPTS_DIR/$(MT_VER=4 script_find Dummy.mq4)" ]
[ -f "$SCRIPTS_DIR/$(MT_VER=5 script_find Dummy.mq5)" ]
