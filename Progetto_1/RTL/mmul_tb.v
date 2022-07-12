`timescale 1ns / 1ps

module mmul_tb();

reg clk, rst, in_rdy1,in_rdy2;
//Matrices to be multiplied
reg [7:0] A[0:3];
reg [7:0] B[0:3];
wire [31:0] mult_out;
wire out, read1, read2;
reg [0:1] count;
/*mmul dut  (.clk(clk) , .rst(rst), .in_rdy(in_rdy) ,
            .A11int(A[0][0][15:8]), .A11dec(A[0][0][7:0]), .A12int(A[0][1][15:8]), .A12dec(A[0][1][7:0]), .A21int(A[1][0][15:8]), .A21dec(A[1][0][7:0]), .A22int(A[1][1][15:8]), .A22dec(A[1][0][7:0]),
            .B11int(B[0][0][15:8]), .B11dec(B[0][0][7:0]), .B12int(B[0][1][15:8]), .B12dec(B[0][1][7:0]), .B21int(B[1][0][15:8]), .B21dec(B[1][0][7:0]),.B22int(B[1][1][15:8]), .B22dec(B[1][0][7:0]),
            .Resint11_A(mult_out[0][0][31:24]), .Resint11_B(mult_out[0][0][23:16]), .Resdec11_A(mult_out[0][0][15:8]), .Resdec11_B(mult_out[0][0][7:0]), .Resint12_A(mult_out[0][1][31:24]), .Resint12_B(mult_out[0][1][23:16]), .Resdec12_A(mult_out[0][1][15:8]), .Resdec12_B(mult_out[0][1][7:0]),
            .Resint21_A(mult_out[1][0][31:24]), .Resint21_B(mult_out[1][0][23:16]), .Resdec21_A(mult_out[1][0][15:8]), .Resdec21_B(mult_out[1][0][7:0]), .Resint22_A(mult_out[1][1][31:24]), .Resint22_B(mult_out[1][1][23:16]),  .Resdec22_A(mult_out[1][1][15:8]), .Resdec22_B(mult_out[1][1][7:0]),
            .out_rdy(out));
*/

mmul_reloaded dut  (.clk(clk) , .rst(rst), .in_rdy1(in_rdy1) , .in_rdy2(in_rdy2),
            .A11(A[0]), .A12(A[1]), .A21(A[2]), .A22(A[3]),
            .B11(B[0]), .B12(B[1]), .B21(B[2]), .B22(B[3]),
            .Resint_A(mult_out[31:24]), .Resint_B(mult_out[23:16]), .Resdec_A(mult_out[15:8]), .Resdec_B(mult_out[7:0]),
            .read_in1(read1),.read_in2(read2) ,.out_rdy(out));

initial begin
clk <= 0;

#10 rst <= 1'b1;
#30 rst <= 1'b0;

#20
A[0] <= 8'b00000001;
A[1] <= 8'b00000000;
A[2] <= 8'b00000000;
A[3] <= 8'b00000001;

#20
B[0] <= 8'b00000001;
B[1] <= 8'b00000000;
B[2] <= 8'b00000000;
B[3] <= 8'b00000001;

#10 in_rdy1 <= 1'b1;

while(read1 == 1'b0) begin end

#40
in_rdy1 <= 1'b0;

A[0] <= 8'b00000000;
A[1] <= 8'b00000000;
A[2] <= 8'b00000000;
A[3] <= 8'b00000000;

B[0] <= 8'b00000000;
B[1] <= 8'b00000000;
B[2] <= 8'b00000000;
B[3] <= 8'b00000000;

#10 in_rdy2 <= 1'b1;
#30 in_rdy2 <= 1'b0;

end

always #10 clk <= !clk;

endmodule