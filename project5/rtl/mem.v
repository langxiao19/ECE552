/**
*   Memory Stage
*/

module mem
(
    // Global clock
    input wire          i_clk,
    input wire          i_rst,
    input wire          i_vld,
    input wire [31:0]   i_inst,
    input wire [4:0]    i_rs1_raddr,
    input wire [4:0]    i_rs2_raddr,
    input wire [31:0]   i_rs1_rdata,
    input wire [31:0]   i_rs2_rdata,
    input wire [31:0]   i_pc,
    input wire [31:0]   i_nxt_pc,

    input wire [2:0]    i_opsel_w, //opsel arrives at different times if read or write
    input wire [2:0]    i_opsel_r,
    input wire [31:0]   i_dmem_addr,
    input wire [31:0]   i_dmem_wdata,
    input wire [31:0]   i_dmem_rdata,
    input wire          i_dmem_ren,
    input wire          i_dmem_wen,
    input wire          i_dmem_ren_ff,
    input wire          i_dmem_wen_ff,
    input wire          i_mem_reg,
    input wire [31:0]   i_res,
    input wire [4:0]    i_rd_waddr,
    input wire          i_rd_wen,

    output wire         o_mem_reg,
    output wire [31:0]  o_res,
    output wire [4:0]   o_rd_waddr,
    output wire         o_rd_wen,
    output wire [31:0]  o_dmem_rdata,


    output wire [31:0]  o_dmem_addr,
    output wire [31:0]  o_dmem_wdata,
    output wire [3:0]   o_dmem_mask,
    output wire         o_dmem_wen,
    output wire         o_dmem_ren,
    output wire         o_vld,
    output wire [31:0]  o_inst,
    output wire [4:0]   o_rs1_raddr,
    output wire [4:0]   o_rs2_raddr,
    output wire [31:0]  o_rs1_rdata,
    output wire [31:0]  o_rs2_rdata,
    output wire [31:0]  o_dmem_addr_ff,
    output wire [3:0]   o_dmem_mask_ff,
    output wire         o_dmem_ren_ff,
    output wire         o_dmem_wen_ff,
    output wire [31:0]  o_dmem_wdata_ff,
    output wire [31:0]  o_dmem_rdata_ff,
    output wire [31:0]  o_pc,
    output wire [31:0]  o_nxt_pc
);
    // Register Signals
    reg          mem_reg_ff;
    reg [31:0]   res_ff;
    reg [4:0]    rd_waddr_ff;
    reg          rd_wen_ff;
    reg          vld_ff;
    reg [31:0]   inst_ff;
    reg [4:0]    rs1_raddr_ff;
    reg [4:0]    rs2_raddr_ff;
    reg [31:0]   rs1_rdata_ff;
    reg [31:0]   rs2_rdata_ff;
    reg [31:0]   dmem_addr_ff;
    reg [3:0]    dmem_mask_ff;
    reg [31:0]   dmem_addr_ff1;
    reg [3:0]    dmem_mask_ff1;
    reg          dmem_ren_ff;
    reg          dmem_wen_ff;
    reg [31:0]   dmem_wdata_ff;
    reg [31:0]   dmem_wdata_ff1;
    reg [31:0]   dmem_rdata_ff;
    reg [31:0]   pc_ff;
    reg [31:0]   nxt_pc_ff;

    // Memory handler (determines mask and aligns accesses)
    wire [2:0]   opsel;
    dmem dmem(.i_opsel(opsel),
                .i_dmem_addr(i_dmem_addr),
                .i_rs2_rdata(i_dmem_wdata),
                .i_dmem_rdata(i_dmem_rdata),
                .o_dmem_addr(o_dmem_addr),
                .o_dmem_wdata(o_dmem_wdata),  // Write data is synchronous, so doesn't need pipeline
                .o_dmem_rdata(o_dmem_rdata),
                .o_dmem_mask(o_dmem_mask));
    // Drive memory interface enables from current decode-stage controls (design choice),
    // but ensure retire/logging uses the correctly pipelined mask below.
    assign o_dmem_wen = i_dmem_wen;
    assign o_dmem_ren = i_dmem_ren;
    // Select opsel for combinational dmem based on whether this cycle is a write or read request
    // Note: retire/logging will use the pipelined mask/value aligned to MEM stage.
    assign opsel      = (o_dmem_wen) ? i_opsel_w : i_opsel_r;

    // MEM/WB Register
    always @(posedge i_clk) begin
        // Only need reset for vld
        if (i_rst) begin
            vld_ff      <= 1'b0;
            rd_wen_ff   <= 1'b0;
            rd_waddr_ff <= 5'd0;
            res_ff      <= 32'd0;
            mem_reg_ff  <= 1'b0;
        end
        else begin
            mem_reg_ff       <= i_mem_reg;
            res_ff           <= i_res;
            rd_waddr_ff      <= i_rd_waddr;
            rd_wen_ff        <= i_rd_wen;
            vld_ff           <= i_vld;
            inst_ff          <= i_inst;
            rs1_raddr_ff     <= i_rs1_raddr;
            rs2_raddr_ff     <= i_rs2_raddr;
            rs1_rdata_ff     <= i_rs1_rdata;
            rs2_rdata_ff     <= i_rs2_rdata;
            dmem_addr_ff     <= o_dmem_addr;
            dmem_mask_ff     <= o_dmem_mask;
            // Pipeline the address/mask to align with the instruction in MEM/WB stage
            dmem_addr_ff1    <= dmem_addr_ff;
            // Always use the previously computed mask for retire/logging to avoid
            // mixing with the next EX-stage instruction's mask.
            dmem_mask_ff1    <= dmem_mask_ff;
            dmem_ren_ff      <= i_dmem_ren_ff;
            dmem_wen_ff      <= i_dmem_wen_ff;
            dmem_wdata_ff    <= o_dmem_wdata;
            dmem_wdata_ff1   <= dmem_wdata_ff;
            // Compute raw (right-shifted to LSB) zero-extended read data for retire/logging.
            // Use the pipelined mask from the previous cycle to select the correct bytes.
            // This raw value will be sign/zero-extended for register writeback in WB.
            dmem_rdata_ff    <= (dmem_mask_ff == 4'b0001) ? {24'b0, i_dmem_rdata[7:0]}   :
                               (dmem_mask_ff == 4'b0010) ? {24'b0, i_dmem_rdata[15:8]}  :
                               (dmem_mask_ff == 4'b0100) ? {24'b0, i_dmem_rdata[23:16]} :
                               (dmem_mask_ff == 4'b1000) ? {24'b0, i_dmem_rdata[31:24]} :
                               (dmem_mask_ff == 4'b0011) ? {16'b0, i_dmem_rdata[15:0]}  :
                               (dmem_mask_ff == 4'b1100) ? {16'b0, i_dmem_rdata[31:16]} :
                                                            i_dmem_rdata;
            pc_ff            <= i_pc;
            nxt_pc_ff        <= i_nxt_pc;
        end
    end

    // Assign Registers to wires
    assign o_mem_reg       = mem_reg_ff;
    assign o_res           = res_ff;
    assign o_rd_waddr      = rd_waddr_ff;
    assign o_rd_wen        = rd_wen_ff;
    assign o_vld           = vld_ff;
    assign o_inst          = inst_ff;
    assign o_rs1_raddr     = rs1_raddr_ff;
    assign o_rs2_raddr     = rs2_raddr_ff;
    assign o_rs1_rdata     = rs1_rdata_ff;
    assign o_rs2_rdata     = rs2_rdata_ff;
    assign o_dmem_addr_ff  = dmem_addr_ff1;
    assign o_dmem_mask_ff  = dmem_mask_ff1;
    assign o_dmem_ren_ff   = dmem_ren_ff;
    assign o_dmem_wen_ff   = dmem_wen_ff;
    assign o_dmem_wdata_ff = dmem_wdata_ff1;
    assign o_dmem_rdata_ff = dmem_rdata_ff;
    assign o_pc            = pc_ff;
    assign o_nxt_pc        = nxt_pc_ff;

endmodule
