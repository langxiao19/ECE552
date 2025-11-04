/**
*   Hazard Detection Unit
*   
*   Detects RAW (Read-After-Write) hazards and generates stall/forwarding signals
*   - Load-use hazards require stalls (1 cycle bubble)
*   - Other RAW hazards can use forwarding (EX-EX or MEM-EX)
*/

module hzrd
(
    input wire          i_clk,          // Global Clock
    input wire          i_rst,          // Global Reset
    // Decode stage valid (only detect hazards when instruction is valid)
    input wire          i_id_vld,
    
    // Current instruction in decode stage
    input wire [4:0]    i_rs1_raddr,    // RS1 being read in decode
    input wire [4:0]    i_rs2_raddr,    // RS2 being read in decode
    
    // EX stage signals
    input wire          i_ex_rd_wen,    // EX stage will write to register
    input wire [4:0]    i_ex_rd_waddr,  // EX stage destination register
    input wire          i_ex_mem_read,  // EX stage is a load instruction
    
    // MEM stage signals  
    input wire          i_mem_rd_wen,   // MEM stage will write to register
    input wire [4:0]    i_mem_rd_waddr, // MEM stage destination register

    output wire         o_if_id_halt,   // Halt IF/ID pipeline (stall fetch)
    output wire         o_id_ex_halt,   // Halt ID/EX pipeline (insert bubble)
    output wire         o_frwd_alu_op1, // Forward from EX stage (ALU result) to op1
    output wire         o_frwd_mem_op1, // Forward from MEM stage to op1
    output wire         o_frwd_alu_op2, // Forward from EX stage (ALU result) to op2
    output wire         o_frwd_mem_op2  // Forward from MEM stage to op2
);

    // Detect if current instruction reads from a register (gate with valid)
    wire rs1_read = i_id_vld && (i_rs1_raddr != 5'd0);
    wire rs2_read = i_id_vld && (i_rs2_raddr != 5'd0);
    
    // Detect RAW hazards for RS1
    wire ex_rs1_hazard  = rs1_read && i_ex_rd_wen  && (i_rs1_raddr == i_ex_rd_waddr);
    wire mem_rs1_hazard = rs1_read && i_mem_rd_wen && (i_rs1_raddr == i_mem_rd_waddr);
    
    // Detect RAW hazards for RS2
    wire ex_rs2_hazard  = rs2_read && i_ex_rd_wen  && (i_rs2_raddr == i_ex_rd_waddr);
    wire mem_rs2_hazard = rs2_read && i_mem_rd_wen && (i_rs2_raddr == i_mem_rd_waddr);
    
    // Load-use hazard: instruction in EX is a load, and current instruction needs that result
    // Must stall for 1 cycle - cannot forward load data until MEM stage
    wire load_use_hazard = i_ex_mem_read && (ex_rs1_hazard || ex_rs2_hazard);
    
    // Stall signals - stall on load-use hazard
    assign o_if_id_halt = load_use_hazard;  // Stall fetch (hold PC and IF/ID register)
    assign o_id_ex_halt = load_use_hazard;  // Insert bubble in EX stage
    
    // Forwarding logic
    // Priority: EX stage (most recent) > MEM stage
    // Only forward if not stalling
    
    // Forward op1
    assign o_frwd_alu_op1 = !load_use_hazard && ex_rs1_hazard;
    assign o_frwd_mem_op1 = !load_use_hazard && !ex_rs1_hazard && mem_rs1_hazard;
    
    // Forward op2
    assign o_frwd_alu_op2 = !load_use_hazard && ex_rs2_hazard;
    assign o_frwd_mem_op2 = !load_use_hazard && !ex_rs2_hazard && mem_rs2_hazard;

endmodule