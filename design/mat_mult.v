`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2022 18:44:14
// Design Name: 
// Module Name: mat_mult
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


module mat_mult 
  #(parameter I_WIDTH = 16,
   F_WIDTH = 16,
   SPECTRAL_BANDS = 103)
  (
    input clk, rst, start,
    input [$clog2(SPECTRAL_BANDS)-1:0] mat1_dims_rows, mat1_dims_cols, mat2_dims_cols,
    input mat1_valid, mat2_valid,
    input [I_WIDTH+F_WIDTH-1:0] mat1, mat2,
    input [2:0] mac_mode,
    output reg rd_addr_valid,
    output [$clog2(SPECTRAL_BANDS)-1:0] mat1_row, mat1_col, mat2_row, mat2_col, out_row, out_col,
    output out_valid,
    output [I_WIDTH+F_WIDTH-1:0] out,
    output done
  );
  
  localparam IDLE = 0,
  BUSY = 1,
  DONE = 2;
  
  reg [1:0] state;
  
  reg [$clog2(SPECTRAL_BANDS)-1:0] r_ctr, w_ctr1, w_ctr2, delayed_r_ctr, delayed_w_ctr1, delayed_w_ctr2;
  
  wire [I_WIDTH+F_WIDTH-1:0] mac_in_1, mac_in_2, mac_out;
  wire mac_in_valid, mac_out_valid, mac_rst;
  
  assign mac_in_valid = mat1_valid & mat2_valid;
  assign mac_in_1 = mat1;
  assign mac_in_2 = mat2;
  assign out = mac_out;
  assign mac_rst = (delayed_r_ctr == mat1_dims_cols) & mac_out_valid;
  assign out_valid = mac_rst;
  
  assign mat1_row = w_ctr1;
  assign mat1_col = r_ctr;
  
  assign mat2_row = r_ctr;
  assign mat2_col = w_ctr2;
  
  assign out_row = delayed_w_ctr1;
  assign out_col = delayed_w_ctr2;
  
  assign done = state == DONE;
  
  
  
  always @ (posedge clk) begin
    
    if (rst) begin
      r_ctr <= 0;
      w_ctr1 <= 0;
      w_ctr2 <= 0;
      delayed_r_ctr <= 0;
      delayed_w_ctr1 <= 0;
      delayed_w_ctr2 <= 0;
    end
    else begin
      
      
      
      if (rd_addr_valid) begin
        if (r_ctr == mat1_dims_cols) begin
          r_ctr <= 0;
          if (w_ctr2 == mat2_dims_cols) begin
            w_ctr2 <= 0;
            if (w_ctr1 == mat1_dims_rows) begin
              w_ctr1 <= 0;
            end
            else begin
              w_ctr1 <= w_ctr1 + 1;
            end
          end
          else begin
            w_ctr2 <= w_ctr2 + 1;
          end
        end
        else begin
          r_ctr <= r_ctr + 1;
        end      
      end    
    end
    
    if (mac_out_valid) begin
      if (delayed_r_ctr == mat1_dims_cols) begin
          delayed_r_ctr <= 0;
        if (delayed_w_ctr2 == mat2_dims_cols) begin
            delayed_w_ctr2 <= 0;
          if (delayed_w_ctr1 == mat1_dims_rows) begin
              delayed_w_ctr1 <= 0;
          end
          else begin
              delayed_w_ctr1 <= delayed_w_ctr1 + 1;
          end
        end
        else begin
            delayed_w_ctr2 <= delayed_w_ctr2 + 1;
        end
      end
      else begin
          delayed_r_ctr <= delayed_r_ctr + 1;
      end      
    end    
    
  
  end
  
  always @ (posedge clk) begin
    if (rst) begin
      state <= IDLE;
      rd_addr_valid <= 0;
    end
    else begin
      
      case (state)
        IDLE : begin
          if (start) begin
            state <= BUSY;
            rd_addr_valid <= 1;
          end       
        end
        BUSY : begin
          if (mac_out_valid & r_ctr == mat1_dims_cols & w_ctr2 == mat2_dims_cols & w_ctr1 == mat1_dims_rows) begin
            rd_addr_valid <= 0;
          end
          
          if (mac_out_valid & delayed_r_ctr == mat1_dims_cols & delayed_w_ctr2 == mat2_dims_cols & delayed_w_ctr1 == mat1_dims_rows) begin
            state <= DONE;
          end
         
        end
        DONE : state <= IDLE;
      
      endcase
    
    end
  
  
  end
  
    mac_fixed
  #(.F_WIDTH(14), // (IN1_F_WIDTH + IN2_F_WIDTH)/2
    .I_WIDTH(4),  // OUT_I_WIDTH
    .F_WIDTH_2(14),
    .I_WIDTH_2(16),
    .F_WIDTH_3(16),
    .I_WIDTH_3(24)
  )
  mac 
  (
    .in_1(mac_in_1),
    .in_2(mac_in_2),
    .mac_reset(mac_rst),
    .in_valid(mac_in_valid),
    .mode(mac_mode),
    .out_valid(mac_out_valid),
    .out(mac_out),
    .clk(clk), 
    .rst(rst)
      );
  
  


endmodule
