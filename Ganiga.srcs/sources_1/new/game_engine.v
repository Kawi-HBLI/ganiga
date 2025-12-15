`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 11:13:45 PM
// Design Name: 
// Module Name: game_engine
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


module game_engine #(
    parameter ENEMY_MOVE_DELAY = 30,
    parameter ENEMY_STEP_X     = 1,
    parameter ENEMY_STEP_Y     = 10
) (

    input wire clk,
    input wire rst_ni,
    input wire tick,
    input wire btn_left,
    input wire btn_right,
    input wire btn_fire,

    output wire [9:0] player_x,
    output wire [9:0] player_y,
    output wire       bullet_active,
    output wire [9:0] bullet_x,
    output wire [9:0] bullet_y,
    output wire       enemy_bullet_active,
    output wire [9:0] enemy_bullet_x,
    output wire [9:0] enemy_bullet_y,
    output wire [4:0] enemies_alive,
    output wire [9:0] enemy_group_x,
    output wire [9:0] enemy_group_y,
    output wire       game_playing
);

    // MENU controller
    wire player_hit;
    menu_fsm u_menu(
        .clk(clk),
        .rst_ni(rst_ni),
        .tick(tick),
        .btn_fire(btn_fire),
        .player_hit(player_hit),
        .game_playing(game_playing)
    );

    // Gate submodules so they reset/hold during MENU
    wire rst_game_ni = rst_ni & game_playing;
    wire fire_game   = btn_fire & game_playing;

    // Internal wires for interaction
    wire b_act_raw;
    wire [9:0] b_x_raw, b_y_raw;
    wire bullet_hit_ack;

    // Player Control
    player_control #(
        .START_X(320),
        .START_Y(440),
        .SPEED(4)
    ) p_ctrl (
        .clk(clk), .rst_ni(rst_game_ni), .tick(tick),
        .btn_left(btn_left), .btn_right(btn_right),
        .x(player_x), .y(player_y)
    );

    // Enemy Control
    wire enemy_fire;
    wire [9:0] enemy_fire_x, enemy_fire_y;
    enemy_control #(
        .MOVE_DELAY(ENEMY_MOVE_DELAY),
        .STEP_X(ENEMY_STEP_X),
        .STEP_Y(ENEMY_STEP_Y)
    ) e_ctrl (
        .clk(clk), .rst_ni(rst_game_ni), .tick(tick),
        .bullet_active(b_act_raw),
        .bullet_x(b_x_raw),
        .bullet_y(b_y_raw),
        .bullet_hit_ack(bullet_hit_ack),
        .enemy_fire(enemy_fire),
        .enemy_fire_x(enemy_fire_x),
        .enemy_fire_y(enemy_fire_y),
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x),
        .group_y(enemy_group_y)
    );

    // Bullet
    bullet bullet_inst (
        .clk(clk), .rst_ni(rst_game_ni), .fire(fire_game), .tick(tick),
        .hit(bullet_hit_ack),
        .player_x(player_x), .player_y(player_y),
        .active(b_act_raw),
        .bullet_x(b_x_raw), .bullet_y(b_y_raw)
    );

    assign bullet_active = b_act_raw && !bullet_hit_ack;
    assign bullet_x = b_x_raw;
    assign bullet_y = b_y_raw;

    // ==== Enemy bullet + hit detection (simple Galaga-style) ====
    // Enemy bullet instance (single bullet at a time)
    wire e_act_raw;
    wire [9:0] e_x_raw, e_y_raw;
    // Player hit when enemy bullet overlaps player box (16x16)
    wire player_box_hit = e_act_raw &&
                          (e_x_raw + 2 >= player_x) &&
                          (e_x_raw < player_x + 16) &&
                          (e_y_raw + 6 >= player_y) &&
                          (e_y_raw < player_y + 16);

    // Use player_hit to drop back to MENU.
    assign player_hit = player_box_hit;

    enemy_bullet #(
        .BULLET_W(2),
        .BULLET_H(6),
        .SPEED_Y(6),
        .SCREEN_H(480)
    ) enemy_bullet_i (
        .clk(clk),
        .rst_ni(rst_game_ni),
        .tick(tick),
        .enemy_fire(enemy_fire),
        .spawn_x(enemy_fire_x),
        .spawn_y(enemy_fire_y),
        .hit(player_box_hit),
        .active(e_act_raw),
        .bullet_x(e_x_raw),
        .bullet_y(e_y_raw)
    );

    assign enemy_bullet_active = e_act_raw;
    assign enemy_bullet_x = e_x_raw;
    assign enemy_bullet_y = e_y_raw;

endmodule