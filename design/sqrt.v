module sqrt
  #( parameter I_WIDTH = 16,
               F_WIDTH = 16)
  (input [I_WIDTH+F_WIDTH-1:0] N_in,
   output reg [I_WIDTH+F_WIDTH-1:0] out,
   input clk, rst, in_valid,
   output reg out_valid, ready
  );
  
  parameter IDLE = 0,
            ITERATE = 1,
            DONE = 2;
  
  reg [1:0] state;
  reg [I_WIDTH+F_WIDTH-1:0] X;
  wire [I_WIDTH+2*F_WIDTH-1:0] X_in;
  wire [I_WIDTH+2*F_WIDTH-1:0] X2;
  
  reg [I_WIDTH+F_WIDTH-1:0] N;
  
  wire [I_WIDTH+2*F_WIDTH-1:0] NX2; 
  wire [I_WIDTH+F_WIDTH-1:0] R;
  reg [I_WIDTH+F_WIDTH-1:0] R_old;
  
  reg [I_WIDTH+F_WIDTH-1:0] approx;
  wire [I_WIDTH+2*F_WIDTH-1:0] out_in;
  
  // initial approximation of 1/sqrt(N)
  always @ (*) begin
    if (N_in > 32'h4000_0000)
      approx = 32'h0000_0100;
    
    if (N_in <= 32'h4000_0000 && N_in > 32'h1000_0000)
      approx = 32'h0000_0200;
    
    if (N_in <= 32'h1000_0000 && N_in > 32'h0400_0000)
      approx = 32'h0000_0400;
    
    if (N_in <= 32'h0400_0000 && N_in > 32'h0100_0000)
      approx = 32'h0000_0800;
    
    if (N_in <= 32'h0100_0000 && N_in > 32'h0040_0000)
      approx = 32'h0000_1000;
    
    if (N_in <= 32'h0040_0000 && N_in > 32'h0010_0000)
      approx = 32'h0000_2000;
    
    if (N_in <= 32'h0010_0000 && N_in > 32'h0004_0000)
      approx = 32'h0000_4000;
    
    if (N_in <= 32'h0004_0000 && N_in > 32'h0001_0000)
      approx = 32'h0000_8000;
    
    if (N_in <= 32'h0001_0000 && N_in > 32'h0000_4000)
      approx = 32'h0001_0000;
    
    if (N_in <= 32'h0000_4000 && N_in > 32'h000_1000)
      approx = 32'h0002_0000;
    
    if (N_in <= 32'h0000_1000 && N_in > 32'h0000_0400)
      approx = 32'h0004_0000;
    
    if (N_in <= 32'h0000_0400 && N_in > 32'h0000_0100)
      approx = 32'h0008_0000;
    
    if (N_in <= 32'h0000_0100 && N_in > 32'h0000_0040)
      approx = 32'h0010_0000;
    
    if (N_in <= 32'h0000_0040 && N_in > 32'h0000_0010)
      approx = 32'h0020_0000;
    
    if (N_in <= 32'h0000_0010 && N_in > 32'h0000_0004)
      approx = 32'h0040_0000;
    
    if (N_in <= 32'h0000_0004)
      approx = 32'h0080_0000;
    
  
  end
  

  assign X2 = X*X;
  assign NX2 = N*X2[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
  assign R = 32'h0003_0000 - NX2[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
  assign X_in = (X>>1)*R;
  
  
  assign out_in = N*X;

  
  always @ (posedge clk) begin
    case (state)
    IDLE : begin
	  N <= N_in;
      X <= approx;
      R_old <= 32'h0003_0000;
    end
    ITERATE : begin
      if (R <= R_old) begin
        X <= X_in[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
        R_old <= R;
      end
    end
    endcase
  
  end
  
  always @ (posedge clk) begin
    
    if (rst) begin
      state <= IDLE;
    end
    else begin
      case (state)
      IDLE : begin
        if (in_valid) begin
          if (N_in == 0) begin
            state <= DONE;
            out <= 0;
          end
          else
            state <= ITERATE;  
        end
      end
      ITERATE : begin     
        if (R > R_old || X_in[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH] == X)
          state <= DONE;
        out <= out_in[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
      end
      DONE : begin
        state <= IDLE;
      end
      endcase
    end
  end
    
  always @ (*) begin
    ready = 0;
    out_valid = 0;
    case (state) 
     IDLE : ready = 1;
     DONE : out_valid = 1;  
    endcase 
  end
  
endmodule
