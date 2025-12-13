`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 11:12:49 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input CLK100MHZ,
    input BTNL,
    input BTNR,
    input BTNC,
    input BTNU,
    input sw0,
    input sw1,
    input sw2,
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
    );
    
    localparam PLAYER_W = 16;
    
    // --- NEW: Enemy Parameters ---
    localparam ENEMY_W = 32;
    localparam ENEMY_H = 32;
    localparam ENEMY_GAP = 16;
    
    wire [9:0] x, y;
    wire blank;
    wire [3:0] r, g, b;
    wire rst_ni = ~BTNC;
    wire game_tick_w;
    wire bullet_active;
    wire [9:0] bullet_x;
    wire [9:0] bullet_y;
    
    // --- NEW: Enemy Signals ---
    reg [4:0] enemies_alive = 5'b11111; // 1 = alive
    reg [9:0] enemy_group_x = 100;
    reg [9:0] enemy_group_y = 50;
    reg [5:0] move_timer = 0;
    reg       move_dir = 0; // 0: Right, 1: Left
    integer i; // For loop variable
    
    game_tick #(
        .CLK_HZ (100_000_000),
        .TICK_HZ(60)
    ) game_tick_i (
        .clk_i (CLK100MHZ),
        .rst_ni(rst_ni),
        .tick_o(game_tick_w)
    );
    
    vga_sync u1(
        .clk(CLK100MHZ), 
        .HS(HS), 
        .VS(VS), 
        .x(x), 
        .y(y),
        .blank(blank)
    );
    
    reg [9:0] player_x = 320;
    wire [9:0] player_y = 440;
    
    // --- Main Logic Block (Player + Enemy) ---
    always @(posedge CLK100MHZ) begin
        if (!rst_ni) begin
            player_x <= 320;
            // Reset Enemy
            enemies_alive <= 5'b11111;
            enemy_group_x <= 100;
            enemy_group_y <= 50;
            move_timer <= 0;
            move_dir <= 0;
        end else if (game_tick_w) begin
            // 1. Player Movement (Code ????)
            if (BTNL && player_x > 4)
                player_x <= player_x - 4;
            else if (BTNR && player_x < 640-PLAYER_W)
                player_x <= player_x + 4;

            // 2. Enemy Movement (?????????)
            // ??? Timer ????????????????????????????????? Player
            if (move_timer == 30) begin
                move_timer <= 0;
                if (move_dir == 0) begin // Move Right
                    if (enemy_group_x < 640 - (5*(ENEMY_W+ENEMY_GAP)) - 20)
                        enemy_group_x <= enemy_group_x + 1; 
                    else begin
                        move_dir <= 1; // Change Direction
                        enemy_group_y <= enemy_group_y + 10; // Drop down
                    end
                end else begin // Move Left
                    if (enemy_group_x > 20)
                        enemy_group_x <= enemy_group_x - 1;
                    else begin
                        move_dir <= 0; // Change Direction
                        enemy_group_y <= enemy_group_y + 10; // Drop down
                    end
                end
            end else begin
                move_timer <= move_timer + 1;
            end

            // 3. Collision Detection (Bullet vs Enemy)
            if (bullet_active) begin
                for (i = 0; i < 5; i = i + 1) begin
                    if (enemies_alive[i] && 
                        bullet_x + 2 >= (enemy_group_x + i*(ENEMY_W+ENEMY_GAP)) &&
                        bullet_x     <  (enemy_group_x + i*(ENEMY_W+ENEMY_GAP) + ENEMY_W) &&
                        bullet_y     >= enemy_group_y &&
                        bullet_y     <  enemy_group_y + ENEMY_H) 
                    begin
                        enemies_alive[i] <= 0; // Enemy Dies!
                        // ????????: Bullet ?????????????????? ?????????????????? kill bullet ??????
                    end
                end
            end
        end
    end
    
    // ?????? renderer ????????? enemies (??????????? renderer.v ????? port ????????????????)
    renderer ren(
        .clk         (CLK100MHZ),   
        .blank       (blank),
        .x           (x),
        .y           (y),
        .player_x    (player_x),
        .player_y    (player_y),
        .bullet_active(bullet_active),
        .bullet_x    (bullet_x),
        .bullet_y    (bullet_y),
        // ????????????????
        .enemies_alive(enemies_alive),
        .enemy_group_x(enemy_group_x),
        .enemy_group_y(enemy_group_y),
        .r           (r),
        .g           (g),
        .b           (b)
    );
    
    bullet bullet_i(
        .clk       (CLK100MHZ),
        .rst_ni    (rst_ni),
        .fire      (BTNU),
        .tick      (game_tick_w),
        .player_x  (player_x),
        .player_y  (player_y),
        .active    (bullet_active),
        .bullet_x  (bullet_x),
        .bullet_y  (bullet_y)
    );
    
    assign RED = r;
    assign GREEN = g;
    assign BLUE = b;
endmodule