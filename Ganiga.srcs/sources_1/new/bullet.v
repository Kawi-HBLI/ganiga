`timescale 1ns / 1ps

module bullet #(
    parameter BULLET_W = 2,
    parameter BULLET_H = 6
)(
    input  wire       clk,
    input  wire       rst_ni,
    input  wire       fire,
    input  wire       tick,
    input  wire       hit,         // [NEW] ?????????????????????
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
   
    output reg        active,
    output reg [9:0]  bullet_x,
    output reg [9:0]  bullet_y
);
    reg fire_prev;

    always @(posedge clk) begin
        if (!rst_ni) begin
            active    <= 1'b0;
            bullet_x  <= 10'd0;
            bullet_y  <= 10'd0;
            fire_prev <= 1'b0;
        end else begin
            fire_prev <= fire;

            // 1. Logic ?????? (??????????? active = 0)
            if (fire && !fire_prev && !active) begin
                active   <= 1'b1;
                bullet_x <= player_x + 8;
                bullet_y <= player_y - 6;
            end

            // 2. Logic ?????????????????????
            if (active) begin
                if (hit) begin
                     active <= 1'b0; // [NEW] ????? ?????????????????
                end
                else if (tick) begin
                    if (bullet_y > 10)
                        bullet_y <= bullet_y - 10;
                    else
                        active <= 1'b0; // ????????
                end
            end
        end
    end

endmodule