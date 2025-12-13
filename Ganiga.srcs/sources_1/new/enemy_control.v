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
    parameter COUNT   = 5,
    
    // [NEW] Enemy Speed Parameters
    parameter MOVE_DELAY = 30, // ?????????????????? (???? 30 frames ??????)
    parameter STEP_X     = 1,  // ??????????? X (???? 1 pixel)
    parameter STEP_Y     = 10  // ??????????? Y ????????????? (???? 10 pixel)
)(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,
    
    // Bullet Interaction
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    output reg        bullet_hit_ack, // ?????????????? Bullet ????????

    // Output State
    output reg [4:0] enemies_alive,
    output reg [9:0] group_x,
    output reg [9:0] group_y
);

    reg [5:0] move_timer;
    reg       move_dir; // 0: Right, 1: Left
    integer i;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive <= {COUNT{1'b1}}; // Set all 1s
            group_x       <= START_X;
            group_y       <= START_Y;
            move_timer    <= 0;
            move_dir      <= 0;
            bullet_hit_ack <= 0;
        end else begin
            bullet_hit_ack <= 0; 

            // --- [NEW] Respawn Logic ---
            if (enemies_alive == 0) begin
                enemies_alive <= {COUNT{1'b1}}; // ?????????????
                group_x       <= START_X;       // ???????????
                group_y       <= START_Y;
                move_timer    <= 0;
                move_dir      <= 0;
            end
            else if (tick) begin
                // 1. Movement Logic (??? Parameter ???????????)
                if (move_timer >= MOVE_DELAY) begin
                    move_timer <= 0;
                    if (move_dir == 0) begin // Moving Right
                        if (group_x < 640 - (COUNT*(ENEMY_W+GAP)) - 20)
                            group_x <= group_x + STEP_X;
                        else begin
                            move_dir <= 1;
                            group_y  <= group_y + STEP_Y;
                        end
                    end else begin // Moving Left
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

                // 2. Collision Detection
                if (bullet_active && !bullet_hit_ack) begin
                    for (i = 0; i < COUNT; i = i + 1) begin
                        if (enemies_alive[i]) begin
                            if (bullet_x + 2 >= (group_x + i*(ENEMY_W+GAP)) &&
                                bullet_x     <  (group_x + i*(ENEMY_W+GAP) + ENEMY_W) &&
                                bullet_y     >= group_y &&
                                bullet_y     <  group_y + ENEMY_H) 
                            begin
                                enemies_alive[i] <= 0;
                                bullet_hit_ack   <= 1; // ????????????????
                            end
                        end
                    end
                end
            end
        end
    end

endmodule