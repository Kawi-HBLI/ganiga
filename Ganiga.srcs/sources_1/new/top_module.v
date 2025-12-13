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
    input  wire        CLK100MHZ,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        sw0, input wire sw1, input wire sw2,
    output wire        HS,
    output wire        VS,
    output wire [3:0]  RED,
    output wire [3:0]  GREEN,
    output wire [3:0]  BLUE
);

    // System Signals
    wire rst_ni = ~BTNC;
    wire tick;
    wire [9:0] x, y;
    wire blank;

    // Game Signals (Engine -> Renderer)
    wire [9:0] p_x, p_y;
    wire       b_active;
    wire [9:0] b_x, b_y;
    wire [4:0] en_alive;
    wire [9:0] en_grp_x, en_grp_y;

    // Menu / State signals
    wire game_playing;     // 1 = in game, 0 = menu/over screens
    wire game_over;        // 1 = game over screen

    // Score (BCD digits: hundreds, tens, ones)
    wire [3:0] score_h;
    wire [3:0] score_t;
    wire [3:0] score_o;

    // 1) Tick generator (60Hz)
    game_tick #(
        .CLK_HZ (100_000_000),
        .TICK_HZ(60)
    ) game_tick_i (
        .clk_i (CLK100MHZ),
        .rst_ni(rst_ni),
        .tick_o(tick)
    );

    // 2) VGA sync
    vga_sync vga_driver (
        .clk  (CLK100MHZ),
        .HS   (HS),
        .VS   (VS),
        .x    (x),
        .y    (y),
        .blank(blank)
    );

    // 3) Game Engine
    // NOTE: ไม่มี #(parameter) เพื่อกัน "parameter mismatch"
    // ถ้าคุณอยากปรับความเร็ว enemy ให้ไปแก้ที่ localparam/parameter ใน enemy_control/game_engine ได้ตรง ๆ
    game_engine engine (
        .clk       (CLK100MHZ),
        .rst_ni     (rst_ni),
        .tick       (tick),

        .btn_left   (BTNL),
        .btn_right  (BTNR),
        .btn_fire   (BTNU),

        // state outputs
        .game_playing(game_playing),
        .game_over  (game_over),

        // score outputs
        .score_h    (score_h),
        .score_t    (score_t),
        .score_o    (score_o),

        // outputs to render
        .player_x   (p_x),
        .player_y   (p_y),

        .bullet_active(b_active),
        .bullet_x   (b_x),
        .bullet_y   (b_y),

        .enemies_alive(en_alive),
        .enemy_group_x(en_grp_x),
        .enemy_group_y(en_grp_y)
    );

    // 4) Renderer
    renderer ren (
        .clk        (CLK100MHZ),
        .blank      (blank),
        .x          (x),
        .y          (y),

        .game_playing(game_playing),
        .game_over  (game_over),

        .score_h    (score_h),
        .score_t    (score_t),
        .score_o    (score_o),

        // Data to draw
        .player_x   (p_x),
        .player_y   (p_y),

        .bullet_active(b_active),
        .bullet_x   (b_x),
        .bullet_y   (b_y),

        .enemies_alive(en_alive),
        .enemy_group_x(en_grp_x),
        .enemy_group_y(en_grp_y),

        // Color output
        .r          (RED),
        .g          (GREEN),
        .b          (BLUE)
    );

endmodule