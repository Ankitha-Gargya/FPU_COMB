`timescale 1ns / 1ps


module TB_FPU_comb;
      
  reg enable;      
  reg [3:0]  Operation; // ALU operation code
  reg [63:0] a_operand; // operand A
  reg [63:0] b_operand; // operand B
  wire [63:0] ALU_Output;
  wire Exception;
  wire Overflow;
  wire Underflow;
  
 ALU uut ( enable, Operation, a_operand, b_operand, ALU_Output, Exception, Overflow, Underflow);
 
   initial enable =1'b0;
  
  always begin
  
  
  //Addition : 15.0 + 2.5
  #10 enable = 1'b1; 
  b_operand = 64'h7FF0000000000000;
  a_operand = 64'h402E000000000000;
  Operation = 4'd1;
  
  
   //Subtraction : 15.0 + 2.5
  #10 enable = 1'b1; 
  a_operand = 64'h402E000000000000;
  b_operand = 64'h4004000000000000;
  Operation = 4'd2;
  
 
   // Multiplication     : 2.5 × 3.25 = 8.125
    #20
    a_operand = 64'h7FF0000000000000; // 2.5
    b_operand = 64'h400A000000000000; // 3.25
    Operation = 4'd3;
      
      
      
    // Test 2: 5.0 × -2.0 = -10.0                     //Division
    #20                                               // Block not working 
    a_operand = 64'h4014000000000000; // 5.0
    b_operand = 64'hC000000000000000; // -2.0
    Operation = 4'd3;
    
    
      //Division : 15.0 / 2.5
  #10 enable = 1'b1; 
  
  a_operand = 64'h402E000000000000;
  b_operand = 64'h0000000000000000;
  Operation = 4'd4;
     #20
    a_operand = 64'h4014000000000000; // 5.0
    b_operand = 64'hC000000000000000; // -2.0
    Operation = 4'd5;
    
     #20
    a_operand = 64'h4014000000000000; // 5.0
    b_operand = 64'hC000000000000000; // -2.0
    Operation = 4'd6;
    
     #20
    a_operand = 64'h4014000000000000; // 5.0
    b_operand = 64'hC000000000000000; // -2.0
    Operation = 4'd7;
    
     #20
    a_operand = 64'h4014000000000000; // 5.0
    b_operand = 64'hC000000000000000; // -2.0
    Operation = 4'd8;
    
    
  
  #150 $stop;
  end
  



endmodule
