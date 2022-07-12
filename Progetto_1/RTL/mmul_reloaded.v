`timescale 1ns / 1ps
//This module multiplies 2 matrices given in input as a 64 bits number.
//Matrices are fixed 2 x 2 dimension and have at each cell a 16 bits fixed point number.
//The number is composed by a 8 bit integer part and a 8 bits decimal part.
//Every port has to be of size = 8bits
module mmul_reloaded(input clk ,input rst, input wire in_rdy1 ,input wire in_rdy2,
            input wire[15:8] A11,input wire[7:0] A12,input wire[15:8] A21,input wire[7:0] A22,
            input wire[15:8] B11,input wire[7:0] B12,input wire[15:8] B21,input wire[7:0] B22,
            output reg[31:24] Resint_A, output reg[23:16] Resint_B, output reg[15:8] Resdec_A, output reg[7:0] Resdec_B,
            output reg read_in1, output reg read_in2,output reg out_rdy);

reg [15:0] mul_a1, mul_b1, mul_a2, mul_b2;
reg m_in_rdy1, m_in_rdy2;
wire m_res_rdy1, m_res_rdy2;
wire [31:0] m_out1, m_out2;
reg rst1, rst2;
reg rdyck;


//Multiplier module
bmul mul_1 (.clk(clk), .rst(rst1), .a_int(mul_a1[15:8]), .b_int(mul_b1[15:8]), .a_dec(mul_a1[7:0]), .b_dec(mul_b1[7:0]), .in_rdy(m_in_rdy1), .res_int1(m_out1[31:24]), .res_int2(m_out1[23:16]), .res_dec1(m_out1[15:8]), .res_dec2(m_out1[7:0]), .res_rdy(m_res_rdy1));
bmul mul_2 (.clk(clk), .rst(rst2), .a_int(mul_a2[15:8]), .b_int(mul_b2[15:8]), .a_dec(mul_a2[7:0]), .b_dec(mul_b2[7:0]), .in_rdy(m_in_rdy2), .res_int1(m_out2[31:24]), .res_int2(m_out2[23:16]), .res_dec1(m_out2[15:8]), .res_dec2(m_out2[7:0]), .res_rdy(m_res_rdy2));

parameter N =  2; //Matrix dimension

//Registers for 3D conversion of inputs
reg [15:0] A [0:N-1][0:N-1];
reg [15:0] B [0:N-1][0:N-1];

reg [3:0] STATE, NEXT_STATE;

parameter ST_RES = 4'b0000, ST_INITIAL = 4'b0001 , ST_IN_INT = 4'b0010, ST_IN_DEC = 4'b1000, ST_WAIT_DEC = 4'b1001 , ST_MUL1 = 4'b0011 ,ST_MUL2 = 4'b0100, ST_MUL3 = 4'b0101, ST_MUL4 = 4'b0110, ST_OUTPUT = 4'b0111;

always @(STATE ,in_rdy1,rdyck,in_rdy2) begin
    case(STATE)
        ST_RES:begin NEXT_STATE <= ST_INITIAL; end

        ST_INITIAL: begin//Init
                if (in_rdy1) begin
                    NEXT_STATE <= ST_IN_INT;
                end
                else begin
                    NEXT_STATE <= ST_INITIAL;
                end
              end

        ST_IN_INT: begin
                    NEXT_STATE <= ST_WAIT_DEC;
                end

        ST_WAIT_DEC: begin
                        if(in_rdy2) begin
                                NEXT_STATE<= ST_IN_DEC;
                         end else begin end
                     end

        ST_IN_DEC:begin
                       NEXT_STATE <= ST_MUL1;
                  end

        ST_MUL1: begin//prima riga per prima colonna
               if(rdyck)begin NEXT_STATE <= ST_MUL2;
               end else
                begin end
              end

        ST_MUL2: begin//prima riga per seconda colonna e memorizza valori prima
               if(rdyck)begin
                NEXT_STATE <= ST_MUL3;
                end else
                begin end
              end

        ST_MUL3:begin//seconda riga per prima colonna e memorizza valori prima
             if(rdyck)begin
                NEXT_STATE <= ST_MUL4;
             end else
                begin end
             end

        ST_MUL4:begin//seconda riga per seconda colonna e memorizza valori prima
            if(rdyck)begin
                 NEXT_STATE <= ST_OUTPUT;
              end else
                begin end
             end

         ST_OUTPUT: begin
                 NEXT_STATE <= ST_INITIAL;
          end

        default: begin NEXT_STATE <= ST_RES; end
    endcase
end

always @(posedge clk, posedge rst) begin
     if(rst)begin
        STATE <= ST_RES;
             //Azzera tutto
                 A[0][0] <= 0;
                 A[1][0] <= 0;
                 A[0][1] <= 0;
                 A[1][1] <= 0;
                 B[0][0] <= 0;
                 B[1][0] <= 0;
                 B[0][1] <= 0;
                 B[1][1] <= 0;

                 Resint_A <= 0;
                 Resint_B <= 0;
                 Resdec_A <= 0;
                 Resdec_B <= 0;


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
     end else begin
     STATE <= NEXT_STATE;
         case(NEXT_STATE)

             ST_RES: begin
                    end

             ST_INITIAL:begin
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

             ST_IN_INT: begin
                //Integer part of input goes into A matrix
                A[0][0][15:8] <= A11;
                A[0][1][15:8] <= A12;
                A[1][0][15:8] <= A21;
                A[1][1][15:8] <= A22;

                //Integer part of input goes into B matrix
                B[0][0][15:8] <= B11;
                B[0][1][15:8] <= B12;
                B[1][0][15:8] <= B21;
                B[1][1][15:8] <= B22;

                rst1 <= 1'b1;
                rst2 <= 1'b1;
             end

             ST_WAIT_DEC: begin
                read_in1 <= 1'b1;
             end

             ST_IN_DEC: begin
              A[0][0][7:0] <= A11;
              A[0][1][7:0] <= A12;
              A[1][0][7:0] <= A21;
              A[1][1][7:0] <= A22;

              B[0][0][7:0] <= B11;
              B[0][0][7:0] <= B11;
              B[0][1][7:0] <= B12;
              B[1][0][7:0] <= B21;
              B[1][1][7:0] <= B22;

              read_in2 <= 1'b1;
             end



             ST_MUL1: begin // first row, first column
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                    if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin
                        mul_a1 <= A[0][0];//[*][*]
                        mul_b1 <= B[0][0];//[ ][ ]
                        mul_a2 <= A[0][1];//[*][ ]
                        mul_b2 <= B[1][0];//[*][ ]
                        m_in_rdy1 <= 1'b1;
                        m_in_rdy2 <= 1'b1;
                    end

                    if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                        rdyck <= 1'b1;
                        m_in_rdy1 <= 1'b0;
                        m_in_rdy2 <= 1'b0;
                     end
                   end

             ST_MUL2:begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

               if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin //If I'm here for the first time I need to store result and to set new operands for multiplication
                    rdyck <= 0;
                    Resint_A <= m_out1[31:24] + m_out2[31:24];
                    Resint_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec_A <= m_out1[15:8] +  m_out2[15:8];
                    Resdec_B <= m_out1[7:0] + m_out2[7:0];

                    mul_a1 <= A[0][0];//[*][*]
                    mul_b1 <= B[0][1];//[ ][ ]
                    mul_a2 <= A[0][1];//[ ][*]
                    mul_b2 <= B[1][1];//[ ][*]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                    out_rdy <= 1'b1;
                end

                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                    out_rdy <= 1'b0;
                end
             end

             ST_MUL3:begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin //If I'm here for the first time I need to store result and to set new operands for multiplication
                    rdyck <= 0;

                    Resint_A <= m_out1[31:24] + m_out2[31:24];
                    Resint_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec_A <= m_out1[15:8] +  m_out2[15:8];
                    Resdec_B <= m_out1[7:0] + m_out2[7:0];

                    mul_a1 <= A[1][0];//[ ][ ]
                    mul_b1 <= B[0][0];//[*][*]
                    mul_a2 <= A[1][1];//[*][ ]
                    mul_b2 <= B[1][0];//[*][ ]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                    out_rdy <= 1'b1;

                end
                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                    out_rdy <= 1'b0;
                end
             end

             ST_MUL4: begin
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                if(m_in_rdy1 == 1'b0 && m_in_rdy2 == 1'b0) begin //If I'm here for the first time I need to store result and to set new operands for multiplication
                    rdyck <= 0;
                    rst1 <= 1'b0;
                    rst2 <= 1'b0;

                    Resint_A <= m_out1[31:24] + m_out2[31:24];
                    Resint_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec_A <= m_out1[15:8] +  m_out2[15:8];
                    Resdec_B <= m_out1[7:0] + m_out2[7:0];

                    mul_a1 <= A[1][0];//[ ][ ]
                    mul_b1 <= B[0][1];//[*][*]
                    mul_a2 <= A[1][1];//[ ][*]
                    mul_b2 <= B[1][1];//[ ][*]
                    m_in_rdy1 <= 1'b1;
                    m_in_rdy2 <= 1'b1;

                    rst1 <= 1'b1;
                    rst2 <= 1'b1;
                    out_rdy <= 1'b1;
                end

                if(m_res_rdy1 == 1'b1 && m_res_rdy2 == 1'b1) begin
                    rdyck <= 1'b1;
                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;
                    out_rdy <= 1'b0;
                end
             end

             ST_OUTPUT: begin
                    rdyck <= 0;

                    m_in_rdy1 <= 1'b0;
                    m_in_rdy2 <= 1'b0;

                    Resint_A <= m_out1[31:24] + m_out2[31:24];
                    Resint_B <= m_out1[23:16] + m_out2[23:16];
                    Resdec_A <= m_out1[15:8] +  m_out2[15:8];
                    Resdec_B <= m_out1[7:0] + m_out2[7:0];

                    out_rdy <= 1'b1;
              end

             default: begin end
         endcase
    end
end

endmodule
