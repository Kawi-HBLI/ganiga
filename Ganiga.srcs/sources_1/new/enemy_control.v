`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 11:48:08 AM
// Design Name: 
// Module Name: enemy_control
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
module enemy_control #(
    parameter START_X = 100,
    parameter START_Y = 50,
    parameter ENEMY_W = 32,
    parameter ENEMY_H = 32,
    parameter GAP     = 16,

    parameter MOVE_DELAY = 30,
    parameter STEP_X     = 1,
    parameter STEP_Y     = 10,

    parameter GAME_OVER_Y = 440
)(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,

    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    output reg        bullet_hit_ack,

    output reg [4:0] enemies_alive,
    output reg [9:0] group_x,
    output reg [9:0] group_y,
    output reg       game_over
);

    reg [7:0] move_timer;
    reg       move_dir; // 0:Right, 1:Left
    integer i;

    wire any_alive = |enemies_alive;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive  <= 5'b11111;
            group_x        <= START_X;
            group_y        <= START_Y;
            move_timer     <= 0;
            move_dir       <= 0;
            bullet_hit_ack <= 0;
            game_over      <= 0;
        end else begin
            bullet_hit_ack <= 0;

            if (!game_over && any_alive && (group_y + ENEMY_H >= GAME_OVER_Y))
                game_over <= 1;

            if (tick && !game_over) begin
                if (move_timer == MOVE_DELAY) begin
                    move_timer <= 0;
                    if (move_dir == 0) begin
                        if (group_x < 640 - (5*(ENEMY_W+GAP)) - 20)
                            group_x <= group_x + STEP_X;
                        else begin
                            move_dir <= 1;
                            group_y  <= group_y + STEP_Y;
                        end
                    end else begin
                        if (group_x > 20)
                            group_x <= group_x - STEP_X;
                        else begin
                            move_dir <= 0;
                            group_y  <= group_y + STEP_Y;
                        end
                    end
                end else begin
                    move_timer <= move_timer + 1;
                end

                if (bullet_active) begin
                    for (i = 0; i < 5; i = i + 1) begin
                        if (!bullet_hit_ack && enemies_alive[i]) begin
                            if (bullet_x + 2 >= (group_x + i*(ENEMY_W+GAP)) &&
                                bullet_x     <  (group_x + i*(ENEMY_W+GAP) + ENEMY_W) &&
                                bullet_y     >= group_y &&
                                bullet_y     <  group_y + ENEMY_H)
                            begin
                                enemies_alive[i] <= 0;
                                bullet_hit_ack   <= 1;
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
