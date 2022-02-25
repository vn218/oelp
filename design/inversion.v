// Code your design here


module inversion 
#( parameter F_WIDTH = 16,
  			 I_WIDTH = 16,
  			 SPECTRAL_BANDS = 103,
             TOTAL_ENDMEMBERS = 20,
             MAC_F_WIDTH_1 = 8,
             MAC_I_WIDTH_1 = 24  //in_data is right shifted by MAC_I_WIDTH_1 - I_WIDTH before further calculations 
  )
 (
  input [I_WIDTH-1:0] U_in,
  input [I_WIDTH-1:0] new_vectorT_in,

  // in_data = new_vectorT * U
  output reg [$clog2(TOTAL_ENDMEMBERS)-1:0] U_col,
  output reg [$clog2(SPECTRAL_BANDS)-1:0] U_row,
  output [$clog2(TOTAL_ENDMEMBERS)-1:0] new_vectorT_row,
  output reg [$clog2(SPECTRAL_BANDS)-1:0] new_vectorT_col,

  output reg addr_valid_out,
  input valid_in,

  output reg [I_WIDTH+F_WIDTH-1:0] inverse,
  input [$clog2(TOTAL_ENDMEMBERS*TOTAL_ENDMEMBERS)-1:0] inv_addr_in,
  output [$clog2(TOTAL_ENDMEMBERS*TOTAL_ENDMEMBERS)-1:0] inv_addr_out,
  input [$clog2(TOTAL_ENDMEMBERS)-1:0] size,
  output reg inv_out_valid,
  output reg done,
  input start,
  input clk,rst
 ); 
  
  
  localparam IDLE = 3'b000,
  			 READ = 3'b001,
             CHOL_1 = 3'b010,
             CHOL_SQRT = 3'b011,
             CHOL_DIV = 3'b100, 
             INV = 3'b101,
             DONE = 3'b110;
  
  reg [2:0] state;
  assign done = (state == DONE);
  
  reg [F_WIDTH+I_WIDTH-1:0] in_data [TOTAL_ENDMEMBERS-1:0];  
  reg [$clog2(TOTAL_ENDMEMBERS)-1:0] in_data_ptr;
 
  
  reg [F_WIDTH+I_WIDTH-1:0] L [(((TOTAL_ENDMEMBERS)*(TOTAL_ENDMEMBERS+1))>>1)-1:0];
  reg [$clog2(((TOTAL_ENDMEMBERS)*(TOTAL_ENDMEMBERS+1))>>1)-1:0] L_addr_1, L_addr_2, L_addr_3, L_addr_4;
  wire [$clog2(TOTAL_ENDMEMBERS)-1:0] L_row_1, L_col_1, L_row_2, L_col_2, L_row_3, L_col_3, L_row_4, L_col_4;
  reg [$clog2(TOTAL_ENDMEMBERS)-1:0] chol_ctr_r, chol_ctr_w;  // k, j

  
  assign L_addr_1 = (((L_row_1)*(L_row_1+1))>>1) + L_col_1; // read   L(j,k)
  assign L_addr_2 = (((L_row_2)*(L_row_2+1))>>1) + L_col_2; // read   L(i,k)
  assign L_addr_3 = (((L_row_3)*(L_row_3+1))>>1) + L_col_3; // write  L(i,j)
  assign L_addr_4 = (((L_row_4)*(L_row_4+1))>>1) + L_col_4; // read  L(j,j)
  
  assign L_row_1 = chol_ctr_w;   
  assign L_col_1 = chol_ctr_r;   
  assign L_row_2 = size;         
  assign L_col_2 = chol_ctr_r;
  assign L_row_3 = size;
  assign L_col_3 = chol_ctr_w;
  assign L_row_4 = chol_ctr_w;
  assign L_col_4 = chol_ctr_w;
  
  
  
  wire [I_WIDTH+F_WIDTH-1:0] U, new_vectorT;
  
  // widths of U and new_vectorT should match with I_WIDTH and F_WIDTH parameters of mac
  assign U = {{MAC_I_WIDTH_1-I_WIDTH{1'b0}},U_in,{MAC_F_WIDTH_1{1'b0}}};
  assign new_vectorT = {{MAC_I_WIDTH_1-I_WIDTH{1'b0}},new_vectorT_in,{MAC_F_WIDTH_1{1'b0}}};
  
  assign new_vectorT_row = size;
  
  reg [I_WIDTH+F_WIDTH-1:0] mac_in_1;
  reg [I_WIDTH+F_WIDTH-1:0] mac_in_2;
  reg [I_WIDTH+F_WIDTH-1:0] mac_out;
  wire mac_out_valid;
  reg mac_rst, mac_in_valid, mac_in_valid_in;
  reg [$clog2(SPECTRAL_BANDS)-1:0] mac_ctr;
  reg [2:0] mac_mode;
   
  reg [F_WIDTH+I_WIDTH-1:0] temp;

  
  wire [I_WIDTH+F_WIDTH-1:0] divider_n, divider_d, divider_out;
  reg divider_in_valid;
  wire divider_out_valid;
  assign divider_n = temp;
  assign divider_d = L[L_addr_4];
  
  
  wire [I_WIDTH+F_WIDTH-1:0] sqrt_n, sqrt_out;
  reg sqrt_in_valid;
  wire sqrt_out_valid, sqrt_ready;
  assign sqrt_n = temp;
  
  
  
  always @ (posedge clk) begin
    if (rst) begin
      U_col <= 0;
      U_row <= 0;
      new_vectorT_col <= 0;
      in_data_ptr <= 0;
      mac_ctr <= 0;
      chol_ctr_r <= 0;
      chol_ctr_w <= 0;
    end
    else begin
      case (state) 
        
        READ : begin
          if (addr_valid_out) begin
            if (U_row == SPECTRAL_BANDS - 1) begin
              U_row <= 0;
              if (U_col == size) begin
                U_col <= 0;
              end
              else begin
                U_col <= U_col + 1;
              end
            end
            else begin
              U_row <= U_row + 1;
            end

            if (new_vectorT_col == SPECTRAL_BANDS - 1) begin
              new_vectorT_col <= 0;
            end
            else begin
              new_vectorT_col <= new_vectorT_col + 1;
            end
          end
        
          
          if (mac_out_valid) begin
            if (mac_ctr == SPECTRAL_BANDS-1) begin
              in_data[in_data_ptr] <= mac_out;
              mac_ctr <= 0;
              if (size == 0)
                temp <= mac_out;
              else
                temp <= in_data[0];
              if (in_data_ptr == size) begin
                in_data_ptr <= 0;
              end
              else begin
                in_data_ptr <= in_data_ptr + 1;
              end
            end
            else begin
              mac_ctr <= mac_ctr + 1;
            end         
          end  
        end
        CHOL_1 : begin
          if (mac_in_valid) begin
            if (chol_ctr_r == chol_ctr_w - 1) begin
              chol_ctr_r <= 0;
            end
            else begin
              chol_ctr_r = chol_ctr_r + 1;
            end
          end
          if (mac_out_valid) begin
            if (mac_ctr == chol_ctr_w - 1) begin
              mac_ctr <= 0;
              temp <= in_data[chol_ctr_w] - mac_out;
            end
            else begin
              mac_ctr <= mac_ctr + 1;
            end
          end
        end
        CHOL_SQRT : begin
          
          if (sqrt_out_valid) begin
            L[L_addr_3] <= sqrt_out;
            chol_ctr_w <= 0;
          end
        
        end
        
        CHOL_DIV : begin
          
          if (divider_out_valid) begin
            L[L_addr_3] <= divider_out;
            chol_ctr_w <= chol_ctr_w + 1;
          end

        end
      
      
      endcase
    end
  
  end
  
  always @ (posedge clk) begin
    if (rst) begin
      addr_valid_out <= 0;
      mac_in_valid_in <= 0;
      divider_in_valid <= 0;
      sqrt_in_valid <= 0;
    end
    else begin
      case (state) 
        
        IDLE: begin
          
          if (start)
            addr_valid_out <= 1;
        
        end
        
        READ : begin
          
          
          if (addr_valid_out)
            if (U_row == SPECTRAL_BANDS - 1)
              if (U_col == size) 
                addr_valid_out <= 0;
        
          
          if (mac_out_valid) 
            if (mac_ctr == SPECTRAL_BANDS-1)
              if (in_data_ptr == size) 
                if (size == 0)
                  sqrt_in_valid <= 1;
                else
                  divider_in_valid <= 1;

        end
        
        CHOL_1 : begin
          if (mac_in_valid)
            if (chol_ctr_r == chol_ctr_w - 1)
              mac_in_valid_in <= 0;

          if (mac_out_valid) 
            if (mac_ctr == chol_ctr_w - 1) 
              if (chol_ctr_w == size)
                sqrt_in_valid <= 1;
              else
                divider_in_valid <= 1;              
        end
        
        CHOL_SQRT : begin
          sqrt_in_valid <= 0;
          
          if (sqrt_out_valid)
            mac_in_valid_in <= 0;
        
        end
        
        CHOL_DIV : begin
          divider_in_valid <= 0;
          
          if (divider_out_valid)
            mac_in_valid_in <= 1;
          
        end
        
      endcase
    end
  
  end
  
  always @ (posedge clk) begin
    if (rst) begin
      state <= IDLE;
    end
    else begin
      case (state)  
        IDLE: begin      
          
          if (start)
            state <= READ;
        
        end    
        
        READ : begin

          if (mac_out_valid) 
            if (mac_ctr == SPECTRAL_BANDS-1)
              if (in_data_ptr == size) 
                if (size == 0)
                  state <= CHOL_SQRT;
                else
                  state <= CHOL_DIV;

        end
        
        CHOL_1 : begin

          if (mac_out_valid) 
            if (mac_ctr == chol_ctr_w - 1) 
              if (chol_ctr_w == size)
                state <= CHOL_SQRT;
              else
                state <= CHOL_DIV;              
        end
        
        CHOL_SQRT : begin
          
          if (sqrt_out_valid)
            state <= DONE;
        
        end
        
        CHOL_DIV : begin
          
          if (divider_out_valid)
            state <= CHOL_1;
          
        end
        
        DONE : begin
          
          state <= IDLE;
          
        end
        
      endcase
    end
  
  end
  
  always @ (*) begin
    mac_in_valid = mac_in_valid_in;
    case (state) 
      IDLE: begin
        mac_rst = 1;
        mac_in_valid = 0;
      end
      READ : begin
        mac_rst = (mac_out_valid & (mac_ctr == SPECTRAL_BANDS-1));
        mac_in_1 = U;
        mac_in_2 = new_vectorT;
        mac_mode = 3'b000;
        mac_in_valid = valid_in;
      end
      CHOL_1 : begin
        mac_rst = (mac_out_valid & (mac_ctr == chol_ctr_w - 1));
        mac_in_1 = L[L_addr_1];
        mac_in_2 = L[L_addr_2];
        mac_mode = 3'b001;
      end
    endcase
  
  end
  
  
  mac_inv
  #(.F_WIDTH(MAC_F_WIDTH_1),
    .I_WIDTH(MAC_I_WIDTH_1),
    .F_WIDTH_2(16),
    .I_WIDTH_2(16),
    .F_WIDTH_3(28),
    .I_WIDTH_3(4)
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
 
  divider
  #(.I_WIDTH(16),
    .F_WIDTH(16),
    .OUT_I_WIDTH(16),
    .OUT_F_WIDTH(16)
  )  
  divider
  (
    .N_in(divider_n), 
    .D_in(divider_d),
    .clk(clk), 
    .rst(rst), 
    .in_valid(divider_in_valid),
    .ready(), 
    .out_valid(divider_out_valid),
    .out(divider_out)
);
  
  sqrt
  #(.I_WIDTH(16),
    .F_WIDTH(16)
  )  
  sqrt
  (
    .N_in(sqrt_n), 
    .clk(clk), 
    .rst(rst), 
    .in_valid(sqrt_in_valid),
    .ready(), 
    .out_valid(sqrt_out_valid),
    .out(sqrt_out)
);
  
  
  
