# Quick Test Commands

## Run Simulation Now (Windows)
```powershell
cd c:\Work\ECE552\wisc25-dist\project5\tb
.\run_sim.ps1
```

## Run Simulation Now (Linux/Mac)
```bash
cd project5/tb
chmod +x run_sim.sh
./run_sim.sh
```

## What to Expect

The test program (`tb/program.mem`) tests:
- ✅ RAW hazards with forwarding
- ✅ Taken branch with flush
- ✅ Should exit with a0 = 0x1

### Expected Output:
```
Loading program.
Resetting hart.
Cycle  PC        Inst     rs1            rs2            [rd, load, store]
[00000000] 00f00393 r[xx]=xxxxxxxx r[xx]=xxxxxxxx w[7]=0000000f
[00000004] 00a00093 r[xx]=xxxxxxxx r[xx]=xxxxxxxx w[1]=0000000a
[00000008] 00108113 r[1]=0000000a r[xx]=xxxxxxxx w[2]=0000000b
[0000000c] 00110193 r[2]=0000000b r[xx]=xxxxxxxx w[3]=0000000c
[00000010] 00118213 r[3]=0000000c r[xx]=xxxxxxxx w[4]=0000000d
[00000014] 00120293 r[4]=0000000d r[xx]=xxxxxxxx w[5]=0000000e
[00000018] 00128313 r[5]=0000000e r[xx]=xxxxxxxx w[6]=0000000f
[0000001c] 00730863 r[6]=0000000f r[7]=0000000f
[00000024] 00001537 r[xx]=xxxxxxxx r[xx]=xxxxxxxx w[10]=00001000
[00000028] 00100073 r[xx]=xxxxxxxx r[xx]=xxxxxxxx
Program halted after X cycles.
Total instructions retired: 10
CPI: 1.X
```

## Checking if it Works

### ✅ Success Indicators:
- Program halts normally
- Final a0 register = 0x1 (shown as w[10]=00001000)
- CPI between 1.2 - 1.8
- No TRAP messages
- Instructions execute in correct order

### ❌ Failure Indicators:
- Program runs forever (> 1000 cycles)
- TRAP messages appear
- Wrong register values
- CPI > 2.5

## Quick Debug Checks

### If simulation doesn't compile:
```powershell
# Check all files exist
ls ..\rtl\*.v
```

### If program doesn't halt:
- Branch prediction might be wrong (check flush)
- PC not updating correctly
- Check waveform: `gtkwave hart.vcd`

### If wrong results:
- Forwarding not working (check frwd.v)
- Hazard detection wrong (check hzrd.v)
- Stalls not inserting NOPs (check dec.v)

### If CPI too high:
- Too many stalls (should only stall for load-use)
- Forwarding not enabled
- Check forwarding signals: `de_frwd_*`

## View Waveform
```powershell
# If GTKWave is installed
gtkwave hart.vcd
```

**Key signals to watch:**
- `de_hold` - High when stalling
- `fe_flush` - High when flushing for branch
- `de_frwd_alu_op1` - Forward from EX stage to op1
- `de_frwd_mem_op1` - Forward from MEM stage to op1
- Pipeline valid bits: `fe_vld`, `de_vld`, `ex_vld`, etc.

## Next Steps

1. ✅ Run basic test (above)
2. Copy tests from project4: `Copy-Item ..\..\project4\tests\asm\*.hex tb\program.mem`
3. Create custom test programs
4. Submit to Gradescope

## Files Created/Modified

- ✅ `rtl/hzrd.v` - Hazard detection
- ✅ `rtl/frwd.v` - Forwarding unit
- ✅ `rtl/pc.v` - Branch prediction
- ✅ `rtl/dec.v` - Stall/flush handling
- ✅ `rtl/ex.v` - Bug fixes
- ✅ `rtl/hart.v` - Signal connections
- ✅ `tb/run_sim.ps1` - Windows test script
- ✅ `tb/run_sim.sh` - Linux test script
- ✅ `tb/program.mem` - Test program

All ready to test! 🚀
