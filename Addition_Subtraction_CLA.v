module Addition_Subtraction_CLA (
  input  wire enable,
  input  [63:0] a_operand, b_operand,
  input  Add_or_Sub,              // 0 = add, 1 = subtract
  output reg Exception,
  output reg [63:0] Result
);

  // Extract fields
  wire sign_a = a_operand[63];
  wire sign_b = b_operand[63];
  wire [10:0] exp_a = a_operand[62:52];
  wire [10:0] exp_b = b_operand[62:52];
  wire [51:0] mant_a = a_operand[51:0];
  wire [51:0] mant_b = b_operand[51:0];

  // hidden bit restore
  wire [52:0] sig_a = (|exp_a) ? {1'b1, mant_a} : {1'b0, mant_a};
  wire [52:0] sig_b = (|exp_b) ? {1'b1, mant_b} : {1'b0, mant_b};

  // exception
  wire Exception_wire = (&exp_a) | (&exp_b);

  // exponent difference
  wire [11:0] exp_diff = (exp_a >= exp_b) ? (exp_a - exp_b) : (exp_b - exp_a);
  wire [10:0] exp_large = (exp_a >= exp_b) ? exp_a : exp_b;

  // align operands
  wire [52:0] sig_a_shifted = (exp_a >= exp_b) ? sig_a : (sig_a >> exp_diff);
  wire [52:0] sig_b_shifted = (exp_b >  exp_a) ? sig_b : (sig_b >> exp_diff);

  // -----------------------------
  // ? USE CLA FOR ADD / SUB
  // -----------------------------

  wire [53:0] A_input = {1'b0, sig_a_shifted};     // make 54 bit
  wire [53:0] B_input = (Add_or_Sub) ? {1'b0, ~sig_b_shifted}  // subtraction: invert B
                                    : {1'b0,  sig_b_shifted}; // addition

  wire Cin_input = Add_or_Sub ? 1'b1 : 1'b0;      // +1 for 2’s complement subtraction

  wire [53:0] sig_sum;
  wire sig_cout;

  // CLA adder instance
  CLA_Adder cla(
    .A(A_input),
    .B(B_input),
    .Cin(Cin_input),
    .Sum(sig_sum),
    .Cout(sig_cout)
  );

  // after addition/sub in CLA
  wire carry = sig_sum[53];

  // normalized significand
  wire [53:0] sig_final = sig_sum;

  // exponent update for add
  wire [10:0] exp_before_norm = (Add_or_Sub) ? exp_large :
                                (carry ? exp_large + 1 : exp_large);

  // sign for subtraction handling
  wire sign_final = (Add_or_Sub) ?
                     ((sig_a_shifted >= sig_b_shifted) ? sign_a : sign_b)
                     : sign_a;

  // priority encoder normalization
  wire [52:0] norm_mant;
  wire [10:0] norm_exp;

  Priority_Encoder_CLA norm(
    .Input_Mantissa(sig_final[52:0]),
    .Input_Exp(exp_before_norm),
    .Output_Mantissa(norm_mant),
    .Output_Exp(norm_exp)
  );

  //---------------------
  // OUTPUT UPDATE
  //---------------------
  always @(*) begin
    if (enable) begin
      Exception = Exception_wire;
      Result =
        (Exception_wire) ? 64'd0 :
        { sign_final, norm_exp, norm_mant[51:0] };
    end
  end

endmodule


module CLA_Adder(
  input  [53:0] A,
  input  [53:0] B,
  input         Cin,
  output [53:0] Sum,
  output        Cout
);
  wire [53:0] G = A & B;   // generate
  wire [53:0] P = A ^ B;   // propagate
  wire [54:0] C;
  assign C[0] = Cin;

  genvar i;
  generate
    for (i=0; i<54; i=i+1) begin
      assign C[i+1] = G[i] | (P[i] & C[i]);
      assign Sum[i] = P[i] ^ C[i];
    end
  endgenerate

  assign Cout = C[54];
endmodule


  
module Priority_Encoder_CLA (
  input  [52:0] Input_Mantissa,
  input  [10:0]  Input_Exp,
  output reg [52:0] Output_Mantissa,
  output reg [10:0]  Output_Exp
);

  integer i;
  reg [5:0] shift; // up to 52 shifts
  reg found;
always @(*) begin
  shift = 0;
  found = 0;
  for (i = 52; i >= 0; i = i - 1) begin
    if (!found && Input_Mantissa[i] == 1'b1) begin
      shift = 52 - i;
      found = 1;
    end
  end
  Output_Mantissa = Input_Mantissa << shift;
  Output_Exp = Input_Exp - shift;
end
endmodule
