#!/bin/bash
# Bash Simulation Script for Project 5 Pipelined Processor
# This script compiles and runs the WISC-25 pipelined processor testbench

echo "==================================="
echo "  Project 5 Pipelined Processor  "
echo "==================================="
echo ""

# Check which simulator is available
echo "Checking for available Verilog simulators..."

if command -v iverilog &> /dev/null; then
    echo "Found Icarus Verilog (iverilog)"
    echo ""
    echo "Compiling design..."
    
    iverilog -o tb.vvp -g2012 \
        -I ../rtl \
        ../rtl/hart.v \
        ../rtl/fet.v \
        ../rtl/dec.v \
        ../rtl/ex.v \
        ../rtl/mem.v \
        ../rtl/wb.v \
        ../rtl/pc.v \
        ../rtl/ctrl.v \
        ../rtl/hzrd.v \
        ../rtl/frwd.v \
        ../rtl/rf.v \
        ../rtl/alu.v \
        ../rtl/imm.v \
        ../rtl/dmem.v \
        tb.v
    
    if [ $? -eq 0 ]; then
        echo "Compilation successful!"
        echo ""
        echo "Running simulation..."
        echo "======================================"
        vvp tb.vvp | tee ../traces/simulation.log
        echo "======================================"
        echo ""
        echo "Simulation complete!"
        echo "Output saved to: traces/simulation.log"
        echo "Waveform saved to: tb/hart.vcd"
    else
        echo "Compilation failed!"
        echo "Check the error messages above."
    fi
elif command -v vsim &> /dev/null; then
    echo "Found ModelSim/QuestaSim"
    echo ""
    echo "Creating work library..."
    rm -rf work
    vlib work
    
    echo "Compiling design..."
    vlog -work work -sv \
        +incdir+../rtl \
        ../rtl/hart.v \
        ../rtl/fet.v \
        ../rtl/dec.v \
        ../rtl/ex.v \
        ../rtl/mem.v \
        ../rtl/wb.v \
        ../rtl/pc.v \
        ../rtl/ctrl.v \
        ../rtl/hzrd.v \
        ../rtl/frwd.v \
        ../rtl/rf.v \
        ../rtl/alu.v \
        ../rtl/imm.v \
        ../rtl/dmem.v \
        tb.v
    
    if [ $? -eq 0 ]; then
        echo "Compilation successful!"
        echo ""
        echo "Running simulation..."
        echo "======================================"
        vsim -c -do "run -all; quit" work.hart_tb | tee ../traces/simulation.log
        echo "======================================"
        echo ""
        echo "Simulation complete!"
        echo "Output saved to: traces/simulation.log"
    else
        echo "Compilation failed!"
        echo "Check the error messages above."
    fi
else
    echo "No Verilog simulator found!"
    echo ""
    echo "Please install one of the following:"
    echo "  - Icarus Verilog: sudo apt-get install iverilog"
    echo "  - ModelSim (Intel FPGA Edition)"
    echo ""
fi
