## Author: Your Langlang Xiao
##
## You may implement the following with any of the instructions in the RV32I instruction set
## and described in the reference sheet. Do not use any of the mul[h][s][u] instructions which
## are *not* described in the reference sheet. Remember to respect the calling convention - if
## you choose to use any of the callee saved registers s[0-11], remember to save them to the
## stack before reusing them (note, you should not need to do this but are free to do so).
##
## [Description]
## Multiplies two 32-bit *unsigned* numbers and provides a 32-bit *unsigned* result
## consisting of the lower 32 bits of the product.
##
## [Arguments]
## a0 = multiplicand
## a1 = multiplier
##
## [Returns]
## a0 = 32-bit product
    .text
    .globl umul
umul:
    # This dummy code adds the two operands and returns the result.
    # Replace with your implementation.
    addi t0, zero, 0      # result = 0
    addi t1, zero, 32     # loop counter = 32

mul_loop:
    andi t2, a1, 1        # if the lsb is 1
    beq  t2, zero, skip   # if 0 we skip to the next round of multiplication
    add  t0, t0, a0       # if its 1 then we add it to result

skip:
    slli a0, a0, 1        # multiplicand left shift to go up in base2, most significant
                          # bit is lost, but its ok since we only want the lowest 32 bits
    srli a1, a1, 1        # multiplier right shift to get the next bit to the lsb position
                          # previous lsb is lost
    addi t1, t1, -1       # decrement counter
    bnez t1, mul_loop     # keep looping and multiple for all 32 bits

    add a0, t0, 0         # add our cumulated result to a0
    jalr zero, 0(ra)      # return
