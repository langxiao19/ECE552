# Project 5 Testing Guide

## Quick Start

### Windows (PowerShell):
```powershell
cd project5\tb
.\run_sim.ps1
```

### Linux/Mac:
```bash
cd project5/tb
chmod +x run_sim.sh
./run_sim.sh
```

## What Gets Tested

The test program (`tests/asm/test_pipeline.asm`) verifies:

1. **RAW Hazards with Forwarding**
   - Back-to-back dependent instructions
   - EX-EX forwarding (1 cycle forward)
   - MEM-EX forwarding (2 cycles forward)

2. **Load-Use Hazards**
   - Load followed immediately by use
   - Should cause 1-cycle stall (bubble)

3. **Branch Prediction**
   - Taken branches → flush 2 instructions
   - Not-taken branches → no flush (correct prediction)
   
4. **Jumps (JAL/JALR)**
   - Always taken → always flush 2 instructions

## Expected Results

### ✅ Correct Behavior:
- Program should halt after **30-50 cycles**
- CPI should be approximately **1.3-1.7** (with forwarding and branch pred)
- Should exit with `a0 = 1` (success)
- Should NOT see `TRAP` messages

### ❌ Problems to Watch For:

**High CPI (> 2.0):**
- Forwarding not working properly
- Too many stalls being inserted
- Check forwarding signals in waveform

**Program doesn't halt:**
- Branch prediction might be wrong
- Infinite loop due to incorrect control flow
- Check flush signals

**Wrong results:**
- Data hazards not being handled
- Forwarding sending wrong data
- Check hazard detection logic

**TRAP messages:**
- Illegal instructions
- Misaligned memory accesses
- Check control logic

## Detailed Testing Steps

### Step 1: Compile Test Program

If you have a RISC-V toolchain:
```bash
cd project5/tests/asm
riscv32-unknown-elf-as -march=rv32i -o test_pipeline.o test_pipeline.asm
riscv32-unknown-elf-objcopy -O binary test_pipeline.o test_pipeline.bin
# Convert to hex format
python hex2mem.py test_pipeline.bin > ../../tb/program.mem
```

Or use existing test from project4:
```powershell
# Copy a known-good test
Copy-Item ..\..\project4\tests\asm\01add.hex project5\tb\program.mem
```

### Step 2: Run Simulation
```powershell
cd project5\tb
.\run_sim.ps1
```

### Step 3: Analyze Results

**Check the output:**
```
Cycle  PC        Inst     rs1            rs2            [rd, load, store]
[00000000] 00f00393 r[xx]=xxxxxxxx r[xx]=xxxxxxxx w[7]=0000000f
[00000004] 00a00093 r[xx]=xxxxxxxx r[xx]=xxxxxxxx w[1]=0000000a
[00000008] 00108113 r[1]=0000000a r[xx]=xxxxxxxx w[2]=0000000b
...
Program halted after 45 cycles.
Total instructions retired: 28
CPI: 1.607143
```

**Good signs:**
- All instructions execute in order
- No TRAP messages
- CPI between 1.3-1.7
- Program halts normally
- a0 = 1 at end

**Bad signs:**
- TRAP messages (illegal instruction)
- Very high CPI (> 2.5)
- Program doesn't halt
- Wrong register values

### Step 4: View Waveform (Optional)

If you have GTKWave installed:
```powershell
gtkwave tb\hart.vcd
```

**Signals to watch:**
- `hart_tb.dut.de_hold` - Should go high for load-use stalls
- `hart_tb.dut.fe_flush` - Should go high when branches taken
- `hart_tb.dut.de_frwd_*` - Forwarding control signals
- Pipeline registers: `*_vld` signals show instruction flow

## Testing Different Scenarios

### Test 1: Simple ADD Test (No Hazards)
Use the existing test from project4:
```powershell
Copy-Item ..\..\project4\tests\asm\program.mem project5\tb\
```

### Test 2: Load-Use Hazards
Create a program with back-to-back load-use:
```assembly
lw x1, 0(x10)
add x2, x1, x1    # Should stall 1 cycle
```

### Test 3: Branch-Heavy Program
```assembly
loop:
    addi x1, x1, 1
    blt x1, x10, loop    # Repeated branches
```

### Test 4: Maximum Forwarding
```assembly
add x1, x2, x3
add x4, x1, x5    # Forward x1 from EX
add x6, x4, x7    # Forward x4 from EX
add x8, x1, x6    # Forward x1 from MEM, x6 from EX
```

## Debugging Tips

### Problem: High CPI
1. Check if forwarding is enabled
2. Verify forwarding signals in waveform
3. Make sure stalls only happen for load-use

### Problem: Wrong Results
1. Check hazard detection signals
2. Verify forwarding mux selects correct data
3. Check flush is clearing instructions properly

### Problem: Infinite Loop
1. Check branch prediction flush
2. Verify PC update on branches
3. Make sure valid bits propagate correctly

### Problem: Compilation Errors
Check all module instantiations have correct ports:
```powershell
cd project5\rtl
# List all .v files
ls *.v
```

## Performance Targets

Based on reference implementation:

| Metric | Without Optimization | With Forwarding & Prediction |
|--------|---------------------|------------------------------|
| CPI    | ~2.5-3.0           | ~1.3-1.7                    |
| Stalls | Every RAW hazard    | Load-use only               |
| Flushes| N/A                | Taken branches only         |

## Gradescope Submission

After local testing passes:
1. Commit your changes
2. Push to repository
3. Submit to Gradescope
4. Check both accuracy and CPI tests

The autograder will:
- Run multiple test programs
- Check correctness (register values, memory)
- Measure CPI performance
- Compare against reference implementation

Good luck! 🚀