endmodule

module mac_inv
  #(parameter F_WIDTH = 0,
              I_WIDTH = 32,
              F_WIDTH_2 = 16,
              I_WIDTH_2 = 16,
              F_WIDTH_3 = 16,
              I_WIDTH_3 = 16
  )
 (
  input signed [I_WIDTH+F_WIDTH-1:0] in_1,
  input signed [I_WIDTH+F_WIDTH-1:0] in_2,
  input mac_reset,
  input in_valid,
  input [2:0] mode,
  output reg out_valid,
  output reg signed [I_WIDTH+F_WIDTH-1:0] out,
  input clk, rst
      );
  
  wire signed [2*I_WIDTH+2*F_WIDTH-1:0] product;
  reg signed [I_WIDTH+F_WIDTH-1:0] out_in;
  
  assign product = in_1*in_2;
  
  always @ (*) begin
    if (in_valid) begin
      case (mode)
        3'b000 : begin
          out_in = product[I_WIDTH + 2*F_WIDTH - 1 -: I_WIDTH + F_WIDTH];
        end
        3'b001 : begin
          out_in = product[I_WIDTH_2 + 2*F_WIDTH_2 - 1 -: I_WIDTH_2 + F_WIDTH_2];
        end
        3'b010 : begin
          out_in = product[I_WIDTH_3 + 2*F_WIDTH_3 - 1 -: I_WIDTH_3 + F_WIDTH_3];
        end      

      endcase
    end
    else begin
      out_in = 0;
    end
    
  end
  
  
  always @ (posedge clk) begin
    if (rst ) begin
      out <= 0;
      out_valid <= 0;
    end
    else if (mac_reset) begin
      out <= out_in;       
    end
    else begin
      out <= out_in + out; 
    end
    out_valid <= in_valid;
  end      
endmodule
