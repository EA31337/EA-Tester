#!/usr/bin/env bash
# Define shell functions for dealing with SET file.
#

## Initialize.
[ -n "$OPT_VERBOSE" ] && echo "Loading ${BASH_SOURCE[0]}... " >&2
CWD="${CWD:-$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)}"

#
## Define SET functions. ##
#

# Set optimization params
# Usage: set_opt_params [param] [start] [end] (step)
set_opt_params() {
  # Optimization settings (F-On, 1-Min, 2-Step, 3-Max).
  input_set ^$1,F 1       # On.
  input_set ^$1,1 $2      # Min.
  input_set ^$1,2 ${4:-1} # Step.
  input_set ^$1,3 $3      # Max.
}
