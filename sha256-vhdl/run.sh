#!/usr/bin/env bash
DIRNAME=$(dirname "$0")  # get current dir regardless of where the script is ran from

ghdl -a --std=08 --workdir=$DIRNAME/build $DIRNAME/src/*.vhdl
ghdl -e --std=08 --workdir=$DIRNAME/build sha256
ghdl -r --std=08 --workdir=$DIRNAME/build sha256
