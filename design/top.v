`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.02.2022 17:34:21
// Design Name: 
// Module Name: top
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


module top
#(parameter SPECTRAL_BANDS = 100,
    IN_WIDTH = 16,
    T_WIDTH = 32,
    MAC_WIDTH = 32,
    TOTAL_PIXELS = 100000,
    TOTAL_ENDMEMBERS = 20
)
(
input [IN_WIDTH-1:0] pixel_in,
input in_axi_valid,
input in_axi_ready,
output [IN_WIDTH-1:0] pixel_out,
output out_axi_valid,
output out_axi_ready,
output intr,
output finish,
input clk,
input rst
    );
    

wire [MAC_WIDTH-1:0] mac_input_1;
wire [MAC_WIDTH-1:0] mac_input_2;
wire mac_reset;
wire mac_input_valid;
wire [3:0] state;
wire [MAC_WIDTH-1:0] mac_output;
wire mac_output_valid;
wire [2:0] mac_mode;

wire [IN_WIDTH-1:0] inv_U;
wire [IN_WIDTH-1:0] inv_new_vectorT;
wire [$clog2(TOTAL_ENDMEMBERS)-1:0] inv_U_col;
wire [$clog2(SPECTRAL_BANDS)-1:0] inv_U_row;
wire [$clog2(TOTAL_ENDMEMBERS)-1:0] inv_new_vectorT_row;
wire [$clog2(SPECTRAL_BANDS)-1:0] inv_new_vectorT_col;
wire inv_addr_valid_inv_to_ctrl;
wire inv_valid_ctrl_to_inv;
wire [T_WIDTH-1:0] inverse;
wire [$clog2(TOTAL_ENDMEMBERS)-1:0] inv_row, inv_col;
wire inv_addr_valid_ctrl_to_inv;
wire [$clog2(TOTAL_ENDMEMBERS)-1:0] inv_size;
wire inv_out_valid;
wire inv_done;
wire inv_start;


wire mat_mult_start;
wire [$clog2(SPECTRAL_BANDS)-1:0] mat1_dims_rows, mat1_dims_cols, mat2_dims_cols;
wire mat1_valid, mat2_valid;
wire [T_WIDTH-1:0] mat1, mat2;
wire [2:0] mat_mult_mac_mode;
wire mat_mult_rd_addr_valid;
wire [$clog2(SPECTRAL_BANDS)-1:0] mat1_row, mat1_col, mat2_row, mat2_col, mat_mult_out_row, mat_mult_out_col;
wire mat_mult_out_valid;
wire [T_WIDTH-1:0] mat_mult_out;
wire mat_mult_done;

control_logic
#(.SPECTRAL_BANDS(SPECTRAL_BANDS),
  .IN_WIDTH(IN_WIDTH),
  .MAC_WIDTH(MAC_WIDTH),
  .TOTAL_PIXELS(TOTAL_PIXELS),
  .TOTAL_ENDMEMBERS(TOTAL_ENDMEMBERS)
)
control_logic
(
.pixel_in(pixel_in),
.in_axi_valid(in_axi_valid),
.in_axi_ready(in_axi_ready),
.pixel_out(pixel_out),
.out_axi_valid(out_axi_valid),
.out_axi_ready(out_axi_ready),
.intr(intr),
.mac_out_1(mac_input_1),
.mac_out_2(mac_input_2),
.mac_reset(mac_reset),
.mac_mode(mac_mode),
.mac_valid_out(mac_input_valid),
.state(state),
.finish(finish),
.mac_in(mac_output),
.mac_valid_in(mac_output_valid),
.clk(clk),
.rst(rst),
.inv_U(inv_U),
.inv_new_vectorT(inv_new_vectorT),
.inv_U_col(inv_U_col),
.inv_U_row(inv_U_row),
.inv_new_vectorT_row(inv_new_vectorT_row),
.inv_new_vectorT_col(inv_new_vectorT_col),
.inv_addr_valid_in(inv_addr_valid_inv_to_ctrl),
.inv_valid_out(inv_valid_ctrl_to_inv),
.inverse(inverse),
.inv_row(inv_row), 
.inv_col(inv_col),
.inv_addr_valid_out(inv_addr_valid_ctrl_to_inv),
.inv_size(inv_size),
.inv_out_valid(inv_out_valid),
.inv_done(inv_done),
.inv_start(inv_start),

.mat_mult_start(mat_mult_start),
.mat1_dims_rows(mat1_dims_rows), 
.mat1_dims_cols(mat1_dims_cols),
.mat2_dims_cols(mat2_dims_cols),
.mat1_valid(mat1_valid), 
.mat2_valid(mat2_valid),
.mat1(mat1), 
.mat2(mat2),
.mat_mult_mac_mode(mat_mult_mac_mode),
.mat_mult_rd_addr_valid(mat_mult_rd_addr_valid),
.mat1_row(mat1_row), 
.mat1_col(mat1_col), 
.mat2_row(mat2_row), 
.mat2_col(mat2_col), 
.mat_mult_out_row(mat_mult_out_row), 
.mat_mult_out_col(mat_mult_out_col),
.mat_mult_out_valid(mat_mult_out_valid),
.mat_mult_out(mat_mult_out),
.mat_mult_done(mat_mult_done)
    );

/*mac
#(.IN_WIDTH(MAC_WIDTH))
mac
(
.in_1(mac_input_1),
.in_2(mac_input_2),
.state(state),
.mac_reset(mac_reset),
.in_valid(mac_input_valid),
.out_valid(mac_output_valid),
.out(mac_output),
.clk(clk), 
.rst(rst) 
    );*/
    
    
mac_fixed
#(.F_WIDTH(0),
  .I_WIDTH(32),
  .F_WIDTH_2(16),
  .I_WIDTH_2(32),
  .F_WIDTH_3(8),   
  .I_WIDTH_3(32)
)
mac
(
  .in_1(mac_input_1),
  .in_2(mac_input_2),
  .mac_reset(mac_reset),
  .in_valid(mac_input_valid),
  .mode(mac_mode),
  .out_valid(mac_output_valid),
  .out(mac_output),
  .clk(clk), 
  .rst(rst)
 );
      
    
inversion 
#(.F_WIDTH(16),
  .I_WIDTH(16),
  .SPECTRAL_BANDS(SPECTRAL_BANDS),
  .TOTAL_ENDMEMBERS(TOTAL_ENDMEMBERS),
  .MAC_F_WIDTH_1(0),
  .MAC_I_WIDTH_1(32)  //in_data is right shifted by MAC_I_WIDTH_1 - I_WIDTH before further calculations  ///// scaling 
  )
 inversion
 (
  .U_in(inv_U),
  .new_vectorT_in(inv_new_vectorT),

  // in_data = new_vectorT * U
  .U_col(inv_U_col),
  .U_row(inv_U_row),
  .new_vectorT_row(inv_new_vectorT_row),
  .new_vectorT_col(inv_new_vectorT_col),

  .addr_valid_out(inv_addr_valid_inv_to_ctrl),
  .valid_in(inv_valid_ctrl_to_inv),

  .inverse(inverse),
  .inv_row_in(inv_row), 
  .inv_col_in(inv_col),
  .inv_addr_valid_in(inv_addr_valid_ctrl_to_inv),
  //output [$clog2(TOTAL_ENDMEMBERS*TOTAL_ENDMEMBERS)-1:0] inv_addr_out,
  .size(inv_size),
  .inv_out_valid(inv_out_valid),
  .done(inv_done),
  .start(inv_start),
  .clk(clk),
  .rst(rst)
 );
 
 mat_mult 
 #(.I_WIDTH(IN_WIDTH),
   .F_WIDTH(T_WIDTH-IN_WIDTH),
   .SPECTRAL_BANDS(SPECTRAL_BANDS))
  mat_mult 
 (
   .clk(clk), 
   .rst(rst), 
   .start(mat_mult_start),
   .mat1_dims_rows(mat1_dims_rows), 
   .mat1_dims_cols(mat1_dims_cols),
   .mat2_dims_cols(mat2_dims_cols),
   .mat1_valid(mat1_valid), 
   .mat2_valid(mat2_valid),
   .mat1(mat1), 
   .mat2(mat2),
   .mac_mode(mat_mult_mac_mode),
   .rd_addr_valid(mat_mult_rd_addr_valid),
   .mat1_row(mat1_row), 
   .mat1_col(mat1_col), 
   .mat2_row(mat2_row), 
   .mat2_col(mat2_col), 
   .out_row(mat_mult_out_row), 
   .out_col(mat_mult_out_col),
   .out_valid(mat_mult_out_valid),
   .out(mat_mult_out),
   .done(mat_mult_done)
  );    
    
endmodule
