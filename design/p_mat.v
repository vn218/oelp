`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2022 18:28:04
// Design Name: 
// Module Name: p_mat
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


module p_mat
  #(
    parameter SPECTRAL_BANDS = 103,
    I_WIDTH = 4,
    F_WIDTH = 28,
    IN_I_WIDTH = 16,
    IN_F_WIDTH = 16)
  (
    input clk, rst,
    input in_valid,
    input [I_WIDTH+F_WIDTH-1:0] in_pixel,
    input [$clog2(SPECTRAL_BANDS)-1:0] row_1, row_2, col_1, col_2,
    input wr_en_1, wr_en_2,
    //input mode,  // 1 if mult and norm
    input [I_WIDTH+F_WIDTH-1:0] in_1, in_2,
    output [I_WIDTH+F_WIDTH-1:0] out_1, out_2,
    input [1:0] state,
    output mac_valid,
    input mac_rst,
    output [I_WIDTH+F_WIDTH-1:0] prod
    //input [$clog2(SPECTRAL_BANDS)-1:0] col_ctr
  );
  
  localparam IDLE = 0, 
  MULT = 1,
  NORM = 2;
  
//  reg state;
  
  wire [I_WIDTH+F_WIDTH-1:0] row_out_1 [SPECTRAL_BANDS-1:0];
  wire [I_WIDTH+F_WIDTH-1:0] row_out_2 [SPECTRAL_BANDS-1:0];
  reg rows_wr_en_1 [SPECTRAL_BANDS-1:0];
  reg rows_wr_en_2 [SPECTRAL_BANDS-1:0];
  reg [$clog2(SPECTRAL_BANDS)-1:0] addr_1, addr_2;
  
  wire [I_WIDTH+F_WIDTH-1:0] mac_out [SPECTRAL_BANDS-1:0];
  reg [I_WIDTH+F_WIDTH-1:0] product [SPECTRAL_BANDS-1:0];
  wire mac_out_valid [SPECTRAL_BANDS-1:0];
  
  reg [$clog2(SPECTRAL_BANDS)-1:0] delayed_row_1, delayed_row_2;
  
  assign mac_valid = mac_out_valid[0];
  assign prod = product[0];
//  wire mac_rst;
  
/*  wire [I_WIDTH+F_WIDTH-1:0] norm_mac_out;
  wire norm_mac_out_valid ;
  wire norm_mac_rst;*/
  
/*  reg [I_WIDTH+F_WIDTH-1:0] delayed_in_pixel;
  reg delayed_in_valid;*/
  
/*  reg [$clog2(SPECTRAL_BANDS)-1:0] mac_ctr;
  reg [$clog2(SPECTRAL_BANDS)-1:0] col_ctr;*/
  
  
   assign out_1 = row_out_1[delayed_row_1];  // to make sure that out doesnt change combinationally with row
   assign out_2 = row_out_2[delayed_row_2];
   
   always @ (posedge clk) begin
        delayed_row_1 <= row_1;
        delayed_row_2 <= row_2;     
   end
   

  
  genvar i;
  integer j;
  
  for (i = 0 ; i < SPECTRAL_BANDS ; i = i + 1) begin
    
    memory
    #(.SIZE(SPECTRAL_BANDS),
      .WIDTH(I_WIDTH+F_WIDTH))
    rows
       
    (
      .pixel_in1(in_1),
      .pixel_in2(in_2),
      .pixel_out1(row_out_1[i]),
      .pixel_out2(row_out_2[i]),
      .enable1(1'b1),
      .wr_enable1(rows_wr_en_1[i]),
      .enable2(1'b1),
      .wr_enable2(rows_wr_en_2[i]),
      .addr1(addr_1),
      .addr2(addr_2),
      .clk(clk)
    );
    
    mac_fixed
    #(.F_WIDTH(14),
      .I_WIDTH(16),
      .F_WIDTH_2(16),
      .I_WIDTH_2(16),
      .F_WIDTH_3(16),
      .I_WIDTH_3(16)
     )
    mac
    (
      .in_1(in_pixel),
      .in_2(row_out_2[i]),
      .mac_reset(mac_rst),
      .in_valid(in_valid),
      .mode(0),
      .out_valid(mac_out_valid[i]),
      .out(mac_out[i]),
      .clk(clk), 
      .rst(rst)
      );
  
  
  end
  
/*  always @ (posedge clk) begin
    
    if (rst) begin
      mac_ctr <= 0;
    end
    else begin
      if (mac_out_valid[0]) begin
        if (mac_ctr == SPECTRAL_BANDS-1 ) begin
          mac_ctr <= 0;
        end
        else begin
          mac_ctr <= mac_ctr + 1;
        end
      end  
    end 
  end*/
  
/*  always @ (posedge clk) begin
    
    if (rst) begin
      col_ctr <= 0;
    end
    else begin
      if (in_valid) begin
        if (col_ctr == SPECTRAL_BANDS-1 ) begin
          col_ctr <= 0;
        end
        else begin
          col_ctr <= col_ctr + 1;
        end
      end  
    end 
  end*/
  

  always @ (posedge clk) begin
      case (state)
        MULT : begin
          for (j = 0 ; j < SPECTRAL_BANDS ; j = j + 1) begin
            product[j] <= mac_out[j];
          end
        end
        NORM : begin
          for (j = SPECTRAL_BANDS-1 ; j > 0 ; j = j - 1) begin
            product[j-1] <= product[j];
          end
        end
      endcase
  end
  
  always @ (*) begin
    addr_1 = col_1;       
    addr_2 = col_2; 
/*    if (state == MULT)
        addr_2 = col_ctr; 
*/
    
    
    for (j = 0 ; j < SPECTRAL_BANDS ; j = j + 1) begin
        rows_wr_en_1[j] = 0;
        rows_wr_en_2[j] = 0;
    end
    
    rows_wr_en_1[row_1] = wr_en_1;
    rows_wr_en_2[row_2] = wr_en_2;
  end
  
  
/*    mac_fixed
  #(.F_WIDTH(0),
    .I_WIDTH(32),
    .F_WIDTH_2(16),
    .I_WIDTH_2(16),
    .F_WIDTH_3(16),
    .I_WIDTH_3(16)
   )
  norm_mac
  (
    .in_1(product[SPECTRAL_BANDS-1]),
    .in_2(product[SPECTRAL_BANDS-1]),
    .mac_reset(norm_mac_rst),
    .in_valid(norm_mac_in_valid),
    .mode(3'b0),
    .out_valid(norm_mac_out_valid),
    .out(norm_mac_out),
    .clk(clk), 
    .rst(rst)
    );*/
  



endmodule

