`timescale 1ns / 1ps

module renderer(
    input  wire       clk,
    input  wire       blank,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [1:0] game_state,
    input  wire       game_playing,
    input  wire       game_over,
    input  wire       game_won, 
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    
    // Enemy Bullets (3 slots)
    input  wire       eb1_active, input wire [9:0] eb1_x, input wire [9:0] eb1_y,
    input  wire       eb2_active, input wire [9:0] eb2_x, input wire [9:0] eb2_y,
    input  wire       eb3_active, input wire [9:0] eb3_x, input wire [9:0] eb3_y,

    input  wire [7:0] enemies_alive, 
    input  wire [9:0] enemy_group_x,
    input  wire [9:0] enemy_group_y,
    output reg  [3:0] r,
    output reg  [3:0] g,
    output reg  [3:0] b
);

    reg [15:0] frame_cnt;
    always @(posedge clk) begin
        if (!blank && x==0 && y==0) frame_cnt <= frame_cnt + 1'b1;
    end

    
    // Map Layer
    wire [3:0] map_r, map_g, map_b;
    wire       map_is_wall;
    tile_map map_inst (.x(x), .y(y), .r(map_r), .g(map_g), .b(map_b), .is_wall(map_is_wall));

    // Player Layer
    wire px_player;
    wire [3:0] p_r, p_g, p_b;
    player_sprite spr_player(
        .clk(clk), .x(x), .y(y),
        .player_x(player_x), .player_y(player_y),
        .px_on(px_player), .r(p_r), .g(p_g), .b(p_b)
    );

    // Enemy Layer
    wire px_enemy;
    wire [3:0] e_r, e_g, e_b;
    enemy_sprite spr_enemy(
        .clk(clk), .x(x), .y(y),
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x), .group_y(enemy_group_y),
        .px_on(px_enemy), .r(e_r), .g(e_g), .b(e_b)
    );

    // Bullet Logic
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    localparam EB_W     = 4; 
    localparam EB_H     = 8; 
    wire px_bullet = bullet_active && (x >= bullet_x) && (x < bullet_x + BULLET_W) && (y >= bullet_y) && (y < bullet_y + BULLET_H);
    wire px_eb1 = eb1_active && (x >= eb1_x) && (x < eb1_x + EB_W) && (y >= eb1_y) && (y < eb1_y + EB_H);
    wire px_eb2 = eb2_active && (x >= eb2_x) && (x < eb2_x + EB_W) && (y >= eb2_y) && (y < eb2_y + EB_H);
    wire px_eb3 = eb3_active && (x >= eb3_x) && (x < eb3_x + EB_W) && (y >= eb3_y) && (y < eb3_y + EB_H);
    wire px_enemy_bullet = px_eb1 | px_eb2 | px_eb3;

    wire [3:0] m_r, m_g, m_b;
    screen_menu s_menu (.clk(clk), .x(x), .y(y), .frame_cnt(frame_cnt), .r(m_r), .g(m_g), .b(m_b));

    wire [3:0] go_r, go_g, go_b;
    screen_game_over s_over (.clk(clk), .x(x), .y(y), .frame_cnt(frame_cnt), .r(go_r), .g(go_g), .b(go_b));

    wire [3:0] w_r, w_g, w_b;
    screen_win s_win (.clk(clk), .x(x), .y(y), .frame_cnt(frame_cnt), .r(w_r), .g(w_g), .b(w_b));


    always @(*) begin
        r = 0; g = 0; b = 0;
        if (blank) begin
            r = 0; g = 0; b = 0;
        end else begin
            case(game_state)
                2'd0: begin 
                    r = m_r; g = m_g; b = m_b;
                end
                
                2'd1: begin 
                    if (px_player) begin
                        r = p_r; g = p_g; b = p_b;
                    end else if (px_bullet) begin
                        r = 4'hF; g = 4'hF; b = 4'hF;
                    end else if (px_enemy_bullet) begin
                        r = 4'hF; g = 4'h0; b = 4'h0;
                    end else if (px_enemy) begin
                        r = e_r; g = e_g; b = e_b;
                    end else begin
                        r = map_r; g = map_g; b = map_b;
                    end
                end
                
                2'd2: begin 
                    r = go_r; g = go_g; b = go_b;
                end
                
                2'd3: begin 
                    r = w_r; g = w_g; b = w_b;
                end
            endcase
        end
    end

endmodule