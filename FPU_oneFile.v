
//--------------------------- TOP -----------------------------//


module ALU (
         
  input  wire  enable,      
  input  wire  [3:0]  Operation, // ALU operation code
  input  wire  [63:0] a_operand, // operand A
  input  wire  [63:0] b_operand, // operand B
  output reg   [63:0] ALU_Output,
  output reg   Exception,
  output reg   Overflow,
  output reg   Underflow
);

  // 1. Define operation codes using localparams (readable constants)
  localparam OP_ADD = 4'd1,  //a_operand + b_operand
             OP_SUB = 4'd2,  //a_operand - b_operand
             OP_MUL = 4'd3,  //a_operand * b_operand
             OP_DIV  = 4'd4, //a_operand / b_operand
             OP_AND = 4'd5,  //a_operand & b_operand
             OP_OR = 4'd6,   //a_operand | b_operand
             OP_XOR = 4'd7,  //a_operand ^ b_operand
             OP_NOT = 4'd8,  //~a_operand
             OP_LS = 4'd9,   //1 bit left shift on a_operand
             OP_RS = 4'd10,  //1 bit right shift on a_operand
             OP_FPI = 4'd11; //converting FP a_operand to integer

  
  // 2. Safe input driving for submodules (no 'z')
  wire  add_sub_ctrl = (Operation == OP_SUB); // 1=sub, 0=add

  // 3. Enable signals for power saving (gating heavy modules)
  wire enable_mul = (Operation == OP_MUL);
  wire enable_div = (Operation == OP_DIV);
  wire enable_addsub = (Operation == OP_ADD) || (Operation == OP_SUB);

  // 4. Submodule instantiations (with enable signals)
  wire [63:0] Add_Sub_Output, Mul_Output, Div_Output, Int_output;
  wire Add_Sub_Exception, Add_Sub_Overflow, Add_Sub_Underflow ;
  wire Mul_Exception,Mul_Overflow, Mul_Underflow;
  wire Div_Exception, Div_Overflow, Div_Underflow;

  Addition_Subtraction addsub_inst (
    .enable(enable_addsub),             
    .a_operand(a_operand),
    .b_operand(b_operand),
    .Add_or_Sub(add_sub_ctrl),
    .Result(Add_Sub_Output),
    .Exception(Add_Sub_Exception),
    .Overflow(Add_sub_Overflow),
    .Underflow(Add_sub_Underfow)  
  );

  Multiplication mul_inst (
    .enable(enable_mul),
    .a_operand(a_operand),
    .b_operand(b_operand),
    .Exception(Mul_Exception),
    .Overflow(Mul_Overflow),
    .Underflow(Mul_Underflow),
    .result(Mul_Output)
  );

Division divinst(
	.enable(enable_div),
    .a(a_operand),     
    .b(b_operand),     
    .Result(Div_Output), 
    .Exception(Div_Exception) 
);




  always @(*) begin
  
	if (enable) begin
		
    case(Operation)
		
      OP_ADD, OP_SUB: 
			begin 
				ALU_Output = Add_Sub_Output; 
				Exception = Add_Sub_Exception;
				Overflow = Add_sub_Overflow;  	
				Underflow =Add_sub_Underfow;
			end		
			
      OP_MUL: 
			begin
				ALU_Output = Mul_Output; 
				Exception = Mul_Exception;
				Overflow = Mul_Overflow; 
				Underflow = Mul_Underflow;
			end			
			
      OP_DIV: 
			begin 
				ALU_Output = Div_Output; 
				Exception = Div_Exception;
			end			
			
      OP_AND: 
            begin
			     ALU_Output = a_operand & b_operand;
			     Exception = 1'b0;
			end		
		
      OP_OR :
            begin
			     ALU_Output = a_operand | b_operand;
			     Exception = 1'b0;
			end	
						
			
      OP_XOR: 
			begin
			     ALU_Output = a_operand ^ b_operand;
			     Exception = 1'b0;
			end			
			
      OP_NOT: 
			begin
			     ALU_Output = ~a_operand;
			     Exception = 1'b0;
			end	  		
			
      OP_LS: 	
			begin
			     ALU_Output = a_operand << 1'b1;	
			     Exception = 1'b0;
			end	
			
      OP_RS: 
			begin
			     ALU_Output = a_operand >> 1'b1;	
			     Exception = 1'b0;
			end	
				
      OP_FPI: 
			begin
			     ALU_Output = Int_output;	
			     Exception = 1'b0;
			end	
					
			
      default: ALU_Output = 64'd0;
    
	endcase
  end
    
  else begin
  
		  ALU_Output = 64'd0; 
		  Exception = 1'b0; 
		  Overflow = 1'b0; 
		  Underflow = 1'b0;
  
  end
  
  end

