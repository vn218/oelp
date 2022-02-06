`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.12.2021 23:30:51
// Design Name: 
// Module Name: memory
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
//(* DONT_TOUCH = "true" *)
module memory
#(parameter SIZE = 1000000,
            WIDTH = 16)
(
input [WIDTH-1:0] pixel_in1,
input [WIDTH-1:0] pixel_in2,
output reg [WIDTH-1:0] pixel_out1,
output reg [WIDTH-1:0] pixel_out2,
input enable1,
input wr_enable1,
input enable2,
input wr_enable2,
input [$clog2(SIZE)-1:0] addr1,
input [$clog2(SIZE)-1:0] addr2,
input clk
    );
   
        
    reg [WIDTH-1:0] mem [SIZE-1:0];
    
    always @ (posedge clk) begin
        if (enable1)begin
            pixel_out1 <= mem[addr1];
                if (wr_enable1)
                    mem[addr1] <= pixel_in1;
        end
    end                
    
    always @ (posedge clk) begin    
        if (enable2) begin
            pixel_out2 <= mem[addr2];
                if (wr_enable2)
                    mem[addr2] <= pixel_in2;
        end            
                        
    end                 
endmodule
