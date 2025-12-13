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
    parameter ENEMY_MOVE_DELAY  = 30,
    parameter ENEMY_STEP_X      = 1,
    parameter ENEMY_STEP_Y      = 10,
    parameter ENEMY_GAME_OVER_Y = 440
)(
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
    output wire [9:0] enemy_group_y,

    output wire       game_playing,   // 1 = PLAY
    output wire       game_over,      // 1 = GAME OVER screen
    output reg  [3:0] score_h,        // BCD hundreds
    output reg  [3:0] score_t,        // BCD tens
    output reg  [3:0] score_o         // BCD ones
);

    // 0 MENU, 1 PLAY, 2 OVER
    reg [1:0] state;
    localparam ST_MENU = 2'd0;
    localparam ST_PLAY = 2'd1;
    localparam ST_OVER = 2'd2;

    assign game_playing = (state == ST_PLAY);
    assign game_over    = (state == ST_OVER);

    // gate submodules so they reset outside PLAY
    wire sub_rst_ni = rst_ni && (state == ST_PLAY);

    // player
    player_control u_player(
        .clk(clk),
        .rst_ni(sub_rst_ni),
        .tick(tick),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .player_x(player_x),
        .player_y(player_y)
    );

    // bullet
    wire bullet_hit_ack;
    bullet u_bullet(
        .clk(clk),
        .rst_ni(sub_rst_ni),
        .tick(tick),
        .fire(btn_fire),
        .player_x(player_x),
        .player_y(player_y),
        .hit(bullet_hit_ack),
        .active(bullet_active),
        .x(bullet_x),
        .y(bullet_y)
    );

    // enemies
    wire enemy_go;
    enemy_control #(
        .MOVE_DELAY (ENEMY_MOVE_DELAY),
        .STEP_X     (ENEMY_STEP_X),
        .STEP_Y     (ENEMY_STEP_Y),
        .GAME_OVER_Y(ENEMY_GAME_OVER_Y)
    ) u_enemy(
        .clk(clk),
        .rst_ni(sub_rst_ni),
        .tick(tick),
        .bullet_active(bullet_active),
        .bullet_x(bullet_x),
        .bullet_y(bullet_y),
        .bullet_hit_ack(bullet_hit_ack),
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x),
        .group_y(enemy_group_y),
        .game_over(enemy_go)
    );

    // BCD add +5
    reg [3:0] nh, nt, no;

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            state   <= ST_MENU;
            score_h <= 0;
            score_t <= 0;
            score_o <= 0;
        end else begin
            // ---------- state transitions ----------
            case (state)
                ST_MENU: begin
                    if (btn_fire) begin
                        state   <= ST_PLAY;
                        score_h <= 0; score_t <= 0; score_o <= 0;
                    end
                end

                ST_PLAY: begin
                    if (enemy_go) begin
                        state <= ST_OVER;
                    end
                end

                ST_OVER: begin
                    if (btn_fire) begin
                        state   <= ST_PLAY;
                        score_h <= 0; score_t <= 0; score_o <= 0;
                    end
                end
            endcase

            // ---------- score update (PLAY only) ----------
            if (state == ST_PLAY && bullet_hit_ack) begin
                // start from current
                nh = score_h;
                nt = score_t;
                no = score_o;

                // ones += 5
                if (no <= 4) begin
                    no = no + 4'd5;
                end else begin
                    no = no - 4'd5; // carry
                    // tens += 1
                    if (nt == 9) begin
                        nt = 0;
                        if (nh != 9) nh = nh + 1;
                        else nh = 9; // clamp at 999
                    end else begin
                        nt = nt + 1;
                    end
                end

                score_h <= nh;
                score_t <= nt;
                score_o <= no;
            end
        end
    end
endmodule
