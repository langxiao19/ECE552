module hart_tb ();
    // Synchronous active-high reset.
    reg         clk, rst;
    // Instruction memory interface.
    reg  [31:0] imem_rdata, dmem_rdata;
    wire [31:0] imem_raddr, dmem_addr;
    // Data memory interface.
    wire        dmem_ren, dmem_wen;
    wire [31:0] dmem_wdata;
    wire [ 3:0] dmem_mask;

    // Instruction retire interface.
    wire        valid, trap, halt;
    wire [31:0] inst;
    wire [ 4:0] rs1_raddr, rs2_raddr;
    wire [31:0] rs1_rdata, rs2_rdata;
    wire [ 4:0] rd_waddr;
    wire [31:0] rd_wdata;
    wire [31:0] pc, next_pc;
    wire [31:0] retire_dmem_addr;
    wire        retire_dmem_ren, retire_dmem_wen;
    wire [ 3:0] retire_dmem_mask;
    wire [31:0] retire_dmem_rdata;
    wire [31:0] retire_dmem_wdata;

    hart #(
        .RESET_ADDR (32'h0)
    ) dut (
        .i_clk        (clk),
        .i_rst        (rst),
        .o_imem_raddr (imem_raddr),
        .i_imem_rdata (imem_rdata),
        .o_dmem_addr  (dmem_addr),
        .o_dmem_ren   (dmem_ren),
        .o_dmem_wen   (dmem_wen),
        .o_dmem_wdata (dmem_wdata),
        .o_dmem_mask  (dmem_mask),
        .i_dmem_rdata (dmem_rdata),
        .o_retire_valid     (valid),
        .o_retire_inst      (inst),
        .o_retire_trap      (trap),
        .o_retire_halt      (halt),
        .o_retire_rs1_raddr (rs1_raddr),
        .o_retire_rs1_rdata (rs1_rdata),
        .o_retire_rs2_raddr (rs2_raddr),
        .o_retire_rs2_rdata (rs2_rdata),
        .o_retire_rd_waddr  (rd_waddr),
        .o_retire_rd_wdata  (rd_wdata),
        .o_retire_dmem_addr (retire_dmem_addr),
        .o_retire_dmem_ren  (retire_dmem_ren),
        .o_retire_dmem_wen  (retire_dmem_wen),
        .o_retire_dmem_mask (retire_dmem_mask),
        .o_retire_dmem_wdata(retire_dmem_wdata),
        .o_retire_dmem_rdata(retire_dmem_rdata),
        .o_retire_pc        (pc),
        .o_retire_next_pc   (next_pc)
    );

    // The tesbench uses separate instruction and data memory banks.
    reg [7:0] imem [0:1023];
    reg [7:0] dmem [0:1023];

    // Utility: sanitize X/Z for nicer prints
    function [31:0] clean32;
        input [31:0] v;
        begin
            if (^v === 1'bx)
                clean32 = 32'h00000000;
            else
                clean32 = v;
        end
    endfunction

    function [4:0] clean5;
        input [4:0] v;
        begin
            if (^v === 1'bx)
                clean5 = 5'd0;
            else
                clean5 = v;
        end
    endfunction

    // Instruction memory read.
    always @(posedge clk) begin
        imem_rdata <= {imem[imem_raddr + 3], imem[imem_raddr + 2], imem[imem_raddr + 1], imem[imem_raddr + 0]};
    end

    // Data memory read. Masks are ignored since it is always safe
    // to access the full bytes in this memory.
    always @(posedge clk) begin
        if (dmem_ren)
            dmem_rdata <= {dmem[dmem_addr + 3], dmem[dmem_addr + 2], dmem[dmem_addr + 1], dmem[dmem_addr + 0]};
        else
            dmem_rdata <= 32'h0;
    end

    // Synchronous data memory write. Masks must be respected.
    // The byte order is little-endian.
    always @(posedge clk) begin
        if (dmem_wen & dmem_mask[0])
            dmem[dmem_addr + 0] <= dmem_wdata[ 7: 0];
        if (dmem_wen & dmem_mask[1])
            dmem[dmem_addr + 1] <= dmem_wdata[15: 8];
        if (dmem_wen & dmem_mask[2])
            dmem[dmem_addr + 2] <= dmem_wdata[23:16];
        if (dmem_wen & dmem_mask[3])
            dmem[dmem_addr + 3] <= dmem_wdata[31:24];
    end

    integer cycles, run;
    integer num_instructions;
    integer i;
    integer dbg_cycles;
    initial begin
        clk = 1;
        rst = 0;
        // Initialize read data regs to zero to avoid X on first cycles
        imem_rdata = 32'h00000000;
        dmem_rdata = 32'h00000000;

        // Open the waveform file.
        $dumpfile("hart.vcd");
        $dumpvars(0, hart_tb);

    // Clear instruction and data memories to zero to avoid X when reading unused locations.
        for (i = 0; i < 1024; i = i + 1) begin
            imem[i] = 8'h00;
            dmem[i] = 8'h00;
        end

        // Load the test program into memory at address 0.
        $display("Loading program.");
        $readmemh("program.mem", imem);
        // Peek first 16 bytes to confirm load
        $write("IMEM[0..15]: ");
        for (i = 0; i < 16; i = i + 1) begin
            $write("%02h ", imem[i]);
        end
        $display("");

        // Reset the dut.
        $display("Resetting hart.");
        @(negedge clk); rst = 1;
        @(negedge clk); rst = 0;

        $display("Cycle  PC        Inst     rs1            rs2            [rd, load, store]");
        dbg_cycles = 0;
        cycles = 0;
        run = 1;
        num_instructions = 0;
        while (run) begin
            @(posedge clk);
            cycles = cycles + 1;
            // Short-lived IF debug: show imem address and data for first 12 cycles
            if (dbg_cycles < 12) begin
                $display("IFDBG c%0d: raddr=%08h rdata=%08h", dbg_cycles, imem_raddr, imem_rdata);
                dbg_cycles = dbg_cycles + 1;
            end

            if (valid) begin
                num_instructions = num_instructions + 1;

                // Base information for all instructions.
                if (inst[3:0] == 4'b0111 || inst[6:0] == 7'b111_0011 || inst[6:0] == 7'b110_1111)
                    $write("[%08h] %08h r[xx]=xxxxxxxx r[xx]=xxxxxxxx", clean32(pc), clean32(inst));
                else if (inst[6:0] == 7'b001_0011 || inst[6:0] == 7'b000_0011 ||
                          inst[6:0] == 7'b110_0111)
                    $write("[%08h] %08h r[%0d]=%08h r[xx]=xxxxxxxx", clean32(pc), clean32(inst), clean5(rs1_raddr), clean32(rs1_rdata));
                else
                    $write("[%08h] %08h r[%0d]=%08h r[%0d]=%08h", clean32(pc), clean32(inst), clean5(rs1_raddr), clean32(rs1_rdata), clean5(rs2_raddr), clean32(rs2_rdata));

                // Only display write information for instructions that write.
                if (rd_waddr != 5'd0)
                    $write(" w[%0d]=%08h", clean5(rd_waddr), clean32(rd_wdata));
                // Only display memory information for load/store instructions.
                if (retire_dmem_ren)
                    $write(" l[%08h,%04b]=%08h", clean32(retire_dmem_addr), retire_dmem_mask, clean32(retire_dmem_rdata));
                if (retire_dmem_wen)
                    $write(" s[%08h,%04b]=%08h", clean32(retire_dmem_addr), retire_dmem_mask, clean32(retire_dmem_wdata));
                // Display trap information if a trap occurred.
                if (trap)
                    $write(" TRAP");
                $display();

                if (halt)
                    run = 0;
            end

            if (cycles > 40000) begin
                $display("Program did not halt after 10000 cycles, aborting.");
                run = 0;
            end
        end

        $display("Program halted after %d cycles.", cycles);
        $display("Total instructions retired: %d", num_instructions);
        if (num_instructions == 0)
            $display("CPI: invalid (no instructions retired)");
        else
            $display("CPI: %f", cycles / (1.0 * num_instructions));
        $finish;
    end

    always
        #5 clk = ~clk;
endmodule
