`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.12.2021 13:11:26
// Design Name: 
// Module Name: control_logic
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


module control_logic
#(parameter SPECTRAL_BANDS = 100,
    WIDTH = 16,
    MAC_WIDTH = 36,
    TOTAL_PIXELS = 100000,
    TOTAL_ENDMEMBERS = 20
)
(
input [WIDTH-1:0] pixel_in,
input in_axi_valid,
input in_axi_ready,
output reg [WIDTH-1:0] pixel_out,
output reg out_axi_valid,
output reg out_axi_ready,
output reg intr,
output reg [MAC_WIDTH-1:0] mac_out_1,
output reg [MAC_WIDTH-1:0] mac_out_2,
output reg mac_reset,
output reg mac_valid_out,
output reg [3:0] state,
output reg finish,
input [MAC_WIDTH-1:0] mac_in,
input mac_valid_in,
input clk,
input rst
    );

localparam IDLE = 0,
    PRE_INIT = 1,
    INIT_m1 = 2,
    INIT_m2 = 3,
    FINISH = 4;



reg [WIDTH-1:0] buffer [SPECTRAL_BANDS-1:0];
reg buffer_state;
wire [WIDTH-1:0] buffer_1;
wire [WIDTH-1:0] buffer_2;
assign buffer_1 = buffer[0];
assign buffer_2 = buffer[SPECTRAL_BANDS-1];
reg buffer_1_valid;
reg buffer_2_valid;
integer i;

reg [$clog2(TOTAL_PIXELS)-1:0] in_pixel_counter;
reg [$clog2(SPECTRAL_BANDS)-1:0] in_spectral_counter;

//reg [$clog2(SPECTRAL_BANDS):0] m1_column_counter_1;
//reg [$clog2(SPECTRAL_BANDS):0] m1_column_counter_2;
wire [WIDTH-1:0] m1_in_1;
wire [WIDTH-1:0] m1_in_2;
wire [WIDTH-1:0] m1_out_1;
wire [WIDTH-1:0] m1_out_2;
wire [$clog2(SPECTRAL_BANDS)-1:0] m1_addr_1;
wire [$clog2(SPECTRAL_BANDS)-1:0] m1_addr_2;
reg m1_wr_en_1;
reg m1_wr_en_2;

reg [$clog2(SPECTRAL_BANDS)-1:0] endmembers_column_counter_1;
reg [$clog2(SPECTRAL_BANDS)-1:0] endmembers_column_counter_2;
reg [$clog2(TOTAL_ENDMEMBERS-1):0] endmembers_row_counter_1;
reg [$clog2(TOTAL_ENDMEMBERS)-1:0] endmembers_row_counter_2;

wire [WIDTH-1:0] endmembers_in_1;
wire [WIDTH-1:0] endmembers_in_2;
wire [WIDTH-1:0] endmembers_out_1;
wire [WIDTH-1:0] endmembers_out_2;
wire [$clog2(SPECTRAL_BANDS*TOTAL_ENDMEMBERS)-1:0] endmembers_addr_1;
wire [$clog2(SPECTRAL_BANDS*TOTAL_ENDMEMBERS)-1:0] endmembers_addr_2;
reg endmembers_wr_en_1;
reg endmembers_wr_en_2;
reg endmembers_valid;

wire [WIDTH-1:0] mux0, mux1; 
reg [WIDTH-1:0] mux2;
reg mux0_s, mux1_s;
reg [1:0] mux2_s;

reg [$clog2(SPECTRAL_BANDS):0] mac_in_counter;
reg [MAC_WIDTH-1:0] max_dist;
reg max_dist_changed;
reg load; //to load contents of buffer to memory
reg delayed_in_axi_valid;
reg [WIDTH-1:0] delayed_pixel_in;


wire [WIDTH-1:0] sub1 , sub2, sub_1_in_1, sub_1_in_2, sub_2_in_1, sub_2_in_2;


assign sub1 = sub_1_in_1 + (~sub_1_in_2) + 1;
assign sub2 = sub_2_in_1 + (~sub_2_in_2) + 1;
assign sub_1_in_1 = mux2;
assign sub_1_in_2 = mux1;

assign mux0 = mux0_s ? pixel_in : buffer_2;
assign mux1 = mux1_s ? endmembers_out_2 : m1_out_2;

always @ (*) begin
    case (mux2_s)
    'b00 : mux2 = buffer_2;
    'b01 : mux2 = delayed_pixel_in;
    'b10 : mux2 = endmembers_out_2;
    endcase
end

assign m1_addr_1 = endmembers_column_counter_1;
assign m1_addr_2 = endmembers_column_counter_2;
assign m1_in_1 = mux0;

assign endmembers_addr_1 = (endmembers_row_counter_1)*SPECTRAL_BANDS + endmembers_column_counter_1;
assign endmembers_addr_2 = (endmembers_row_counter_2)*SPECTRAL_BANDS + endmembers_column_counter_2;
assign endmembers_in_1 = buffer_2;

always @ (posedge clk) begin
    if ( in_axi_valid ) begin
        for( i = 0 ; i < SPECTRAL_BANDS - 1 ; i = i + 1) begin
            buffer[0] <= pixel_in;
            buffer[i + 1] <= buffer[i];
        end
    end    
end

always @ (posedge clk) begin
    if (rst) begin
        delayed_pixel_in <= 0;
        delayed_in_axi_valid <= 0;
    end
    if ( state != PRE_INIT) begin
        delayed_pixel_in <= pixel_in;
        delayed_in_axi_valid <= in_axi_valid;
    end    
end

always @ (posedge clk) begin
    if (rst) begin
        in_pixel_counter <= 0;
        in_spectral_counter <= 0;
    end
    else if (in_axi_valid) begin
        if (in_spectral_counter == SPECTRAL_BANDS - 1 ) begin
            in_spectral_counter <= 0;
            if (in_pixel_counter == TOTAL_PIXELS - 1) begin
                in_pixel_counter <= 0;
            end
            else begin
                in_pixel_counter <= in_pixel_counter + 1;
            end    
        end
        else begin
            in_spectral_counter <= in_spectral_counter + 1;
        end    
    end
end

/*always @ (posedge clk) begin
    if (rst) begin
        endmembers_column_counter_1 <= 0;
        endmembers_column_counter_2 <= 0;
        endmembers_row_counter_1 <= 0;
        endmembers_row_counter_2 <= 0;
    end
    else if (endmembers_wr_en_1 | m1_wr_en_1) begin
        if ( endmembers_column_counter_1 == SPECTRAL_BANDS-1) begin
            endmembers_column_counter_1 <= 0;
        end
        else begin
            endmembers_column_counter_1 <= endmembers_column_counter_1 + 1;
        end    
    end
end
*/

always @ (posedge clk) begin
    if (rst) begin
        state <= IDLE;
        mac_in_counter <= 0;
        max_dist_changed <= 0;
        max_dist <= 0;
        load <= 0;
        mac_reset <= 0;
        endmembers_column_counter_1 <= 0;
        endmembers_column_counter_2 <= 0;
        endmembers_row_counter_1 <= 0;
        endmembers_row_counter_2 <= 0;
    end
    else begin
        case (state)
        IDLE : begin
            state <= PRE_INIT;
            intr <= 1;
        end
        PRE_INIT: begin              //filling input in m1 via port 1
            if (in_axi_valid) begin
                intr <= 0;         
                if ( endmembers_column_counter_1 == SPECTRAL_BANDS-1) begin
                    state <= INIT_m2;
                    intr <= 1;
                end 
            end
              
        end
       INIT_m1 : begin
            if (in_axi_valid) begin
                intr <= 0;
                if ( endmembers_column_counter_2 == SPECTRAL_BANDS-1) begin
                    endmembers_column_counter_2 <= 0;
                end
                else begin
                    endmembers_column_counter_2 <= endmembers_column_counter_2 + 1;  // to subtractor       
                end
            end
            if (mac_valid_in) begin    
                if ( mac_in_counter == SPECTRAL_BANDS-1) begin
                    intr <= 1;
                    mac_reset <= 1;                   
                    mac_in_counter <= 0;
                    if (in_pixel_counter == 1) begin
                        max_dist_changed <= 0;
                        if (max_dist_changed) begin
                            state <= INIT_m2;
                        end
                        else if (!max_dist_changed & !(mac_in > max_dist)) begin
                            state <= FINISH;
                            intr <= 0;
                        end 
                    end
                    if ( mac_in > max_dist) begin
                        max_dist <= mac_in;
                        load <= 1;
                        if (in_pixel_counter == 1) begin
                            state <= INIT_m2;
                        end
                        else begin
                            max_dist_changed <= 1;
                        end
                    end
                    else begin    
                        load <= 0;
                    end
                end
                else begin
                    mac_in_counter <= mac_in_counter + 1;
                end
            end       
        end
        INIT_m2 : begin
            if (in_axi_valid) begin
                intr <= 0;
                if ( endmembers_column_counter_2 == SPECTRAL_BANDS-1) begin
                    endmembers_column_counter_2 <= 0;
                end
                else begin
                    endmembers_column_counter_2 <= endmembers_column_counter_2 + 1;  // to subtractor       
                end
            end
            if (mac_valid_in) begin    

                if ( mac_in_counter == SPECTRAL_BANDS-1) begin
                    intr <= 1;
                    mac_reset <= 1;
                    mac_in_counter <= 0;
                    if (in_pixel_counter == 1) begin
                        max_dist_changed <= 0;
                        if (max_dist_changed) begin
                            state <= INIT_m1;
                        end
                        else if (!max_dist_changed & !(mac_in > max_dist)) begin
                            state <= FINISH;
                            intr <= 0;
                        end 
                    end
                    if ( mac_in > max_dist) begin
                        max_dist <= mac_in;
                        load <= 1;
                        if (in_pixel_counter == 1) begin
                            state <= INIT_m1;
                        end
                        else begin
                            max_dist_changed <= 1;
                        end
                    end
                    else begin    
                        load <= 0;
                    end
                end
                else begin
                    mac_in_counter <= mac_in_counter + 1;
                end
            end
            
        
        end
        endcase
        
        
        if (mac_reset) begin
            mac_reset <= 0;
        end
        
        if ( endmembers_column_counter_1 == SPECTRAL_BANDS-1) begin
            endmembers_column_counter_1 <= 0;
        end
        else if (endmembers_wr_en_1 | m1_wr_en_1) begin
            endmembers_column_counter_1 <= endmembers_column_counter_1 + 1;    
        end
    
    end        
end



always @ (*) begin
    m1_wr_en_1 = 0;
    m1_wr_en_2 = 0;
    endmembers_wr_en_1 = 0;
    endmembers_wr_en_2 = 0;
    finish = 0;
    case (state)
    IDLE: begin
    end
    PRE_INIT: begin
        mux0_s = 'b1;
        m1_wr_en_1 = in_axi_valid;
        
    end
    INIT_m1: begin
        mux2_s = 'b01;
        mux1_s = 1;
        m1_wr_en_1 = in_axi_valid & load;
        mac_out_1 = {{MAC_WIDTH - WIDTH{sub1[WIDTH - 1]}},sub1};
        mac_out_2 = {{MAC_WIDTH - WIDTH{sub1[WIDTH - 1]}},sub1};
        mac_valid_out = delayed_in_axi_valid;     
    end
    INIT_m2: begin
        mux2_s = 'b01;
        mux1_s = 0;
        endmembers_wr_en_1 = in_axi_valid & load;
        mac_out_1 = {{MAC_WIDTH - WIDTH{sub1[WIDTH - 1]}},sub1};
        mac_out_2 = {{MAC_WIDTH - WIDTH{sub1[WIDTH - 1]}},sub1}; 
        mac_valid_out = delayed_in_axi_valid;  
    end
    FINISH: begin
        finish = 1;
    end
    endcase
end


memory 
#(.SIZE(TOTAL_ENDMEMBERS*SPECTRAL_BANDS),
  .WIDTH(WIDTH))
endmembers
(
.pixel_in1(endmembers_in_1),
.pixel_in2(endmembers_in_2),
.pixel_out1(endmembers_out_1),
.pixel_out2(endmembers_out_2),
.enable1(1'b1),
.wr_enable1(endmembers_wr_en_1),
.enable2(1'b1),
.wr_enable2(endmembers_wr_en_2),
.addr1(endmembers_addr_1),
.addr2(endmembers_addr_2),
.clk(clk)
    );

memory 
#(.SIZE(SPECTRAL_BANDS),
  .WIDTH(WIDTH))
m1
(
.pixel_in1(m1_in_1),
.pixel_in2(m1_in_2),
.pixel_out1(m1_out_1),
.pixel_out2(m1_out_2),
.enable1(1'b1),
.wr_enable1(m1_wr_en_1),
.enable2(1'b1),
.wr_enable2(m2_wr_en_1),
.addr1(m1_addr_1),
.addr2(m1_addr_2),
.clk(clk)
    );
    
       
       
endmodule
