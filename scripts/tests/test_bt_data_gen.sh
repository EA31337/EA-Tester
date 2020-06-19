#!/usr/bin/env bash
# Test generation of backtest data.
set -eEx -o pipefail

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
      file="$dst/${type}-s${spread}-d${digits}.csv"
      # Convert to CSV.
      bt_data_gen -p $type -o "$file" -s $spread -D $digits 2020.01.01 2020.01.02 1.0 2.0
      # Convert to binary format.
      for format in fxt4 hst4 hcc; do
        for tf in M1 M5 M15 M30 H1 H4 D1 W1 MN1; do
          conv_csv_to_mt -i "$file" -d "$dst" -f $format -t $tf -s ${type^^}
        done
      done
    done
  done
done

## Test generated files.
for format in hst fxt hcc; do
  find "$dst" -name "*.${format}" -print0 | while IFS= read -r -d '' file; do
    mt_read -f "$file" -t "${format}-header" > /dev/null
  done
done

echo "${BASH_SOURCE[0]} done."
