`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2022 18:42:37
// Design Name: 
// Module Name: mac_fixed
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mac_fixed
  #(parameter F_WIDTH = 0,
              I_WIDTH = 32,
              F_WIDTH_2 = 16,
              I_WIDTH_2 = 16,
              F_WIDTH_3 = 16,
              I_WIDTH_3 = 16,
              F_WIDTH_4 = 16,
              I_WIDTH_4 = 16,
              T_WIDTH = 32
  )
 (
  input signed [T_WIDTH-1:0] in_1,
  input signed [T_WIDTH-1:0] in_2,
  input mac_reset,
  input in_valid,
  input [2:0] mode,
  output reg out_valid,
  output reg signed [T_WIDTH-1:0] out,
  input clk, rst
      );
  
  
  wire signed [2*T_WIDTH-1:0] product;
  reg signed [2*T_WIDTH-1:0] out_64;
  reg signed [2*T_WIDTH-1:0] out_in;
  
  assign product = in_1*in_2;
  
  always @ (*) begin
    case (mode)
      3'b000 : begin
        
        out = out_64[I_WIDTH + 2*F_WIDTH - 1 -: T_WIDTH];
      end
      3'b001 : begin
       
        out = out_64[I_WIDTH_2 + 2*F_WIDTH_2 - 1 -: T_WIDTH];
      end
      3'b010 : begin
        
        out = out_64[I_WIDTH_3 + 2*F_WIDTH_3 - 1 -: T_WIDTH];
      end
      3'b011 : begin
        
        out = out_64[I_WIDTH_4 + 2*F_WIDTH_4 - 1 -: T_WIDTH];
      end        

    endcase
    
    if (in_valid)
      out_in = product;  
    else begin
      out_in = 0;
    end
    
  end
  
  
  always @ (posedge clk) begin
    if (rst ) begin
      out_64 <= 0;
      out_valid <= 0;
    end
    else if (mac_reset) begin
      out_64 <= out_in;       
    end
    else begin
      out_64 <= out_in + out_64; 
    end
    out_valid <= in_valid;
  end      
endmodule
