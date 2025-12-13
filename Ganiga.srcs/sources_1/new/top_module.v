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

    // Active-low reset from BTNC
    wire rst_ni = ~BTNC;

    // 60 Hz tick
    wire tick;
    game_tick u_tick(
        .clk(CLK100MHZ),
        .rst_ni(rst_ni),
        .tick(tick)
    );

    // VGA sync
    wire [9:0] x, y;
    wire blank;
    vga_sync u_vga(
        .clk(CLK100MHZ),
        .rst_ni(rst_ni),
        .hsync(HS),
        .vsync(VS),
        .blank(blank),
        .x(x),
        .y(y)
    );

    // Game signals
    wire [9:0] p_x, p_y;
    wire b_active;
    wire [9:0] b_x, b_y;
    wire [4:0] en_alive;
    wire [9:0] en_grp_x, en_grp_y;

    wire game_playing;
    wire game_over;
    wire [3:0] score_h, score_t, score_o;

    // Easy enemy speed knobs (edit here)
    localparam integer ENEMY_MOVE_DELAY  = 30; // bigger = slower
    localparam integer ENEMY_STEP_X      = 1;
    localparam integer ENEMY_STEP_Y      = 10;
    localparam integer ENEMY_GAME_OVER_Y = 440;

    // Game engine
    game_engine #(
        .ENEMY_MOVE_DELAY (ENEMY_MOVE_DELAY),
        .ENEMY_STEP_X     (ENEMY_STEP_X),
        .ENEMY_STEP_Y     (ENEMY_STEP_Y),
        .ENEMY_GAME_OVER_Y(ENEMY_GAME_OVER_Y)
    ) engine (
        .clk(CLK100MHZ),
        .rst_ni(rst_ni),
        .tick(tick),
        .btn_left(BTNL),
        .btn_right(BTNR),
        .btn_fire(BTNU),

        .player_x(p_x),
        .player_y(p_y),
        .bullet_active(b_active),
        .bullet_x(b_x),
        .bullet_y(b_y),
        .enemies_alive(en_alive),
        .enemy_group_x(en_grp_x),
        .enemy_group_y(en_grp_y),

        .game_playing(game_playing),
        .game_over(game_over),
        .score_h(score_h),
        .score_t(score_t),
        .score_o(score_o)
    );

    // Renderer
    renderer ren (
        .clk(CLK100MHZ),
        .blank(blank),
        .x(x), .y(y),

        .player_x(p_x),
        .player_y(p_y),
        .bullet_active(b_active),
        .bullet_x(b_x),
        .bullet_y(b_y),
        .enemies_alive(en_alive),
        .enemy_group_x(en_grp_x),
        .enemy_group_y(en_grp_y),

        .game_playing(game_playing),
        .game_over(game_over),
        .score_h(score_h),
        .score_t(score_t),
        .score_o(score_o),

        .r(RED), .g(GREEN), .b(BLUE)
    );

endmodule
