module inversion #(parameter WIDTH = 16,SIZE = 3) (
  input clk,
  input rst,
  input ack,
  input a_valid,
  input [(WIDTH*SIZE*SIZE)-1:0] a, //Was thinking to calculate sqrt sequentially initially so thought would be better to buffer a, but now we can just stream since sqrt is combinational
  output reg [(WIDTH*SIZE*SIZE)-1:0] ia,
  output reg ia_valid
);
  
  //Inversion has three steps
  //1. Cholesky Decomposition into triangular matrices
  //2. Inversion of the triangular matrix, through an algorithm "https://math.stackexchange.com/a/1611352"
  //3. Matrix multiplication of the transpose of the inverted triangular matrix and the inverted triangular matrix
  localparam IDLE = 0, DECOMP = 1, TRIINV = 2, MULT = 3, DONE = 4;
  reg [3:0] state;
  
  reg [WIDTH-1:0] A [0:SIZE-1] [0:SIZE-1];
  reg [WIDTH-1:0] L [0:SIZE-1] [0:SIZE-1];
  reg [WIDTH-1:0] squared_Ldiag [0:SIZE-1];
  reg [WIDTH-1:0] temp_sum;
  reg [$clog2(SIZE*SIZE)-1:0] addr = 0;
  reg [$clog2(SIZE)-1:0] row_index, col_index, k;

  //For known size, you can just instantiate required sqrt modules, but tried doing this for parametrized size not sure if it works
  //https://www.chipverify.com/verilog/verilog-generate-block
  genvar iter;
  
  generate
    for (iter=0; iter<SIZE; iter=iter+1) begin
      sqrt sqrt0 (squared_Ldiag[iter], L[iter][iter]);
    end
  endgenerate

  always @ (posedge clk) begin
    if (rst) begin
      state <= IDLE;
      for (row_index=0; row_index<SIZE; row_index=row_index+1) begin
        for (col_index=0; col_index<SIZE; col_index=col_index+1) begin
          A[row_index][col_index] <= 0;
          L[row_index][col_index] <= 0;
        end
      end
    end else begin
      case (state)
        IDLE :
          ia_valid <= 0;
          if (a_valid) begin
            for (row_index=0; row_index<SIZE; row_index=row_index+1) begin
              for (col_index=0; col_index<SIZE; col_index=col_index+1) begin
                A[row_index][col_index] <= a[(WIDTH*addr)+:WIDTH];
                addr = addr + 1;
              end
            end
            state <= DECOMP;
          end
        DECOMP :
          for (row_index=0; row_index<SIZE; row_index=row_index+1) begin
            for (col_index=0; col_index<SIZE; col_index=col_index+1) begin
              for (k=0; k<SIZE; k=k+1) 
                temp_sum = temp_sum + (L[row_index][k]*L[k][col_index]);
              if (row_index==col_index)
                squared_Ldiag[row_index] = A[row_index][col_index] - temp_sum;
              else
                L[row_index][col_index] = (A[row_index][col_index] - temp_sum)/L[col_index][col_index];
            end
            if (row_index == SIZE-1)
              state <= TRIINV;
          end
        TRIINV :
          for (col_index=0; col_index<SIZE; col_index=col_index+1) begin
            L[col_index][col_index] = 1/L[col_index][col_index]
            for (row_index=col_index+1; row_index<SIZE; row_index=row_index+1) begin
              temp_product = ; //Here is the problem, according to the algorithm there should be matrix multiplication in this term, stumbled on how to do it, because we can slice in verilog, but the width of slicing cannot be a variable, it will be of different size each time
              L[row_index][col_index] = ((-1)*temp_prod)/(L[row_index][row_index])
            end
            if (col_index == SIZE-1)
              state <= MULT;
          end
        MULT :
        //if we solve the above problem, then this state is also done
        
      endcase
  end
  

endmodule
