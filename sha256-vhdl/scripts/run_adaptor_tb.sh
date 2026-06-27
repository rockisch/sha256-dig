#!/usr/bin/env bash
set -e
DIRNAME="$(cd "$(dirname "$0")" && pwd)/.."

mkdir -p "$DIRNAME/build"
( cd "$DIRNAME/build" && ghdl --remove --std=08 )
( cd "$DIRNAME/build" && ghdl -i --std=08 "$DIRNAME"/src/rtl/*.vhdl )
( cd "$DIRNAME/build" && ghdl -m --std=08 sha256_adaptor_tb )
( cd "$DIRNAME/build" && ghdl -r --std=08 sha256_adaptor_tb )
