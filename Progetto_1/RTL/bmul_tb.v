`timescale 1ns / 1ps

module bmul_tb();
reg clk, rst, in_rdy;
reg [15:0] a, b;

wire res_rdy;
wire [31:0] dout;



bmul dut(.clk(clk), .rst(rst), .a_int(a[15:8]), .b_int(b[15:8]), .a_dec(a[7:0]), .b_dec(b[7:0]), .in_rdy(in_rdy), .res_int1(dout[31:24]), .res_int2(dout[23:16]), .res_dec1(dout[15:8]), .res_dec2(dout[7:0]), .res_rdy(res_rdy));

initial begin
   clk <= 1'b0;
   #20 rst <= 1'b0;
   #20 rst <= 1'b1;

   #20 rst <= 1'b0;
   #10 a <= 16'b0000001000000000 ;
   #20 b <= 16'b0000001000000000 ;
   #20 in_rdy <= 1'b1;
end

always #10 clk <= !clk;

endmodule
