#!/usr/bin/env bash
# Test eval.sh file.
set -eE -o pipefail

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.aliases.inc.sh

# Asserts.
bc_4=$(run bc <<< "2+2")
[ "$bc_4" -eq 4 ]

echo "${BASH_SOURCE[0]} done."
