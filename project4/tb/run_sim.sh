# Simulation Script for Project 4 Testbench
# This script compiles and runs the WISC-25 processor testbench

# Choose your simulator (uncomment the one you have):
# Options: iverilog, modelsim, questasim, vcs

# ===== Icarus Verilog (iverilog) =====
# Compile the design and testbench
iverilog -o tb.vvp -I ../rtl ../rtl/hart.v tb.v
# Run the simulation
vvp tb.vvp > ../traces/simulation.log

# ===== ModelSim/QuestaSim =====
# # Create work library
# vlib work
# # Compile the design and testbench
# vlog -work work +incdir+../rtl ../rtl/hart.v tb.v
# # Run simulation
# vsim -c -do "run -all; quit" work.hart_tb > ../traces/simulation.log

# ===== VCS =====
# # Compile and simulate
# vcs -full64 +incdir+../rtl ../rtl/hart.v tb.v -o simv
# ./simv > ../traces/simulation.log
