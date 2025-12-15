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
    parameter MOVE_DELAY = 25, // ?????????????????? (???? 30 frames ??????)
    parameter STEP_X     = 10,  // ??????????? X (???? 1 pixel)
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

    // Enemy bullet spawn (1-shot pulse + spawn position)
    output reg        enemy_fire,
    output reg [9:0]  enemy_fire_x,
    output reg [9:0]  enemy_fire_y,

    // Output State
    output reg [4:0] enemies_alive,
    output reg [9:0] group_x,
    output reg [9:0] group_y
);

    reg [5:0] move_timer;
    reg       move_dir; // 0: Right, 1: Left
    // Enemy shooting
    reg [7:0] fire_timer;
    reg [7:0] lfsr;
    reg [2:0] fire_pick;
    integer i;

    // Pick the first alive enemy index starting from 'start' (wrap around).
    function [2:0] pick_alive_idx;
        input [2:0] start;
        input [4:0] alive;
        integer k;
        reg [2:0] idx;
        reg found;
        begin
            found = 1'b0;
            // ????? start ??????? COUNT (??????????? COUNT=5 ??? start ???? 0..7)
            idx = (start >= COUNT) ? (start - COUNT) : start;
    
            pick_alive_idx = 3'd0;
    
            for (k = 0; k < COUNT; k = k + 1) begin
                if (!found && alive[idx]) begin
                    pick_alive_idx = idx;
                    found = 1'b1;      // "?????????" ??????????????????????????
                end
    
                // ???? idx ???????? wrap
                if (idx == COUNT-1) idx = 0;
                else                idx = idx + 1'b1;
            end
        end
    endfunction

    // Tunables (frames @60Hz)
    localparam integer FIRE_DELAY_MIN = 30; // 0.5s
    localparam integer FIRE_DELAY_MAX = 90; // 1.5s
    localparam integer ENEMY_CENTER_X_OFF = (ENEMY_W/2);
    localparam integer ENEMY_MUZZLE_Y_OFF  = ENEMY_H;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive <= {COUNT{1'b1}}; // Set all 1s
            group_x       <= START_X;
            group_y       <= START_Y;
            move_timer    <= 0;
            move_dir      <= 0;
            bullet_hit_ack <= 0;
            enemy_fire    <= 1'b0;
            enemy_fire_x  <= 10'd0;
            enemy_fire_y  <= 10'd0;
            fire_timer    <= 8'd0;
            lfsr          <= 8'hA5;
        end else begin
            bullet_hit_ack <= 0; 
            enemy_fire     <= 1'b0;

            // --- [NEW] Respawn Logic ---
            if (enemies_alive == 0) begin
                enemies_alive <= {COUNT{1'b1}}; // ?????????????
                group_x       <= START_X;       // ???????????
                group_y       <= START_Y;
                move_timer    <= 0;
                move_dir      <= 0;
                fire_timer    <= 8'd0;
            end
            else if (tick) begin
                // LFSR update every tick (simple pseudo-random)
                lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

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

                // 1.5. Enemy fire (Galaga-ish: one random alive enemy fires downward)
                //     - enemy_fire is a 1-tick pulse
                //     - enemy_bullet module will ignore if it already has an active shot
                if (fire_timer >= (FIRE_DELAY_MIN + (lfsr % (FIRE_DELAY_MAX - FIRE_DELAY_MIN + 1)))) begin
                    fire_timer <= 8'd0;

                    // Pick a (pseudo)random alive enemy starting from lfsr%COUNT.
                    // (Function wraps around and returns the first alive index it sees.)
                    if (enemies_alive != 0) begin
                        // NOTE: COUNT is 5 in this project, so 3-bit is enough.
                        //       If you change COUNT > 8, widen the start index.
                        // Use blocking assignment so the same-cycle math uses the picked index.
                        fire_pick = pick_alive_idx(lfsr[2:0], enemies_alive);
                        enemy_fire   <= 1'b1;
                        enemy_fire_x <= group_x + fire_pick*(ENEMY_W+GAP) + ENEMY_CENTER_X_OFF;
                        enemy_fire_y <= group_y + ENEMY_MUZZLE_Y_OFF;
                    end
                end else begin
                    fire_timer <= fire_timer + 1'b1;
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

