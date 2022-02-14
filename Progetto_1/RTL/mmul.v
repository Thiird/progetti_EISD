`timescale 1ns / 1ps
//This module multiplies 2 matrices given in input as a 64 bits number.
//Matrices are fixed 2 x 2 dimension and have at each cell a 16 bits fixed point number.
//The number is composed by a 8 bit integer part and a 8 bits decimal part.
module mmul(input A, input B, output Res);

//Registers for input matrices
reg [63:0] A; 
reg [63:0] B;
reg [63:0] Res;
//Registers for 3D conversion of inputs
reg [15:0] A1 [0:N-1][0:N-1];
reg [15:0] B1 [0:N-1][0:N-1];

//Register for 3D result
reg [63:0] Res1 [0:N-1][0:N-1]; 

parameter N =  2; //Matrix dimension
reg [] STATE, NEXT_STATE;

parameter ST_RES = 3'd0, ST_0 = 3'd1 , ST_1 = 3'd2  , ST_2 = 3'd3 ,ST_3 = 3'd4, ST_4 = 3'd5, ST_DONE = 3'd6;

assign 

always @(STATE,in_rdy,A,B) begin
    case(NEXT_STATE) begin
        ST_RES:begin
            NEXT_STATE <= ST_0;
        end

        default:begin NEXT_STATE <= STATE end
    endcase 
end

always @(posedge clk, negedge rst) begin
     if(rst == 1'b1)begin 
        STATE <= ST_RES;
     end else begin
         STATE <= NEXT_STATE;
         case(STATE) begin
             ST_RES:begin
                 //Azzera tutto
             end


            default begin end
         endcase
end

endmodule
