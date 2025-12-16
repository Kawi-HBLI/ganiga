`timescale 1ns / 1ps


module player_control #(
    parameter START_X = 320,
    parameter START_Y = 440,
    parameter SPEED   = 8,      
    parameter PLAYER_W = 16,
    parameter SCREEN_W = 640
)(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,        // Game tick 60Hz
    input  wire btn_left,
    input  wire btn_right,
    output reg [9:0] x,
    output wire [9:0] y
);

    assign y = START_Y;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            x <= START_X;
        end else if (tick) begin
            if (btn_left && x > SPEED) 
                x <= x - SPEED;
            else if (btn_right && x < (SCREEN_W - PLAYER_W - SPEED)) 
                x <= x + SPEED;
        end
    end

endmodule
