/**
*   Fetch Block of Pipeline
*/

module fet
(
    // Global clock.
    input  wire         i_clk,
    // Synchronous active-high reset.
    input  wire         i_rst,

    /* Control Signals for Program Counter */
    // Branching
    input wire          i_eq,           // OP1 and OP2 Equal
    input wire          i_slt,          // OP1 < OP2
    input wire [2:0]    i_opsel,        // Branch opsel
    input wire          i_branch,       // Current Instruction is branch
    // Valid for execute-stage branch signals
    input wire          i_ex_vld,

    // Asserts if we want to load a specific address into the pc (jump)
    input wire          i_jal,
    input wire          i_jalr,
    // Valid for decode-stage jump/immediate/rs1 signals
    input wire          i_de_vld,
    // Asserts if processor needs to halt
    input wire          i_halt,
    input wire          i_hold,

    /* Address Signals */
    // Immediate value used for Branch and Jump
    input wire  [31:0]  i_immediate,
    //RS1 input for jalr instruction
    input wire  [31:0]  i_rs1,
    // Next instruction address to execute
    output wire [31:0]  o_imem_raddr,
    // Instruction read from memory
    input wire  [31:0]  i_imem_rdata,
    output wire [31:0]  o_inst,
    // Next PC value to send to control unit to determine if trap needed
    output wire [31:0]  o_pc,
    output wire [31:0]  o_nxt_pc,
    // Instruction Valid
    output wire         o_vld,
    // Flush signal (branch/jump taken)
    output wire         o_flush
);
    // Internal Signals
    wire        [31:0]  nxt_pc;
    wire                flush;

    // Register Holding
    reg [31:0]  inst_ff;
    reg [31:0]  nxt_pc_ff;
    reg [31:0]  pc_ff;
    reg [31:0]  raddr_prev_ff;   // Holds previous cycle's address to align with registered IMEM
    reg [31:0]  nxt_pc_prev_ff;  // Holds previous cycle's next PC to align with instruction
    reg         flush_ff;
    reg         vld_ff;
    reg         first_fetch_ff;  // Track if we need to wait one cycle after reset

    // Program Counter
    // Sanitize/gate control inputs with valid signals to prevent X propagation into PC
    // Use case-equality (===) so that X/ Z are treated as not-asserted and do not propagate Xs
    wire        eq_safe      = (i_ex_vld === 1'b1) ? i_eq        : 1'b0;
    wire        slt_safe     = (i_ex_vld === 1'b1) ? i_slt       : 1'b0;
    wire [2:0]  opsel_safe   = (i_ex_vld === 1'b1) ? i_opsel     : 3'b000;
    wire        branch_safe  = (i_ex_vld === 1'b1) ? i_branch    : 1'b0;
    wire        jal_safe     = (i_de_vld === 1'b1) ? i_jal       : 1'b0;
    wire        jalr_safe    = (i_de_vld === 1'b1) ? i_jalr      : 1'b0;
    wire [31:0] imm_safe     = (i_de_vld === 1'b1) ? i_immediate : 32'h0000_0000;
    wire [31:0] rs1_safe     = (i_de_vld === 1'b1) ? i_rs1       : 32'h0000_0000;

    pc   pc(  .i_clk(i_clk), 
                .i_rst(i_rst),
                .i_eq(eq_safe),
                .i_slt(slt_safe),
                .i_opsel(opsel_safe),
                .i_branch(branch_safe),
                .i_jal(jal_safe),
                .i_jalr(jalr_safe),
                .i_halt(i_halt | i_hold), 
                .i_immediate(imm_safe),
                .i_rs1(rs1_safe),
                .o_imem_raddr(o_imem_raddr),
                .o_nxt_pc(nxt_pc),
                .o_flush(flush));

    // IF/ID register
    always @(posedge i_clk) begin
        if (i_rst | flush) begin
            //on reset or flush load add x0 and x0 to x0
            inst_ff        <= 32'h00000033;
            vld_ff         <= 1'b0;
            first_fetch_ff <= 1'b1;  // Need to wait one cycle after reset for imem
            pc_ff          <= 32'h00000000;
            nxt_pc_ff      <= 32'h00000000;
            raddr_prev_ff  <= 32'h00000000;
            nxt_pc_prev_ff <= 32'h00000000;
            flush_ff       <= 1'b0;
        end
        else if (!i_hold) begin
            // Align PC/instruction with registered IMEM (1-cycle latency)
            inst_ff        <= i_imem_rdata;
            pc_ff          <= raddr_prev_ff;
            nxt_pc_ff      <= nxt_pc_prev_ff;
            // Update previous-cycle trackers for next cycle
            raddr_prev_ff  <= o_imem_raddr;
            nxt_pc_prev_ff <= nxt_pc;
            flush_ff       <= flush;
            // Only set valid after first fetch completes (imem has 1-cycle latency)
            vld_ff         <= !first_fetch_ff;
            first_fetch_ff <= 1'b0;
        end
        // Implied else hold value
    end

    // Assign output wires to registers
    assign o_inst   = inst_ff;
    assign o_vld    = vld_ff;
    assign o_nxt_pc = nxt_pc_ff;
    assign o_pc     = pc_ff;
    assign o_flush  = flush_ff;

endmodule