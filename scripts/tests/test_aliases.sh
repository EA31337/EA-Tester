#!/usr/bin/env bash
# Test .aliases.inc.sh file.
set -eEx -o pipefail

# Initialize.
. ../.funcs.inc.sh
initialize

# Includes required code.
. ../.aliases.inc.sh

# Test code
input="123"
input_encoded=$(printf "%s" "$input" | encode)
input_decoded=$(printf "%s" "$input_encoded" | decode)

# Asserts.
[ "$input" -eq "$input_decoded" ]

echo "${BASH_SOURCE[0]} done."
