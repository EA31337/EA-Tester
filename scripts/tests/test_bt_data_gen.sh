#!/usr/bin/env bash
# Test .funcs.cmds.inc.sh file.
set -e

# Initialize.
. ../.funcs.inc.sh
initialize

# Defines variables.
dst="/tmp"

# Includes required code.
. ../.funcs.cmds.inc.sh

# Asserts.

## Test generation of data.
for type in none wave curve zigzag random; do
  for spread in 10 20; do
    for digits in 4 5; do
      filename="${type}-s${spread}-d${digits}.csv"
      bt_data_gen -p $type -o "$dst/$filename" -s $spread -D $digits 2020.01.01 2020.01.02 1.0 2.0
    done
  done
done

echo "${BASH_SOURCE[0]} done."
