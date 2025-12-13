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
    
    // Player & Bullet
    output wire [9:0] player_x,
    output wire [9:0] player_y,
    output wire       bullet_active,
    output wire [9:0] bullet_x,
    output wire [9:0] bullet_y,

    // --- NEW: Enemy Signals ---
    output reg  [4:0] enemies_alive, 
    output reg  [9:0] enemy_group_x, 
    output reg  [9:0] enemy_group_y  
    );

    // --- Player Logic  ---
    reg [9:0] p_x, p_x_next;
    localparam P_Y = 400; 
    localparam P_SPEED = 3;
    
    assign player_x = p_x;
    assign player_y = P_Y;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) p_x <= 320; 
        else if (tick) p_x <= p_x_next;
    end
    
    always @* begin
        p_x_next = p_x;
        if (btn_left && p_x > P_SPEED) p_x_next = p_x - P_SPEED;
        else if (btn_right && p_x < (640 - 16 - P_SPEED)) p_x_next = p_x + P_SPEED;
    end


    wire b_act;
    wire [9:0] b_x, b_y;
    
    bullet bullet_inst (
        .clk(clk), .rst_ni(rst_ni), .fire(btn_fire), .tick(tick),
        .player_x(p_x), .player_y(P_Y),
        .active(b_act), .bullet_x(b_x), .bullet_y(b_y)
    );
    
 
    reg bullet_hit_enemy;
    assign bullet_active = b_act && !bullet_hit_enemy; 
    assign bullet_x = b_x;
    assign bullet_y = b_y;

    // --- NEW: Enemy Logic ---

    reg [5:0] move_timer;
    reg       move_dir; // 0: Right, 1: Left
    
    localparam ENEMY_START_X = 100;
    localparam ENEMY_START_Y = 50;
    localparam ENEMY_W = 32; 
    localparam ENEMY_H = 32; 
    localparam ENEMY_GAP = 16; 

    integer i;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            enemies_alive <= 5'b11111; 
            enemy_group_x <= ENEMY_START_X;
            enemy_group_y <= ENEMY_START_Y;
            move_timer    <= 0;
            move_dir      <= 0;
            bullet_hit_enemy <= 0;
        end else begin
            bullet_hit_enemy <= 0; // Reset hit flag

            // 1. Enemy Movement 
            if (tick) begin
                if (move_timer == 30) begin
                    move_timer <= 0;
                    
                    // Logic 
                    if (move_dir == 0) begin // Moving Right
                        if (enemy_group_x < 640 - (5*(ENEMY_W+ENEMY_GAP)) - 20)
                            enemy_group_x <= enemy_group_x + 10;
                        else begin
                            move_dir <= 1; 
                            enemy_group_y <= enemy_group_y + 20; // ??????
                        end
                    end else begin // Moving Left
                        if (enemy_group_x > 20)
                            enemy_group_x <= enemy_group_x - 10;
                        else begin
                            move_dir <= 0;
                            enemy_group_y <= enemy_group_y + 20; // ??????
                        end
                    end
                end else begin
                    move_timer <= move_timer + 1;
                end
            end

            // 2. Collision Detection (Bullet vs Enemy)
            if (b_act && !bullet_hit_enemy) begin
                for (i = 0; i < 5; i = i + 1) begin
                    
                    if (enemies_alive[i] && 
                        b_x + 2 >= (enemy_group_x + i*(ENEMY_W+ENEMY_GAP)) &&
                        b_x     <  (enemy_group_x + i*(ENEMY_W+ENEMY_GAP) + ENEMY_W) &&
                        b_y     >= enemy_group_y &&
                        b_y     <  enemy_group_y + ENEMY_H) 
                    begin
                        enemies_alive[i] <= 0; 
                        bullet_hit_enemy <= 1; 
                    end
                end
            end
        end
    end

endmodule
