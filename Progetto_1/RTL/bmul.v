`timescale 1ns / 1ps

module bmul(input clk, input rst, input a_int,input b_int,input a_dec,input b_dec, input in_rdy,output res_int1, output res_int2, output res_dec1, output res_dec2, output res_rdy);

//temp for memoryzing intermediate product of multiplication

wire clk,rst,in_rdy,res_rdy;
wire[7:0] a_int,a_dec,b_int,b_dec,res_int1,res_int2,res_dec1,res_dec2;
reg done;
reg[3:0] Count;
reg[31:0] mul;
reg[15:0] temp, b;
reg[3:0] STATE, NEXT_STATE;

parameter size = 16;
parameter ST_RES = 3'd0, ST_0 = 3'd1 , ST_1 = 3'd2  , ST_2 = 3'd3 ,ST_3 = 3'd4, ST_4 = 3'd5, ST_DONE = 3'd6;

//result's integer part 1 (bit from 31 to 24)
assign res_int1 = mul[31:24];
//result's integer part 2 (bit from 23 16)
assign res_int2 = mul[23:16];
//result's decimal part part 1 (bit from 15 to 8)
assign res_dec1 = mul[15:8];
//result's decimal part part 2 (bit from 7 to 0) 
assign res_dec2 = mul[7:0];

//signal that result is ready
assign res_rdy = done;

always @(STATE,in_rdy,a,b) begin
    case(STATE)
        ST_RES: begin
            NEXT_STATE <= ST_0;
        end

        ST_0: begin
            //If input is ready, next state is beginning computation
            if(in_rdy) begin NEXT_STATE <= ST_1; end
            //Else remain in reset state 0
            else begin NEXT_STATE <= ST_0; end
        end

        ST_1:begin
            if(Count == size) begin
                NEXT_STATE <= ST_DONE;
            end else begin
                NEXT_STATE <= ST_2;
            end
        end

        ST_2:begin
           if(b[Count] == 1) begin
               NEXT_STATE <= ST_3;
           end else begin
               NEXT_STATE <= ST_4;
           end
        end

        ST_3:begin
             NEXT_STATE <= ST_1;
        end

        ST_4:begin
             NEXT_STATE <= ST_1;
        end

        ST_DONE:begin
            NEXT_STATE <= ST_0;
        end

        default:begin
            NEXT_STATE <= STATE;
        end

    endcase
end

always @(posedge clk, negedge rst) begin
    if(rst == 1'b1)begin 
        STATE <= ST_RES;
    end
    else begin
        STATE <= NEXT_STATE;
        case(NEXT_STATE)
            ST_RES: begin
                //Reset Out signals
                res_rdy <= 1'b0;
                res_int1 <= 8'b0;
                res_int2 <= 8'b0;
                res_dec1 <= 8'b0;
                res_dec2 <= 8'b0;
                count <= 3'b0;
            ST_0: begin 
                mul <= 32'b0;
                temp <= 16'b0;
                b <= 16'b0;
                Count <= 0;
            end

            ST_1: begin
                temp[15:8] <= a_int;
                temp[7:0] <= a_dec;
                b[15:8] <= b_int;
                b[7:0] <= b_dec;
            end

            ST_2:begin
               //Do nothing 
            end

            ST_3:begin
                mul <= mul + temp;
                temp <= temp << 1 // could also use temp <= temp * 2;
                Count <= Count + 1;
            end

            ST_4:begin
                temp <= temp << 1 // could also use temp <= temp * 2;
                Count <= Count + 1;
            end

            ST_DONE:begin
                done <= 1'b1;
            end

            default:begin end

        endcase
    end

end

endmodule