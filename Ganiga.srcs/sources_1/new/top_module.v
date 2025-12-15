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
    input sw0, input sw1, input sw2, 
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
    );

    // System Signals
    wire rst_ni = ~BTNC;
    wire tick;

    // Easy enemy speed tuning
    localparam integer ENEMY_MOVE_DELAY = 30; // bigger = slower
    localparam integer ENEMY_STEP_X     = 1;  // pixels per move
    localparam integer ENEMY_STEP_Y     = 10; // drop when hitting edge

    wire [9:0] x, y;
    wire blank;

    // Game Signals (Wiring between Engine and Renderer)
    wire [9:0] p_x, p_y;
    wire       b_active;
    wire [9:0] b_x, b_y;
    wire       eb_active;
    wire [9:0] eb_x, eb_y;
    wire [4:0] en_alive;
    wire [9:0] en_grp_x, en_grp_y;
    wire       game_playing;

    // 1. Clock & Sync
    // ??????? parameter: game_tick.v ??? CLK_HZ, TICK_HZ -> ???????????????
    game_tick #(
        .CLK_HZ (100_000_000),
        .TICK_HZ(60)
    ) game_tick_i (
        .clk_i (CLK100MHZ),
        .rst_ni(rst_ni),
        .tick_o(tick)
    );

    vga_sync vga_driver (
        .clk(CLK100MHZ), 
        .HS(HS), .VS(VS), 
        .x(x), .y(y), .blank(blank)
    );

    // 2. Game Engine (Logic Center)
    game_engine #(
        .ENEMY_MOVE_DELAY(ENEMY_MOVE_DELAY),
        .ENEMY_STEP_X(ENEMY_STEP_X),
        .ENEMY_STEP_Y(ENEMY_STEP_Y)
    ) engine (
        .clk(CLK100MHZ), 
        .rst_ni(rst_ni), 
        .tick(tick),
        .btn_left(BTNL), 
        .btn_right(BTNR), 
        .btn_fire(BTNU),
        .game_playing(game_playing),
        // Outputs
        .player_x(p_x), 
        .player_y(p_y),
        .bullet_active(b_active), 
        .bullet_x(b_x), 
        .bullet_y(b_y),
        .enemy_bullet_active(eb_active),
        .enemy_bullet_x(eb_x),
        .enemy_bullet_y(eb_y),
        .enemies_alive(en_alive), 
        .enemy_group_x(en_grp_x), 
        .enemy_group_y(en_grp_y)
    );

    // 3. Renderer (Visual Center)
    renderer ren (
        .clk(CLK100MHZ), 
        .blank(blank), 
        .x(x), .y(y),
        .game_playing(game_playing),
        // Data to draw
        .player_x(p_x), 
        .player_y(p_y),
        .bullet_active(b_active), 
        .bullet_x(b_x), 
        .bullet_y(b_y),
        .enemy_bullet_active(eb_active),
        .enemy_bullet_x(eb_x),
        .enemy_bullet_y(eb_y),
        .enemies_alive(en_alive), 
        .enemy_group_x(en_grp_x), 
        .enemy_group_y(en_grp_y),
        // Color output
        .r(RED), .g(GREEN), .b(BLUE)
    );

endmodule
