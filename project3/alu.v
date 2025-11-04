`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it in phase 3.
module alu (
    // Major operation selection.
    // NOTE: In order to simplify instruction decoding in phase 4, both 3'b010
    // and 3'b011 are used for set less than (they are equivalent).
    // Unsigned comparison is controlled through the `i_unsigned` signal.
    //
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [ 2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is only used for branch comparisons and set less than.
    // For branch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b011` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out (from addition) should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used downstream to determine if a
    // branch should be taken.
    output wire        o_eq,
    // Set less than result. This is used downstream to determine if a
    // branch should be taken.
    output wire        o_slt
);
    wire [31:0] add_sub_result;
    wire [31:0] sll_result;
    wire [31:0] slt_result;
    wire [31:0] xor_result;
    wire [31:0] srl_sra_result;
    wire [31:0] or_result;
    wire [31:0] and_result;
    
    wire [31:0] op2_add_sub;
    wire [4:0] shift_amount;
    
    assign op2_add_sub = i_sub ? (~i_op2 + 1) : i_op2;
    assign add_sub_result = i_op1 + op2_add_sub;
    
    assign shift_amount = i_op2[4:0];
    assign sll_result = i_op1 << shift_amount;
    
    wire slt_signed, slt_unsigned;
    assign slt_signed = $signed(i_op1) < $signed(i_op2);
    assign slt_unsigned = i_op1 < i_op2;
    assign slt_result = {31'b0, i_unsigned ? slt_unsigned : slt_signed};
    
    assign xor_result = i_op1 ^ i_op2;
    
    wire [31:0] srl_result, sra_result;
    assign srl_result = i_op1 >> shift_amount;
    assign sra_result = $signed(i_op1) >>> shift_amount;
    assign srl_sra_result = i_arith ? sra_result : srl_result;
    
    assign or_result = i_op1 | i_op2;
    assign and_result = i_op1 & i_op2;
    
    assign o_result = (i_opsel == 3'b000) ? add_sub_result :
                      (i_opsel == 3'b001) ? sll_result :
                      (i_opsel == 3'b010 || i_opsel == 3'b011) ? slt_result :
                      (i_opsel == 3'b100) ? xor_result :
                      (i_opsel == 3'b101) ? srl_sra_result :
                      (i_opsel == 3'b110) ? or_result :
                      (i_opsel == 3'b111) ? and_result :
                      32'b0;
    
    assign o_eq = (i_op1 == i_op2);
    assign o_slt = i_unsigned ? slt_unsigned : slt_signed;

endmodule

`default_nettype wire
