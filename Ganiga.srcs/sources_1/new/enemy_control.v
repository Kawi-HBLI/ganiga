`timescale 1ns / 1ps

module enemy_control #(
    parameter START_X = 100,
    parameter START_Y = 50,
    parameter ENEMY_W = 24, 
    parameter ENEMY_H = 24, 
    parameter GAP     = 16,
    parameter COUNT   = 8, 
    
    parameter MOVE_DELAY = 5,
    parameter STEP_X     = 2,
    parameter STEP_Y     = 10
)(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,
    
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    output reg        bullet_hit_ack, 

    output reg        enemy_fire,
    output reg [9:0]  enemy_fire_x,
    output reg [9:0]  enemy_fire_y,

    output reg [7:0] enemies_alive, 
    output reg [9:0] group_x,
    output reg [9:0] group_y,
    output reg       victory
);
    reg [5:0] move_timer;
    
    reg [7:0] fire_timer;
    reg [7:0] lfsr;
    reg [2:0] fire_pick;
    integer i;
    
    localparam DIR_RIGHT = 3'd0;
    localparam DIR_LEFT  = 3'd1;
    localparam DIR_UP    = 3'd2;
    localparam DIR_DOWN  = 3'd3;
    localparam DIR_IDLE  = 3'd4;

    reg [2:0] move_mode;
    
    reg [1:0] wave_stage;
    reg [3:0] current_max;

    function [2:0] pick_alive_idx;
        input [2:0] start;
        input [7:0] alive;
        integer k;
        reg [2:0] idx;
        reg found;
        begin
            found = 1'b0;
            idx = (start >= COUNT) ? (start - COUNT) : start;
            pick_alive_idx = 3'd0;
            for (k = 0; k < COUNT; k = k + 1) begin
                if (!found && alive[idx]) begin
                    pick_alive_idx = idx;
                    found = 1'b1;
                end
                if (idx == COUNT-1) idx = 0;
                else                idx = idx + 1'b1;
            end
        end
    endfunction

    localparam integer FIRE_DELAY_MIN = 20;
    localparam integer FIRE_DELAY_MAX = 60;
    localparam integer ENEMY_CENTER_X_OFF = (ENEMY_W/2) - 2; 
    localparam integer ENEMY_MUZZLE_Y_OFF  = ENEMY_H;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive <= 8'h1F;
            current_max   <= 5;
            wave_stage    <= 0;
            victory       <= 0;

            group_x       <= 208;
            group_y       <= START_Y;
            move_timer    <= 0;
            bullet_hit_ack <= 0;
            enemy_fire    <= 1'b0;
            enemy_fire_x  <= 10'd0;
            enemy_fire_y  <= 10'd0;
            fire_timer    <= 8'd0;
            lfsr          <= 8'hA5;
            move_mode     <= DIR_RIGHT;
        end else begin
            bullet_hit_ack <= 0;
            enemy_fire     <= 1'b0;
            victory        <= 0;

            if (enemies_alive == 0 && wave_stage != 3) begin
                if (wave_stage == 0) begin
                    wave_stage    <= 1;
                    current_max   <= 7;
                    enemies_alive <= 8'h7F; 
                    group_x       <= 160; 
                end else if (wave_stage == 1) begin
                    wave_stage    <= 2;
                    current_max   <= 8;
                    enemies_alive <= 8'hFF;
                    group_x       <= 136;
                end else if (wave_stage == 2) begin
                    wave_stage    <= 3;
                    victory       <= 1;
                end
                
                if (wave_stage < 2) begin
                    group_y       <= START_Y;
                    move_timer    <= 0;
                    fire_timer    <= 8'd0;
                end
            end
            else if (tick && wave_stage != 3) begin
                lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};

                if (move_timer >= MOVE_DELAY) begin
                    move_timer <= 0;
                    case (lfsr[2:0])
                        3'd0, 3'd1, 3'd2: move_mode <= DIR_RIGHT;
                        3'd3, 3'd4, 3'd5: move_mode <= DIR_LEFT;
                        3'd6:             move_mode <= DIR_UP;
                        3'd7:             move_mode <= DIR_DOWN;
                    endcase

                    case (move_mode)
                        DIR_RIGHT: begin
                            if (group_x < 640 - (current_max*(ENEMY_W+GAP)) - 20)
                                group_x <= group_x + STEP_X;
                        end
                        DIR_LEFT: begin
                            if (group_x > 20)
                                group_x <= group_x - STEP_X;
                        end
                        DIR_UP: begin
                            if (group_y > 20)
                                group_y <= group_y - STEP_Y;
                        end
                        DIR_DOWN: begin
                            if (group_y < 480 - ENEMY_H - 20)
                                group_y <= group_y + STEP_Y;
                        end
                        DIR_IDLE: begin
                            group_x <= group_x;
                            group_y <= group_y;
                        end
                    endcase
                end else begin
                    move_timer <= move_timer + 1;
                end

                if (fire_timer >= (FIRE_DELAY_MIN + (lfsr % (FIRE_DELAY_MAX - FIRE_DELAY_MIN + 1)))) begin
                    fire_timer <= 8'd0;
                    if (enemies_alive != 0) begin
                        fire_pick = pick_alive_idx(lfsr[2:0], enemies_alive);
                        if (fire_pick < current_max) begin
                            enemy_fire   <= 1'b1;
                            enemy_fire_x <= group_x + fire_pick*(ENEMY_W+GAP) + ENEMY_CENTER_X_OFF;
                            enemy_fire_y <= group_y + ENEMY_MUZZLE_Y_OFF;
                        end
                    end
                end else begin
                    fire_timer <= fire_timer + 1'b1;
                end

                if (bullet_active && !bullet_hit_ack) begin
                    for (i = 0; i < COUNT; i = i + 1) begin
                        if (i < current_max && enemies_alive[i]) begin
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