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
