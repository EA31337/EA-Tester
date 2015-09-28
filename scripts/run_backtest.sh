#!/bin/bash 
# Initialize variables and settings.
: ${1?"Usage: $0 (dir)"} || exit 1
ROOT=$(git rev-parse --show-toplevel)

# Find the ini files.
inis=($(find $ROOT/$1 -name \*.ini))

# Parse configuration and run the tests.
for ini in ${inis[@]}; do
  . <(grep = "$ini" | sed "s/;/#/g") # Load ini values.
  dir=$(dirname $ini)
  for deposit in ${deposits[@]}; do
    for year in ${years[@]}; do
      for source in ${sources[@]}; do
        for spread in ${spreads[@]}; do
          ./run_test.sh "$dir" $setfile $mode $symbol $deposit $year $spread $source 
        done
      done
    done
  done
done
