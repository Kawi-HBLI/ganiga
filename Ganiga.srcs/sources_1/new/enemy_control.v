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
    parameter START_X = 100, // [cite: 75]
    parameter START_Y = 50,  // [cite: 75]
    parameter ENEMY_W = 32,  // [cite: 71]
    parameter ENEMY_H = 32,
    parameter GAP     = 16
)(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,
    
    // Bullet Info for collision
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    output reg        bullet_hit_ack,

    // State Output
    output reg [4:0] enemies_alive,
    output reg [9:0] group_x,
    output reg [9:0] group_y
);

    reg [5:0] move_timer;
    reg       move_dir; // 0:Right, 1:Left
    integer i;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive <= 5'b11111;
            group_x       <= START_X;
            group_y       <= START_Y;
            move_timer    <= 0;
            move_dir      <= 0;
            bullet_hit_ack <= 0;
        end else begin
            bullet_hit_ack <= 0; // Reset every clock

            if (tick) begin
                // --- Movement Logic (Copy from top_module [cite: 86-93]) ---
                if (move_timer == 30) begin
                    move_timer <= 0;
                    if (move_dir == 0) begin // Moving Right
                        if (group_x < 640 - (5*(ENEMY_W+GAP)) - 20)
                            group_x <= group_x + 1; // [cite: 87] Original uses +1
                        else begin
                            move_dir <= 1;
                            group_y  <= group_y + 10; // [cite: 89] Original uses +10
                        end
                    end else begin // Moving Left
                        if (group_x > 20)
                            group_x <= group_x - 1; // [cite: 90] Original uses -1
                        else begin
                            move_dir <= 0;
                            group_y  <= group_y + 10; // [cite: 92] Original uses +10
                        end
                    end
                end else begin
                    move_timer <= move_timer + 1;
                end

                // --- Collision Logic (Copy from top_module [cite: 94-98]) ---
                if (bullet_active && !bullet_hit_ack) begin
                    for (i = 0; i < 5; i = i + 1) begin
                        if (enemies_alive[i]) begin
                            // Check AABB Collision
                            if (bullet_x + 2 >= (group_x + i*(ENEMY_W+GAP)) &&
                                bullet_x     <  (group_x + i*(ENEMY_W+GAP) + ENEMY_W) &&
                                bullet_y     >= group_y &&
                                bullet_y     <  group_y + ENEMY_H) 
                            begin
                                enemies_alive[i] <= 0;
                                bullet_hit_ack   <= 1; // Tell engine to destroy bullet
                            end
                        end
                    end
                end
            end
        end
    end

endmodule