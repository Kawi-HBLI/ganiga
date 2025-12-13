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
    input  wire       clk,        // ??????? clk ????????? ?????????? sprite
    input  wire       blank,
    input  wire [9:0] x,
    input  wire [9:0] y,

    // Player position
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,

    // Bullet
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,

    // --- NEW: Enemy Inputs (????????? Top Module) ---
    input  wire [4:0] enemies_alive, // ??????????????????????? 5 ??? (1=Alive)
    input  wire [9:0] enemy_group_x, // ????? X ?????????????
    input  wire [9:0] enemy_group_y, // ????? Y ?????????????
    
    output reg  [3:0] r, g, b
);

    // ---------- Player Sprite ??? ROM ----------
    wire player_px_on;
    wire [3:0] spr_r, spr_g, spr_b;

    player_sprite #(
        .SPRITE_W(16),
        .SPRITE_H(16)
    ) player_sprite_i (
        .clk      (clk),
        .x        (x),
        .y        (y),
        .player_x (player_x),
        .player_y (player_y),
        .px_on    (player_px_on),
        .r        (spr_r),
        .g        (spr_g),
        .b        (spr_b)
    );

    // ---------- Bullet (??????????????) ----------
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;

    wire px_bullet =
        bullet_active &&
        (x >= bullet_x) && (x < bullet_x + BULLET_W) &&
        (y >= bullet_y) && (y < bullet_y + BULLET_H);
        
    // ---------- Enemy Logic (?????????) ----------
            // ?????????????????? 5 ???
            reg px_enemy;
            integer k;
            
            localparam ENEMY_W = 32;     // ??????????????
            localparam ENEMY_H = 32;     // ????????????
            localparam ENEMY_GAP = 16;   // ??????????????????
        
            always @(*) begin
                px_enemy = 0;
                // ????????????? 5 ???
                for (k = 0; k < 5; k = k + 1) begin
                    if (enemies_alive[k]) begin
                        // ????????????: (X ????????) + (???????? * ????????)
                        if (x >= (enemy_group_x + k*(ENEMY_W + ENEMY_GAP)) && 
                            x <  (enemy_group_x + k*(ENEMY_W + ENEMY_GAP) + ENEMY_W) &&
                            y >= enemy_group_y &&
                            y <  enemy_group_y + ENEMY_H) begin
                            px_enemy = 1'b1;
                        end
                    end
                end
            end

    // ---------- Render Priority ----------
    always @(*) begin
        if (blank) begin
            r = 0; g = 0; b = 0;
        end
        else if (player_px_on) begin
            // ???????? sprite ROM
            r = spr_r;
            g = spr_g;
            b = spr_b;
        end
        else if (px_bullet) begin
            r = 4'hF; g = 4'hF; b = 4'h0;   // bullet 
        end
        else if (px_enemy) begin
            r = 4'hF; g = 4'hF; b = 4'h0; // Enemy 
        end
        else begin
            r = 0; g = 0; b = 4'h1; // Background ????????????
        end
    end

endmodule