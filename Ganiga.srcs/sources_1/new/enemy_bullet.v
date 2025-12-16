`timescale 1ns / 1ps

module enemy_bullet #(
    parameter BULLET_W = 4,   
    parameter BULLET_H = 8,
    parameter SPEED_Y  = 8,   
    parameter SCREEN_H = 480
)(
    input  wire       clk,
    input  wire       rst_ni,
    input  wire       tick,

    input  wire       enemy_fire, 
    input  wire [9:0] spawn_x,
    input  wire [9:0] spawn_y,
    input  wire       hit,        

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
            fire_prev <= enemy_fire;
            if (enemy_fire && !fire_prev && !active) begin
                active   <= 1'b1;
                bullet_x <= spawn_x;
                bullet_y <= spawn_y;
            end

            if (active) begin
                if (hit) begin
                    active <= 1'b0;
                end else if (tick) begin
                    if (bullet_y < (SCREEN_H - BULLET_H - SPEED_Y))
                        bullet_y <= bullet_y + SPEED_Y;
                    else
                        active <= 1'b0;
                end
            end
        end
    end

endmodule