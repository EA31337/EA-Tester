#!/usr/bin/env bash
# Test .vars.inc.sh file.
set -eEx -o pipefail

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.vars.inc.sh

# Test code

echo "${BASH_SOURCE[0]} done."
