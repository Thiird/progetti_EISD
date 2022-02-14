`timescale 1ns / 1ps

module bmul_tb();
reg clk, rst, in_rdy;
reg [15:0] a, b;

wire res_rdy;
wire [31:0] dout;



bmul_tb dut(.clk(clk), .rst(rst), .a_int(a[15:8]), .b_int(b[15:8]), .a_dec(a[7:0]), .b_dec(b[7:0]), .in_rdy(in_rdy), .res_int1(dout[31:24]), .res_int2(dout[23:16]), .res_dec1(dout[15:8]), .dout[7:0](res_dec2), .res_rdy(res_rdy));

initial begin
      clk <= 1'b0;
   rst <= #10 1'b0;
   rst <= #30 1'b1;
   din_rdy <= #40 1'b1;
   din_rdy <= #60 1'b0;

    a <= 16'd5 ; 
    b <= 16'd4 ;
end

always #10 clk <= !clk; 

endmodule
