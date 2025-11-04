// Simple test program for Project 5 Pipelined Processor
// Tests: RAW hazards, forwarding, load-use hazards, and branches

.text
.global main

main:
    // Initialize x7 with target value (15)
    addi x7, x0, 15         // x7 = 15
    
    //==============================================
    // Test 1: RAW hazard with forwarding
    // Should forward from EX and MEM stages
    //==============================================
    addi x1, x0, 10         // x1 = 10
    addi x2, x1, 1          // x2 = 11 (needs x1, EX-EX forward)
    addi x3, x2, 1          // x3 = 12 (needs x2, EX-EX forward)
    addi x4, x3, 1          // x4 = 13 (needs x3, EX-EX forward)
    addi x5, x4, 1          // x5 = 14 (needs x4, EX-EX forward)
    addi x6, x5, 1          // x6 = 15 (needs x5, EX-EX forward)
    
    //==============================================
    // Test 2: Load-use hazard (should stall)
    //==============================================
    addi x10, x0, 0x100     // x10 = 0x100 (address)
    addi x11, x0, 42        // x11 = 42
    sw   x11, 0(x10)        // store 42 to memory[0x100]
    lw   x12, 0(x10)        // load from memory[0x100] → x12 = 42
    addi x13, x12, 1        // x13 = 43 (STALL: load-use hazard)
    
    //==============================================
    // Test 3: Branch prediction (always-not-taken)
    // This branch is taken, so should flush pipeline
    //==============================================
    beq  x6, x7, branch_target   // x6 == x7 == 15, TAKEN (flush 2 instr)
    lui  a0, 0xdead              // Should be flushed
    ebreak                       // Should be flushed

branch_target:
    //==============================================
    // Test 4: Not-taken branch (correct prediction)
    //==============================================
    addi x14, x0, 5         // x14 = 5
    addi x15, x0, 10        // x15 = 10
    bne  x14, x15, skip     // NOT taken (correct, no flush)
    addi x16, x0, 100       // x16 = 100 (executed)
    
skip:
    //==============================================
    // Test 5: JAL (always taken, should flush)
    //==============================================
    jal  x20, jump_target   // JAL always taken (flush 2 instr)
    lui  a0, 0xbad1         // Should be flushed
    ebreak                  // Should be flushed

jump_target:
    //==============================================
    // Test 6: Multiple forwarding paths
    //==============================================
    addi x21, x0, 1         // x21 = 1
    addi x22, x21, 2        // x22 = 3 (EX-EX forward)
    add  x23, x21, x22      // x23 = 4 (MEM-EX forward x21, EX-EX forward x22)
    
    //==============================================
    // Success: Exit with a0 = 1
    //==============================================
    li   a0, 1
    ebreak

// This program should:
// - Execute ~30 instructions
// - Have several stalls for load-use hazard
// - Have several flushes for taken branches/jumps
// - Demonstrate all forwarding paths
// - Exit successfully with a0 = 1
