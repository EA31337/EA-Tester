#!/usr/bin/env bash
# Test .vars.inc.sh file.
set -ex

# Test code
. ../.vars.inc.sh

echo "${BASH_SOURCE[0]} done."
