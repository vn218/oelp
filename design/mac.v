`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.02.2022 22:59:49
// Design Name: 
// Module Name: mac
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


module mac
#(parameter WIDTH = 36)
(
input [WIDTH-1:0] in_1,
input [WIDTH-1:0] in_2,
input [3:0] state,
input mac_reset,
input in_valid,
output reg out_valid,
output reg [WIDTH-1:0] out,
input clk, rst
    );

reg [WIDTH-1:0] product;
reg product_valid;    

always @ (posedge clk) begin
    if (rst ) begin
        out <= 0;
    end
    else begin
        if ( in_valid ) begin
            product <= in_1 * in_2;
        end
        if (product_valid) begin
            out <= product + out;
        end
        if ( mac_reset ) begin
            out <= 0;
        end
        product_valid <= in_valid;
        out_valid <= product_valid;    
    end
end      
endmodule
