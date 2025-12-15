`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module top_module(
    input CLK100MHZ,
    input BTNL,
    input BTNR,
    input BTNC,
    input BTNU,
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
    localparam integer ENEMY_MOVE_DELAY = 30;
    localparam integer ENEMY_STEP_X     = 1;
    localparam integer ENEMY_STEP_Y     = 10;

    wire [9:0] x, y;
    wire blank;

    // Game Signals
    wire [9:0] p_x, p_y;
    wire       b_active;
    wire [9:0] b_x, b_y;
    wire       eb_active;
    wire [9:0] eb_x, eb_y;
    wire [4:0] en_alive;
    wire [9:0] en_grp_x, en_grp_y;
    wire       game_playing;
    wire       game_over;
    wire [1:0] game_state;

    // 1. Clock & Sync
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

    // 2. Game Engine
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
        .game_state(game_state),
        .game_playing(game_playing),
        .game_over(game_over),
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

    // 3. Renderer
    renderer ren (
        .clk(CLK100MHZ),
        .blank(blank),
        .x(x), .y(y),
        .game_state(game_state),
        .game_playing(game_playing),
        .game_over(game_over),
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
        .r(RED), .g(GREEN), .b(BLUE)
    );

endmodule