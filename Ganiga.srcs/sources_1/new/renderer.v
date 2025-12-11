`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 11:50:17 AM
// Design Name: 
// Module Name: renderer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module renderer(
    input  wire blank,
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire        bullet_active,
    input  wire [9:0]  bullet_x,
    input  wire [9:0]  bullet_y,
    output reg [3:0]  r,
    output reg [3:0]  g,
    output reg [3:0]  b
);

    wire px_player;
    
    player_sprite #(
        .PLAYER_W(16),
        .PLAYER_H(8)
    ) player (
        .x        (x),
        .y        (y),
        .player_x (player_x),
        .player_y (player_y),
        .px_on    (px_player)
    );
    
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    
    wire px_bullet = bullet_active &&
                     (x >= bullet_x) && (x < bullet_x + BULLET_W) &&
                     (y >= bullet_y) && (y < bullet_y + BULLET_H);

    always @(*) begin
        if (blank) begin
            r = 0; g = 0; b = 0;
    
        end else if (px_player) begin
            r = 0; g = 15; b = 0;     // player green
    
        end else if (px_bullet) begin
            r = 0; g = 15; b = 15;    // bullet cyan
    
        end else begin
            r = 0; g = 0; b = 0;
        end
    end
//    assign r = (!blank && x > 0   && x < 300 && y > 0   && y < 300) ? 4'hF : 4'h0;
//    assign g = (!blank && x > 200 && x < 400 && y > 150 && y < 350) ? 4'hF : 4'h0;
//    assign b = (!blank && x > 300 && x < 600 && y > 180 && y < 480) ? 4'hF : 4'h0;
    
endmodule
