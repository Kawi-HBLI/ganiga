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
    input  wire       clk,
    input  wire       blank,
    input  wire [9:0] x,
    input  wire [9:0] y,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    input  wire [4:0] enemies_alive,
    input  wire [9:0] enemy_group_x,
    input  wire [9:0] enemy_group_y,
    
    output reg  [3:0] r, g, b
);

    // 1. Player Sprite
    wire px_player;
    wire [3:0] p_r, p_g, p_b;
    player_sprite spr_player (
        .clk(clk), .x(x), .y(y),
        .player_x(player_x), .player_y(player_y),
        .px_on(px_player), .r(p_r), .g(p_g), .b(p_b)
    );

    // 2. Enemy Sprite (NEW)
    wire px_enemy;
    wire [3:0] e_r, e_g, e_b;
    enemy_sprite spr_enemy (
        .x(x), .y(y),
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x), .group_y(enemy_group_y),
        .px_on(px_enemy), .r(e_r), .g(e_g), .b(e_b)
    );

    // 3. Bullet (Keep simple logic here or move to module)
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    wire px_bullet = bullet_active &&
                     (x >= bullet_x) && (x < bullet_x + BULLET_W) &&
                     (y >= bullet_y) && (y < bullet_y + BULLET_H);

    // 4. Compositing
    always @(*) begin
        if (blank) begin
            r = 0; g = 0; b = 0;
        end
        else if (px_player) begin
            r = p_r; g = p_g; b = p_b;
        end
        else if (px_bullet) begin
            r = 4'hF; g = 4'hF; b = 4'hF; // White bullet
        end
        else if (px_enemy) begin
            r = e_r; g = e_g; b = e_b;    // Color from sprite
        end
        else begin
            r = 0; g = 0; b = 4'h1;       // Background
        end
    end

endmodule