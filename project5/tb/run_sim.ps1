# PowerShell Simulation Script for Project 5 Pipelined Processor
# This script compiles and runs the WISC-25 pipelined processor testbench

Write-Host "===================================" -ForegroundColor Cyan
Write-Host "  Project 5 Pipelined Processor  " -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Check which simulator is available and run accordingly
Write-Host "Checking for available Verilog simulators..."

# Check for Icarus Verilog
if (Get-Command iverilog -ErrorAction SilentlyContinue) {
    Write-Host "Found Icarus Verilog (iverilog)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Compiling design..." -ForegroundColor Yellow
    
    # Compile all RTL files
    iverilog -o tb.vvp -g2012 `
        -I ..\rtl `
        ..\rtl\hart.v `
        ..\rtl\fet.v `
        ..\rtl\dec.v `
        ..\rtl\ex.v `
        ..\rtl\mem.v `
        ..\rtl\wb.v `
        ..\rtl\pc.v `
        ..\rtl\ctrl.v `
        ..\rtl\hzrd.v `
        ..\rtl\frwd.v `
        ..\rtl\rf.v `
        ..\rtl\alu.v `
        ..\rtl\imm.v `
        ..\rtl\dmem.v `
        tb.v
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Compilation successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Running simulation..." -ForegroundColor Yellow
        Write-Host "======================================" -ForegroundColor Cyan
        vvp tb.vvp | Tee-Object -FilePath ..\traces\simulation.log
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Simulation complete!" -ForegroundColor Green
        Write-Host "Output saved to: traces\simulation.log" -ForegroundColor Cyan
        Write-Host "Waveform saved to: tb\hart.vcd" -ForegroundColor Cyan
    } else {
        Write-Host "Compilation failed!" -ForegroundColor Red
        Write-Host "Check the error messages above." -ForegroundColor Red
    }
}
# Check for ModelSim
elseif (Get-Command vsim -ErrorAction SilentlyContinue) {
    Write-Host "Found ModelSim/QuestaSim" -ForegroundColor Green
    Write-Host ""
    Write-Host "Creating work library..." -ForegroundColor Yellow
    if (Test-Path work) { Remove-Item -Recurse -Force work }
    vlib work
    
    Write-Host "Compiling design..." -ForegroundColor Yellow
    vlog -work work -sv `
        +incdir+..\rtl `
        ..\rtl\hart.v `
        ..\rtl\fet.v `
        ..\rtl\dec.v `
        ..\rtl\ex.v `
        ..\rtl\mem.v `
        ..\rtl\wb.v `
        ..\rtl\pc.v `
        ..\rtl\ctrl.v `
        ..\rtl\hzrd.v `
        ..\rtl\frwd.v `
        ..\rtl\rf.v `
        ..\rtl\alu.v `
        ..\rtl\imm.v `
        ..\rtl\dmem.v `
        tb.v
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Compilation successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Running simulation..." -ForegroundColor Yellow
        Write-Host "======================================" -ForegroundColor Cyan
        vsim -c -do "run -all; quit" work.hart_tb | Tee-Object -FilePath ..\traces\simulation.log
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Simulation complete!" -ForegroundColor Green
        Write-Host "Output saved to: traces\simulation.log" -ForegroundColor Cyan
    } else {
        Write-Host "Compilation failed!" -ForegroundColor Red
        Write-Host "Check the error messages above." -ForegroundColor Red
    }
}
else {
    Write-Host "No Verilog simulator found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  - Icarus Verilog: https://bleyer.org/icarus/"
    Write-Host "  - ModelSim (Intel FPGA Edition)"
    Write-Host ""
}
