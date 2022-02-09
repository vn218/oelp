//Square root by Babylonian Method, not tested tho, just found out about this recently
//A combinational way to calculate square root
module sqrt #(parameter WIDTH = 16) (
  input [WIDTH-1:0] in, 
  output reg [WIDTH-1:0] out
);
  //https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
  wire [WIDTH-1:0] temp1, temp3, temp5;
  reg [WIDTH-1:0] temp2, temp4;
  assign temp1 = in/out;
  assign temp3 = in/temp2;
  assign temp5 = in/temp4;

  always @ (in) begin
    out = {{8{1'b0}},{8{1'b1}}};

    temp2 = (out + temp1) >> 1;
    temp4 = (temp2 + temp3) >> 1;
    out = (temp4 + temp5) >> 1;
  end 
endmodule
