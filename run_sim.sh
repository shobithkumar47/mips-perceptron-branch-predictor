#!/bin/sh
# Simulate the CPU with Icarus Verilog.
# Usage: ./run_sim.sh baseline     or     ./run_sim.sh perceptron
set -e
V=${1:-perceptron}
case "$V" in baseline|perceptron) ;; *) echo "usage: $0 baseline|perceptron"; exit 1;; esac
mkdir -p build
cp mem/meminstr.mem mem/memdata.mem build/
iverilog -g2012 -s TB_MIPS_CPU -o build/$V.out rtl/common/*.v rtl/$V/*.v tb/$V/TB_MIPS_CPU.v
cd build && vvp -n $V.out > $V.log
sed -n '/PERFORMANCE REPORT/,/TEST P\|TEST F/p' $V.log
