`timescale 1ns / 1ps
// This module computes the multiplication of two matrices given
// A matrix is defined by 64 bits, because it's a 2x2 and each number is 16 bits (16*4 = 64)
// The first 8 LSB bits of the number are the decimal part, the 8 MSB are the integer part
// Every port has to be of size = 8bits
module mmul(input clk ,input rst, input wire in_rdy ,
            input wire[15:8] A11int,input wire[7:0] A11dec,input wire[15:8] A12int,input wire[7:0] A12dec,input wire[15:8] A21int,input wire[7:0] A21dec, input wire[15:8] A22int, input wire[7:0] A22dec,
            input wire[15:8] B11int,input wire[7:0] B11dec,input wire[15:8] B12int,input wire[7:0] B12dec,input wire[15:8] B21int,input wire[7:0] B21dec, input wire[15:8] B22int, input wire[7:0] B22dec,
            output reg[127:120] Resint11_A, output reg[119:112] Resint11_B, output reg[111:104] Resdec11_A, output reg[103:96] Resdec11_B, output reg[95:88] Resint12_A, output reg[87:80] Resint12_B, output reg[79:72] Resdec12_A, output reg[71:64] Resdec12_B,
            output reg[63:56] Resint21_A, output reg[55:48] Resint21_B, output reg[47:40] Resdec21_A, output reg[39:32] Resdec21_B, output reg[31:24] Resint22_A, output reg[23:16] Resint22_B,  output reg[15:8] Resdec22_A, output reg[7:0] Resdec22_B,
            output reg out_rdy);

reg  [15:0] mul_a1, mul_b1, mul_a2, mul_b2;
reg  m_in_rdy1, m_in_rdy2;
wire m_res_rdy1, m_res_rdy2;
wire [31:0] m_out1, m_out2;
reg  rst1, rst2;
reg  rdyck;

// multiplier modules
bmul mul_1 (.clk(clk), .rst(rst1), .a_int(mul_a1[15:8]), .b_int(mul_b1[15:8]), .a_dec(mul_a1[7:0]), .b_dec(mul_b1[7:0]), .in_rdy(m_in_rdy1), .res_int1(m_out1[31:24]), .res_int2(m_out1[23:16]), .res_dec1(m_out1[15:8]), .res_dec2(m_out1[7:0]), .res_rdy(m_res_rdy1));
bmul mul_2 (.clk(clk), .rst(rst2), .a_int(mul_a2[15:8]), .b_int(mul_b2[15:8]), .a_dec(mul_a2[7:0]), .b_dec(mul_b2[7:0]), .in_rdy(m_in_rdy2), .res_int1(m_out2[31:24]), .res_int2(m_out2[23:16]), .res_dec1(m_out2[15:8]), .res_dec2(m_out2[7:0]), .res_rdy(m_res_rdy2));

parameter N =  2; // matrix dimension, fixed

// registers for 3D conversion of inputs
reg [15:0] A [0:N-1][0:N-1];
reg [15:0] B [0:N-1][0:N-1];

reg [2:0] STATE, NEXT_STATE; // for EFSM

parameter ST_RES = 3'b000, ST_0 = 3'b001 , ST_1 = 3'b010 , ST_2 = 3'b011 ,ST_3 = 3'b100, ST_4 = 3'b101, ST_DONE = 3'b110, ST_OUTPUT = 3'b111;

always @(STATE ,in_rdy,rdyck) begin
    case(STATE)
        ST_RES:begin NEXT_STATE <= ST_0; end

        ST_0: begin//Init
                if (in_rdy) begin
                    NEXT_STATE <= ST_1;
                end
                else begin
                    NEXT_STATE <= ST_0;
                end
              end
        ST_1: begin
                NEXT_STATE <= ST_2;
              end

        ST_2: begin//prima riga per prima colonna
                if(rdyck) begin
                    NEXT_STATE <= ST_3;
                end
                else begin
                // nop
                end
              end

        ST_3: begin//prima riga per seconda colonna e memorizza valori prima
               if(rdyck) begin
                NEXT_STATE <= ST_4;
                end else
                begin end
              end

        ST_4:begin//seconda riga per prima colonna e memorizza valori prima
             if(rdyck) begin
                NEXT_STATE <= ST_DONE;
             end else
                begin end
             end

        ST_DONE:begin//seconda riga per seconda colonna e memorizza valori prima
            if(rdyck) begin
                 NEXT_STATE <= ST_OUTPUT;
            end else
                begin end
            end

         ST_OUTPUT: begin
            if(rdyck) begin
                NEXT_STATE <= ST_0;
            end
          end

        default: begin NEXT_STATE <= ST_RES; end
    endcase
end

always @(posedge clk, posedge rst) begin
    if(rst)begin
        STATE <= ST_RES;
            // clear all registers
            A[0][0] <= 0;
            A[1][0] <= 0;
            A[0][1] <= 0;
            A[1][1] <= 0;
            B[0][0] <= 0;
            B[1][0] <= 0;
            B[0][1] <= 0;
            B[1][1] <= 0;
            Resint11_A <= 0;
            Resint11_B <= 0;
            Resdec11_A <= 0;
            Resdec11_B <= 0;
            Resint12_A <= 0;
            Resint12_B <= 0;
            Resdec12_A <= 0;
            Resdec12_B <= 0;
            Resint21_A <= 0;
            Resint21_B <= 0;
            Resdec21_A <= 0;
            Resdec21_B <= 0;
            Resint22_A <= 0;
            Resint22_B <= 0;
            Resdec22_A <= 0;
            Resdec22_B <= 0;

            out_rdy <= 0;
            mul_a1 <= 0;
            mul_b1 <= 0;
            mul_a2 <= 0;
            mul_b2 <= 0;
            m_in_rdy1 <= 0;
            m_in_rdy2 <= 0;

            rst1 <= 1'b1;
            rst2 <= 1'b1;

            rdyck <=0;
    end
    else begin
    STATE <= NEXT_STATE;
        case(NEXT_STATE)

            ST_RES: begin
                    // nop
                    end

            ST_0:begin
                 rst1 <= 1'b0;
                 rst2 <= 1'b0;

                 out_rdy <= 0;

                 A[0][0] <= 0;
                 A[1][0] <= 0;
                 A[0][1] <= 0;
                 A[1][1] <= 0;
                 B[0][0] <= 0;
                 B[1][0] <= 0;
                 B[0][1] <= 0;
                 B[1][1] <= 0;
            end
            ST_1: begin
                // Input goes into A matrix
                A[0][0][15:8] <= A11int;
                A[0][0][7:0]  <= A11dec;
                A[0][1][15:8] <= A12int;
                A[0][1][7:0]  <= A12dec;
                A[1][0][15:8] <= A21int;
                A[1][0][7:0]  <= A21dec;
                A[1][1][15:8] <= A22int;
                A[1][1][7:0]  <= A22dec;

                // Input goes into B matrix
                B[0][0][15:8] <= B11int;
                B[0][0][7:0]  <= B11dec;
                B[0][1][15:8] <= B12int;
                B[0][1][7:0]  <= B12dec;
                B[1][0][15:8] <= B21int;
                B[1][0][7:0]  <= B21dec;
                B[1][1][15:8] <= B22int;
                B[1][1][7:0]  <= B22dec;

                rst1 <= 1'b1;
                rst2 <= 1'b1;
            end

            ST_2: begin // first row, first column

                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                    if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin
                        mul_a1 <= A[0][0]; //[*][*]
                        mul_b1 <= B[0][0]; //[ ][ ]
                        mul_a2 <= A[0][1]; //[*][ ]
                        mul_b2 <= B[1][0]; //[*][ ]
                        m_in_rdy1 <= 1'b1;
                        m_in_rdy2 <= 1'b1;
                    end

                    if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                        rdyck <= 1'b1;
                        m_in_rdy1 <= 1'b0;
                        m_in_rdy2 <= 1'b0;
                     end
                   end

            ST_3:begin
                rst1 <= 1'b0;
                rst2 <= 1'b0;

                // if here for first time, need to store result and set new operands for multiplication
                if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin
                    rdyck <= 0;
                    Resint11_A <= m_out1[31:24] + m_out2[31:24];
                    Resint11_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec11_A <= m_out1[15:8] +  m_out2[15:8];
                    Resdec11_B <= m_out1[7:0] + m_out2[7:0];

                    mul_a1 <= A[0][0]; //[*][*]
                    mul_b1 <= B[0][1]; //[ ][ ]
                    mul_a2 <= A[0][1]; //[ ][*]
                    mul_b2 <= B[1][1]; //[ ][*]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                end

                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                end

                STATE <= NEXT_STATE;
             end

            ST_4:begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;


                if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin
                    rdyck <= 0;
                    Resint12_A <= m_out1[31:24] + m_out2[31:24];
                    Resint12_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec12_A <= m_out1[15:8]  + m_out2[15:8];
                    Resdec12_B <= m_out1[7:0]   + m_out2[7:0];

                    mul_a1 <= A[1][0]; //[ ][ ]
                    mul_b1 <= B[0][0]; //[*][*]
                    mul_a2 <= A[1][1]; //[*][ ]
                    mul_b2 <= B[1][0]; //[*][ ]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                end

                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                end
            end

            ST_DONE: begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                // if here first time, need to store result and set new operands for multiplication
                if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                    Resint21_A <= m_out1[31:24] + m_out2[31:24];
                    Resint21_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec21_A <= m_out1[15:8]  +  m_out2[15:8];
                    Resdec21_B <= m_out1[7:0]   + m_out2[7:0];

                    mul_a1 <= A[1][0]; //[ ][ ]
                    mul_b1 <= B[0][1]; //[*][*]
                    mul_a2 <= A[1][1]; //[ ][*]
                    mul_b2 <= B[1][1]; //[ ][*]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                end
                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                end
            end

            ST_OUTPUT: begin
                    rdyck <= 0;

                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;

                    Resint22_A <= m_out1[31:24] + m_out2[31:24];
                    Resint22_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec22_A <= m_out1[15:8]  +  m_out2[15:8];
                    Resdec22_B <= m_out1[7:0]   + m_out2[7:0];

                    out_rdy <= 1'b1;
            end

            default: begin end
        endcase
    end
end

endmodule
