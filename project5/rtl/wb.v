/**
*   Write Back Stage
*/

module wb
(
    input wire          i_rst,
    input wire          i_mem_reg,
    input wire [31:0]   i_dmem_rdata,
    input wire [31:0]   i_res,
    input wire [4:0]    i_rd_waddr,
    input wire          i_rd_wen,
    input wire          i_vld,
    input wire [31:0]   i_inst,
    input wire [4:0]    i_rs1_raddr,
    input wire [4:0]    i_rs2_raddr,
    input wire [31:0]   i_rs1_rdata,
    input wire [31:0]   i_rs2_rdata,
    input wire [31:0]   i_dmem_addr,
    input wire [3:0]    i_dmem_mask,
    input wire          i_dmem_ren,
    input wire          i_dmem_wen,
    input wire [31:0]   i_dmem_wdata,
    input wire [31:0]   i_pc,
    input wire [31:0]   i_nxt_pc,

    output wire [31:0]  o_res,
    output wire [4:0]   o_rd_waddr,
    output wire         o_rd_wen,
    output wire         o_vld,
    output wire [31:0]  o_inst,
    output wire [4:0]   o_rs1_raddr,
    output wire [4:0]   o_rs2_raddr,
    output wire [31:0]  o_rs1_rdata,
    output wire [31:0]  o_rs2_rdata,
    output wire [31:0]  o_dmem_addr,
    output wire [3:0]   o_dmem_mask,
    output wire         o_dmem_ren,
    output wire         o_dmem_wen,
    output wire [31:0]  o_dmem_rdata,
    output wire [31:0]  o_dmem_wdata,
    output wire [31:0]  o_pc,
    output wire [31:0]  o_nxt_pc
);

// For loads, perform the appropriate sign/zero extension based on funct3.
wire [2:0] wb_funct3 = i_inst[14:12];
wire [31:0] load_ext = (wb_funct3 == 3'b000) ? {{24{i_dmem_rdata[7]}},   i_dmem_rdata[7:0]}   : // LB
                       (wb_funct3 == 3'b001) ? {{16{i_dmem_rdata[15]}},  i_dmem_rdata[15:0]}  : // LH
                       (wb_funct3 == 3'b010) ? i_dmem_rdata                                   : // LW
                       (wb_funct3 == 3'b100) ? {24'b0,                  i_dmem_rdata[7:0]}   : // LBU
                       (wb_funct3 == 3'b101) ? {16'b0,                  i_dmem_rdata[15:0]}  : // LHU
                                                i_dmem_rdata;

// Need to determine if we want to use ALU result or memory output
assign o_res        =   (i_mem_reg) ?   load_ext : i_res;
assign o_rd_waddr   =   i_rd_waddr;
assign o_rd_wen     =   i_rd_wen;
assign o_vld        =   (i_rst)     ?   1'b0         : i_vld;
assign o_inst          = i_inst;
assign o_rs1_raddr     = i_rs1_raddr;
assign o_rs2_raddr     = i_rs2_raddr;
assign o_rs1_rdata     = i_rs1_rdata;
assign o_rs2_rdata     = i_rs2_rdata;
assign o_dmem_addr     = i_dmem_addr;
assign o_dmem_mask     = i_dmem_mask;
assign o_dmem_wen      = i_dmem_wen;
assign o_dmem_ren      = i_dmem_ren;
assign o_dmem_rdata    = i_dmem_rdata;
assign o_dmem_wdata    = i_dmem_wdata;
assign o_pc            = i_pc;
assign o_nxt_pc        = i_nxt_pc;

endmodule
