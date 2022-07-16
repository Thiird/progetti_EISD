 // <time_unit>/<time_precision>
`timescale 1ns / 1ps

module mmul_tb();

reg clk, rst, in_rdy1,in_rdy2;
// matrices to be multiplied
reg [7:0] A[0:3];
reg [7:0] B[0:3];
wire [31:0] mult_out;
wire out, read1, read2;
reg [0:1] count;

mmul_reloaded dut  (.clk(clk) , .rst(rst), .in_rdy1(in_rdy1) , .in_rdy2(in_rdy2),
            .A11(A[0]), .A12(A[1]), .A21(A[2]), .A22(A[3]),
            .B11(B[0]), .B12(B[1]), .B21(B[2]), .B22(B[3]),
            .Resint_A(mult_out[31:24]), .Resint_B(mult_out[23:16]), .Resdec_A(mult_out[15:8]), .Resdec_B(mult_out[7:0]),
            .read_in1(read1),.read_in2(read2) ,.out_rdy(out));

// set initial values for the mmul module
initial
begin
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

// toggle clock to run simulation
always #10 clk <= !clk;

endmodule