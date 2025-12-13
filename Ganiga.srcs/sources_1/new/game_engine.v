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


module game_engine(
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
    output wire [4:0] enemies_alive,
    output wire [9:0] enemy_group_x,
    output wire [9:0] enemy_group_y
    );

    // Internal wires
    wire bullet_hit_ack; // ?????????????????????? Enemy ??? Bullet
    wire b_act_internal;
    wire [9:0] b_x_int, b_y_int;

    // 1. Player Control
    player_control #( .START_X(320), .START_Y(440), .SPEED(4) ) p_ctrl (
        .clk(clk), .rst_ni(rst_ni), .tick(tick),
        .btn_left(btn_left), .btn_right(btn_right),
        .x(player_x), .y(player_y)
    );

    // 2. Enemy Control (???? Speed ?????????)
    enemy_control #(
        .MOVE_DELAY(30), // ???????????-?????????? (??????? = ????)
        .STEP_X(1),      // ???????????????????
        .STEP_Y(10)      // ??????????
    ) e_ctrl (
        .clk(clk), .rst_ni(rst_ni), .tick(tick),
        .bullet_active(b_act_internal),
        .bullet_x(b_x_int),
        .bullet_y(b_y_int),
        .bullet_hit_ack(bullet_hit_ack), // ????????????????
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x),
        .group_y(enemy_group_y)
    );

    // 3. Bullet Logic
    bullet bullet_inst (
        .clk(clk), .rst_ni(rst_ni), .fire(btn_fire), .tick(tick),
        .hit(bullet_hit_ack),          // [NEW] ?????????????????
        .player_x(player_x), .player_y(player_y),
        .active(b_act_internal), 
        .bullet_x(b_x_int), .bullet_y(b_y_int)
    );
    
    // Output assignment
    assign bullet_active = b_act_internal; // ??????? mask ???? ????? active ?????????????????
    assign bullet_x = b_x_int;
    assign bullet_y = b_y_int;

endmodule