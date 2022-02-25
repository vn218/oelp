
// Uses Newton_Raphson Method
// I_WIDTH, F_WIDTH ----> N_in and D_in (Q32.0 to Q4.28)
// OUT_I_WIDTH, OUT_F_WIDTH ------> out (Q28.4 to Q4.28)
//I_WIDTH + F_WIDTH = OUT_I_WIDTH + OUT_F_WIDTH = 32


module divider
  #(parameter I_WIDTH = 16,
              F_WIDTH = 16,
              OUT_I_WIDTH = 4,
              OUT_F_WIDTH = 28)  
(
  input signed [I_WIDTH+F_WIDTH-1:0] N_in, D_in,
  input clk, rst, in_valid,
  output reg ready, out_valid,
  output reg signed [I_WIDTH+F_WIDTH-1:0] out
);
  
  parameter IDLE = 0,
            SHIFT = 1,
            ITERATE = 2,
            DONE = 3;
  
  localparam A = 32'h2_D2D2D2D,
             B = 32'h1_E1E1E1E;
  
  localparam iter = 4;
  
  reg [$clog2(I_WIDTH+F_WIDTH)-1:0] shift_counter;
  reg [$clog2(iter)-1:0] iter_counter;
  
  
  reg signed [I_WIDTH+F_WIDTH-1:0] N, D, X;
  wire signed [OUT_I_WIDTH+2*OUT_F_WIDTH-1:0] inter_1, feedback;
  wire signed [I_WIDTH+F_WIDTH-1:0] X_in, inter_2;
  reg signed [3*OUT_I_WIDTH+3*OUT_F_WIDTH-1:0] out_in , out_in_shift_1, out_in_shift_2;
  
  reg [1:0] state;
  reg negative;
  
  assign X_in = X + feedback[OUT_I_WIDTH+2*OUT_F_WIDTH-1 -: I_WIDTH+F_WIDTH];
  assign inter_1 = D*X;
  assign inter_2 = {{OUT_I_WIDTH-4{1'b0}},4'b1,{OUT_F_WIDTH{1'b0}}}  -inter_1[OUT_I_WIDTH+2*OUT_F_WIDTH-1 -: OUT_I_WIDTH+OUT_F_WIDTH];
  assign feedback = inter_2*X;
  
  always @ (*) begin
    
    out_in = X_in*N;
    
    if (OUT_F_WIDTH > F_WIDTH) begin
      out_in_shift_1 = out_in<<<(OUT_F_WIDTH-F_WIDTH);
    end
    else begin
      out_in_shift_1 = out_in>>>(F_WIDTH-OUT_F_WIDTH);
    end
    
    if (shift_counter <= I_WIDTH)
      out_in_shift_2 <= out_in_shift_1 >>> (I_WIDTH - shift_counter);
    else
      out_in_shift_2 <= out_in_shift_1 <<< (shift_counter - I_WIDTH);
  end
  
  always @ (posedge clk) begin
    case (state)
    IDLE : begin
      if (in_valid) begin
      	N <= N_in;
        if (D_in < 0) begin
          negative <= 1;
           D <= -D_in;
        end
        else begin
           negative <= 0;
           D <= D_in;
        end
        shift_counter <= 0;
        iter_counter <= 0;
      end
    end
    SHIFT : begin
      if ( D[I_WIDTH+F_WIDTH-1] == 1) begin
        D <= {{OUT_I_WIDTH{1'b0}},D[I_WIDTH+F_WIDTH-1 -: OUT_F_WIDTH]};
        X <=  {{OUT_I_WIDTH-4{1'b0}},A[I_WIDTH+F_WIDTH-1 -: 4+OUT_F_WIDTH]} - {{OUT_I_WIDTH-4{1'b0}},B[I_WIDTH+F_WIDTH-1 -: 4+(OUT_F_WIDTH)/2]}*{{OUT_I_WIDTH{1'b0}},D[I_WIDTH+F_WIDTH-1 -: OUT_F_WIDTH/2]};        
      end
      else begin
      	D <= D<<1;
        shift_counter <= shift_counter + 1;
      end
    end
    ITERATE : begin
      X <= X_in;
      if (negative)
        out <= -out_in_shift_2[OUT_I_WIDTH+2*OUT_F_WIDTH-1 -: I_WIDTH+F_WIDTH];
      else
        out <= out_in_shift_2[OUT_I_WIDTH+2*OUT_F_WIDTH-1 -: I_WIDTH+F_WIDTH];
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
