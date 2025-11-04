# PowerShell Simulation Script for Project 4 Testbench
# This script compiles and runs the WISC-25 processor testbench on Windows

# Check which simulator is available and run accordingly

Write-Host "Checking for available Verilog simulators..."

# Check for Icarus Verilog
if (Get-Command iverilog -ErrorAction SilentlyContinue) {
    Write-Host "Found Icarus Verilog (iverilog)"
    Write-Host "Compiling design..."
    iverilog -o tb.vvp -I ..\rtl ..\rtl\hart.v tb.v
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Running simulation..."
        vvp tb.vvp | Tee-Object -FilePath ..\traces\simulation.log
        Write-Host "`nSimulation complete. Check traces\simulation.log for output."
    } else {
        Write-Host "Compilation failed!" -ForegroundColor Red
    }
}
# Check for ModelSim
elseif (Get-Command vsim -ErrorAction SilentlyContinue) {
    Write-Host "Found ModelSim/QuestaSim"
    Write-Host "Creating work library..."
    vlib work
    Write-Host "Compiling design..."
    vlog -work work +incdir+..\rtl ..\rtl\hart.v tb.v
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Running simulation..."
        vsim -c -do "run -all; quit" work.hart_tb | Tee-Object -FilePath ..\traces\simulation.log
        Write-Host "`nSimulation complete. Check traces\simulation.log for output."
    } else {
        Write-Host "Compilation failed!" -ForegroundColor Red
    }
}
else {
    Write-Host "No Verilog simulator found!" -ForegroundColor Red
    Write-Host "Please install one of the following:"
    Write-Host "  - Icarus Verilog: https://bleyer.org/icarus/"
    Write-Host "  - ModelSim (Intel FPGA Edition): https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html"
    Write-Host "  - Or use the Docker-based simulation"
}