endmodule
  //--------------------------------------------------------------------------------//
  
  
  
  
  // -------- ADDITION ----------- //
  
  
module Addition_Subtraction (
  input  wire enable,
  input  [63:0] a_operand, b_operand,
  input  Add_or_Sub,              // 0 = add, 1 = subtract
  output reg Exception,
  output Overflow,
  output Underflow,
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

// ----------------------------------------------- // 


 // --------------- MULTIPLICATION --------------- //

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

 // -------------------------------------------- //  
 
 
 
  // ----------------- DIVISION ---------------- //
  
  
module Division(
	input enable,
    input  wire [63:0] a,     
    input  wire [63:0] b,     
    output [63:0] Result,
    output Exception,
    output Overflow,
    output Underflow 
);

    reg [63:0] result;
    // Step 1: Unpack inputs 
    wire sign_a     = a[63];        
    wire [10:0] exp_a = a[62:52];    
    wire [51:0] frac_a = a[51:0];    

    wire sign_b     = b[63];         
    wire [10:0] exp_b = b[62:52];    
    wire [51:0] frac_b = b[51:0];    

    // Step 2: Special cases detection 
    wire is_zero_a = (exp_a == 0) && (frac_a == 0);
    wire is_zero_b = (exp_b == 0) && (frac_b == 0);
    wire is_inf_a  = (exp_a == 11'h7FF) && (frac_a == 0);
    wire is_inf_b  = (exp_b == 11'h7FF) && (frac_b == 0);
    wire is_nan_a  = (exp_a == 11'h7FF) && (frac_a != 0);
    wire is_nan_b  = (exp_b == 11'h7FF) && (frac_b != 0);

    // Step 3: Result sign and quiet NaN definition
    wire result_sign = sign_a ^ sign_b;                         
    wire [63:0] quiet_nan = {1'b0, 11'h7FF, 1'b1, 51'b0};       

    // Step 4: Internal registers 
    reg [10:0] exp_r;                
    reg [10:0] exp_a_int, exp_b_int; 
    reg [53:0] mant_a, mant_b;       
    reg [105:0] mant_res;            

    always @(*) begin
	
	
	if (enable) begin
	
        // Step 5: Handle special cases (IEEE 754 rules) 
        if (is_nan_a || is_nan_b) begin
            result = quiet_nan;                      // If either input is NaN → result is NaN
            
        end else if ((is_zero_a && is_zero_b) || (is_inf_a && is_inf_b)) begin
            result = quiet_nan;                      // 0/0 or Inf/Inf → NaN
            
        end else if (is_zero_b) begin
            result = {result_sign, 11'h7FF, 52'b0};  // Division by 0 → Inf
            
        end else if (is_zero_a) begin
            result = {result_sign, 63'b0};           // 0 / x → 0
        end else if (is_inf_a) begin
            result = {result_sign, 11'h7FF, 52'b0};  // Inf / x → Inf
        end else if (is_inf_b) begin
            result = {result_sign, 63'b0};           // x / Inf → 0
        end else begin
            // Step 6: Normalize mantissas
            
            mant_a = (exp_a == 0) ? {1'b0, frac_a} : {1'b1, frac_a};
            mant_b = (exp_b == 0) ? {1'b0, frac_b} : {1'b1, frac_b};

            
            exp_a_int = (exp_a == 0) ? 11'd1 : exp_a;
            exp_b_int = (exp_b == 0) ? 11'd1 : exp_b;

            
            exp_r = exp_a_int - exp_b_int + 1023;

            // Step 7: Mantissa division
            
            mant_res = (mant_a << 53) / mant_b;

            // Step 8: Normalize the result
           
            if (mant_res[53] == 0) begin
                mant_res = mant_res << 1;
                exp_r = exp_r - 1;
            end

            // Step 9: Pack final result 
        
            result = {result_sign, exp_r, mant_res[52:1]};
        end
    end
	
	else begin
	
		result=64'd0;
	
	end
	end


assign Exception = (is_zero_b || is_zero_b || is_inf_a || is_inf_b || is_nan_a || is_nan_b) ? 1'b1 : 1'b0; 
assign Result = result;                      
                                              
                                
 endmodule 
 
  // ------------------------------------------------------- //
  
  
  
    // ----------------- PRIORITY ENCODER ---------------- //  
  
  module Priority_Encoder (
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

  // ------------------------------------------------------- //
