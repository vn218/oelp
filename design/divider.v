module divider
  #(parameter I_WIDTH = 16,
   		        F_WIDTH = 16,
              OUT_I_WIDTH = 16,
              OUT_F_WIDTH = 16)  
 (
  input [I_WIDTH+F_WIDTH-1:0] N_in, D_in,
  input clk, rst, in_valid,
  output reg ready, out_valid,
  output reg [I_WIDTH+F_WIDTH-1:0] out
);
  
  parameter IDLE = 0,
  			    SHIFT = 1,
  			    ITERATE = 2,
            DONE = 3;
  
  localparam A = 32'b10_1101_0010_1101_0010,
  			     B = 32'b01_1110_0001_1110_0001;
  
  localparam iter = 4;
  
  reg [$clog2(I_WIDTH+F_WIDTH)-1:0] shift_counter;
  reg [$clog2(iter)-1:0] iter_counter;
  
  
  reg signed [I_WIDTH+F_WIDTH-1:0] N, D, X;
  wire signed [I_WIDTH+2*F_WIDTH-1:0] inter_1, feedback;
  wire signed [I_WIDTH+F_WIDTH-1:0] X_in, inter_2;
  wire signed [I_WIDTH+2*F_WIDTH-1:0] out_in;
  
  reg [1:0] state;
  
  assign X_in = X + feedback[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
  assign inter_1 = D*X;
  assign inter_2 = 32'b1_0000000000000000 -inter_1[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
  assign feedback = inter_2*X;
  assign out_in = N*X_in;
  
  always @ (posedge clk) begin
    case (state)
    IDLE : begin
      if (in_valid) begin
      	N <= N_in;
        D <= D_in;
        shift_counter <= 0;
        iter_counter <= 0;
      end
    end
    SHIFT : begin
      if ( D[I_WIDTH+F_WIDTH-1] == 1) begin
        D <= {{I_WIDTH{1'b0}},D[I_WIDTH+F_WIDTH-1 -: F_WIDTH]};
        X <=  A - B[I_WIDTH+F_WIDTH-1 -: I_WIDTH + (F_WIDTH/2)]*{{I_WIDTH{1'b0}},D[I_WIDTH+F_WIDTH-1 -: F_WIDTH/2]};
        
        if (shift_counter <= I_WIDTH)
          N <= (N >> (I_WIDTH - shift_counter));
        else
          N <= (N << (shift_counter - I_WIDTH));
      end
      else begin
      	D <= D<<1;
        shift_counter <= shift_counter + 1;
      end
    end
    ITERATE : begin
        X <= X_in;
        out <= out_in[I_WIDTH+2*F_WIDTH-1 -: I_WIDTH+F_WIDTH];
        iter_counter <= iter_counter + 1;        
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
          state <= SHIFT;
        end
      end
      SHIFT : begin
        if ( D[I_WIDTH+F_WIDTH-1] == 1) begin
          state <= ITERATE;
      	end
      end
      ITERATE : begin
        if (iter_counter == iter-1 ) begin
          state <= DONE;	
        end
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
