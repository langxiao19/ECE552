`default_nettype none

/**
*   Forwarding Unit
*   
*   This module selects inputs to ALU based on control signals
*           control signals either come from control unit or hazard detection unit
*   
*   In the case where a Read-After-Write Hazard is detected, we can reduce cpi by
*           forwarding outputs from memory or alu output to alu input
*   
*   Forwarding priority:
*   1. Check if forwarding needed (from hazard unit)
*   2. If EX-EX forwarding: use i_alu_res (most recent)
*   3. If MEM-EX forwarding: use i_mem_res
*   4. Otherwise: use register file data
*/

module frwd
(
    input wire          i_auipc,        //load pc into op1
    input wire          i_imm,          //load immediate to op2
    input wire          i_jal,          //load 4 into op2
    input wire          i_jalr,
    input wire          i_mem_reg,      //select ALU or memory result
    input wire [31:0]   i_pc,           //program counter value
    input wire [31:0]   i_rs1_rdata,    //rs1 data from rf
    input wire [31:0]   i_rs2_rdata,    //rs2 data from rf
    input wire [31:0]   i_immediate,    //immediate value

    input wire          i_frwd_alu_op1, //forward from alu result op1
    input wire          i_frwd_mem_op1, //forward from memory result op1
    input wire          i_frwd_alu_op2, //forward from alu result op2
    input wire          i_frwd_mem_op2, //forward from memory result op2

    input wire [31:0]   i_alu_res,      //alu output from EX stage
    input wire [31:0]   i_mem_res,      //memory result from MEM stage

    output wire [31:0]  o_op1,          //alu op1
    output wire [31:0]  o_op2           //alu op2
);

    // Internal signals for forwarded values
    wire [31:0] rs1_fwd;
    wire [31:0] rs2_fwd;
    
    // Select RS1 value with forwarding
    // Priority: EX-EX forward > MEM-EX forward > Register file
    assign rs1_fwd = i_frwd_alu_op1 ? i_alu_res :
                     i_frwd_mem_op1 ? i_mem_res :
                                      i_rs1_rdata;
    
    // Select RS2 value with forwarding
    // Priority: EX-EX forward > MEM-EX forward > Register file
    assign rs2_fwd = i_frwd_alu_op2 ? i_alu_res :
                     i_frwd_mem_op2 ? i_mem_res :
                                      i_rs2_rdata;

    // Data being fed to ALU changes based on specific instruction
    // OP1: PC for AUIPC, otherwise forwarded RS1
    assign o_op1 = (i_auipc) ? i_pc : rs1_fwd;
    
    // OP2: Immediate for I-type, 4 for JAL/JALR (to compute return addr), otherwise forwarded RS2
    assign o_op2 = (i_imm)          ? i_immediate :
                   (i_jal | i_jalr) ? 32'd4       :
                                      rs2_fwd;

endmodule

`default_nettype wire