`timescale 1ns / 1ps
// 64-bit IEEE-754 Double Precision Floating Point Multiplier
// ASIC-friendly version with sequential registers and enable signal

module Multiplication (
  input enable,              // clock, reset, enable for power gating
  input [63:0] a_operand, b_operand,     // IEEE-754 double precision inputs
  output reg Exception, Overflow, Underflow,
  output reg [63:0] result
);

  // Internal signals
  wire sign = a_operand[63] ^ b_operand[63];
  wire [10:0] exp_a = a_operand[62:52];
  wire [10:0] exp_b = b_operand[62:52];
  wire [51:0] mant_a = a_operand[51:0];
  wire [51:0] mant_b = b_operand[51:0];

  // Hidden bit handling
  wire [52:0] op_a = (|exp_a) ? {1'b1, mant_a} : {1'b0, mant_a};
  wire [52:0] op_b = (|exp_b) ? {1'b1, mant_b} : {1'b0, mant_b};

  // 106-bit product
  wire [105:0] product = op_a * op_b;
  wire normalised = product[105];

  // Normalization
  wire [105:0] norm_product = normalised ? product : product << 1;

  // Mantissa rounding (keep 52 bits)
  wire [51:0] mant_final = norm_product[104:53] + norm_product[52];

  // Exponent adjustment
 wire [11:0] exp_sum = exp_a + exp_b + normalised;
  
  // Exceptions
  wire exc = (&exp_a) | (&exp_b);
  wire ovf = (exp_sum > 12'd3070); // 2046 + 1024
  wire unf = (exp_sum < 12'd1023); // below bias ? underflow

  wire [11:0] exp_result = exp_sum - 12'd1023;

  // Sequential output (for timing + ASIC sync)
  always @(*) begin
  
    if (enable) begin
      Exception = exc;
      Underflow = unf;
      Overflow  = ovf;
      result = exc ? 64'd0 :
                ovf ? {sign, 11'h7FF, 52'd0} :
                unf ? {sign, 63'd0} :
      {sign, exp_result[10:0], mant_final};
    end
  end
endmodule
