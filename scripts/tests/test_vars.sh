#!/usr/bin/env bash
# Test .vars.inc.sh file.
set -ex

# Initialize.
. ../.funcs.inc.sh
initialize

# Test code
. ../.vars.inc.sh

echo "${BASH_SOURCE[0]} done."
