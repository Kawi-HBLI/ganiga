`timescale 1ns / 1ps

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
    
    output wire       eb1_active, output wire [9:0] eb1_x, output wire [9:0] eb1_y,
    output wire       eb2_active, output wire [9:0] eb2_x, output wire [9:0] eb2_y,
    output wire       eb3_active, output wire [9:0] eb3_x, output wire [9:0] eb3_y,

    // Game State Outputs
    output wire [7:0] enemies_alive, 
    output wire [9:0] enemy_group_x,
    output wire [9:0] enemy_group_y,
    output wire [1:0] game_state,
    output wire       game_playing,
    output wire       game_over,
    output wire       game_won
);

    wire player_hit;
    wire player_victory;
    

    wire rst_game_ni = rst_ni & game_playing;
    wire fire_game   = btn_fire & game_playing;


    wire b_act_raw;
    wire [9:0] b_x_raw, b_y_raw;
    wire bullet_hit_ack;


    wire enemy_fire;
    wire [9:0] enemy_fire_x, enemy_fire_y;


    menu_fsm u_menu(
        .clk(clk),
        .rst_ni(rst_ni),
        .btn_fire(btn_fire),
        .player_hit(player_hit),     
        .player_won(player_victory), 
        .game_state(game_state),
        .game_playing(game_playing),
        .game_over(game_over),
        .game_won(game_won)
    );


    player_control #(
        .START_X(320),
        .START_Y(440),
        .SPEED(4)
    ) p_ctrl (
        .clk(clk), .rst_ni(rst_game_ni), .tick(tick),
        .btn_left(btn_left), .btn_right(btn_right),
        .x(player_x), .y(player_y)
    );

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
        .group_y(enemy_group_y),
        .victory(player_victory) 
    );

    bullet bullet_inst (
        .clk(clk), .rst_ni(rst_game_ni), .fire(fire_game), .tick(tick),
        .hit(bullet_hit_ack),
        .player_x(player_x), .player_y(player_y),
        .active(b_act_raw),
        .bullet_x(b_x_raw), .bullet_y(b_y_raw)
    );

    assign bullet_active = b_act_raw && !bullet_hit_ack;
    assign bullet_x      = b_x_raw;
    assign bullet_y      = b_y_raw;

    enemy_bullet_manager #(
        .BULLET_W(4), .BULLET_H(8), .SPEED_Y(8), .SCREEN_H(480)
    ) eb_manager (
        .clk(clk), .rst_ni(rst_game_ni), .tick(tick),
        .enemy_fire(enemy_fire),
        .spawn_x(enemy_fire_x),
        .spawn_y(enemy_fire_y),
        .player_x(player_x),
        .player_y(player_y),
        .eb1_active(eb1_active), .eb1_x(eb1_x), .eb1_y(eb1_y),
        .eb2_active(eb2_active), .eb2_x(eb2_x), .eb2_y(eb2_y),
        .eb3_active(eb3_active), .eb3_x(eb3_x), .eb3_y(eb3_y),
        .player_hit(player_hit)
    );

endmodule