`timescale 1ns / 1ps

module bmul(input clk, input rst, input wire[7:0] a_int,input wire[7:0] b_int,input wire[7:0] a_dec,input wire[7:0] b_dec, input wire in_rdy,output reg[7:0] res_int1, output reg[7:0] res_int2, output reg[7:0] res_dec1, output reg[7:0] res_dec2, output reg res_rdy);

reg[3:0] Count; // current result of multiplication
reg[31:0] temp, mul;
reg[15:0] b; //temp = a for first step
reg[2:0] STATE, NEXT_STATE;

parameter ST_RES = 3'b000, ST_INITIAL = 3'b001, ST_INPUT = 3'b010, ST_IF = 3'b011, ST_BIT1 = 3'b100, ST_BIT0 = 3'b101, ST_DONE = 3'b110, ST_OUTPUT = 3'b111;

always @(STATE,in_rdy,temp,b,Count) begin
    case(STATE)
        ST_RES: begin
            NEXT_STATE <= ST_INITIAL;
        end

        ST_INITIAL: begin
            //If input is ready, next state is beginning computation
            if(in_rdy) begin NEXT_STATE <= ST_INPUT; end
            //Else remain in reset state 0
            else begin NEXT_STATE <= ST_INITIAL; end
        end

        ST_INPUT:begin
            if(Count == 4'b1111) begin
                NEXT_STATE <= ST_DONE;
            end else begin
                NEXT_STATE <= ST_IF;
            end
        end

        ST_IF:begin
           if(b[Count] == 4'b0001) begin
               NEXT_STATE <= ST_BIT1;
           end else begin
               NEXT_STATE <= ST_BIT0;
           end
        end

        ST_BIT0:begin
             NEXT_STATE <= ST_INPUT;
        end

        ST_BIT1:begin
             NEXT_STATE <= ST_INPUT;
        end

        ST_DONE:begin
            NEXT_STATE <= ST_OUTPUT;
        end

        ST_OUTPUT:begin
            NEXT_STATE <= ST_INITIAL;
        end

        default:begin
            NEXT_STATE <= STATE;
        end

    endcase
end

always @(posedge clk, posedge rst) begin
    if(rst == 1'b1)begin
        STATE <= ST_RES;
    end
    else begin
        STATE <= NEXT_STATE;
        case(NEXT_STATE)
            ST_RES: begin // reset out signals
                res_rdy <= 1'b0;
                res_int1 <= 8'b00000000;
                res_int2 <= 8'b00000000;
                res_dec1 <= 8'b00000000;
                res_dec2 <= 8'b00000000;
                Count <= 4'b0000;
            end

            ST_INITIAL: begin
                mul <= 32'b00000000000000000000000000000000;
                temp <= 32'b00000000000000000000000000000000;
                b <= 16'b0000000000000000;
                Count <= 0;
            end

            ST_INPUT: begin
              if(Count == 4'b0000) begin //This is needed otherwise it keeps resetting temp and b
                temp[15:8] <= a_int;
                temp[7:0] <= a_dec;
                b[15:8] <= b_int;
                b[7:0] <= b_dec;
              end
            end

            ST_IF:begin
               // nop
            end

            ST_BIT1:begin
                mul <= mul + temp;
                temp <= temp << 1; // multiply by 2;
                Count <= Count + 1'd1;
            end

            ST_BIT0:begin
                temp <= temp << 1; // could also use temp <= temp * 2;
                Count <= Count + 1'd1;
            end

            ST_DONE:begin
                res_rdy <= 1'b0;
                res_int1 <= 8'b00000000;
                res_int2 <= 8'b00000000;
                res_dec1 <= 8'b00000000;
                res_dec2 <= 8'b00000000;

                //result's integer part 1 (bit from 31 to 24)
                res_int1 <= mul[31:24];
                //result's integer part 2 (bit from 23 16)
                res_int2 <= mul[23:16];
                //result's decimal part part 1 (bit from 15 to 8)
                res_dec1 <= mul[15:8];
                //result's decimal part part 2 (bit from 7 to 0)
                res_dec2 <= mul[7:0];
                //signal that result is ready
                res_rdy <= 1'b1;
            end

            ST_OUTPUT:begin
                res_rdy <= 1'b0;
            end

            default: begin end

        endcase
    end
end

endmodule
