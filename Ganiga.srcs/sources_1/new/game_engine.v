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
    // Enemy speed knobs (passed down into enemy_control)
    parameter integer ENEMY_MOVE_DELAY   = 30,  // bigger = slower
    parameter integer ENEMY_STEP_X       = 1,
    parameter integer ENEMY_STEP_Y       = 10,
    parameter integer ENEMY_GAME_OVER_Y  = 440
)(
    input  wire        clk,
    input  wire        rst_ni,
    input  wire        tick,        // 60Hz
    input  wire        btn_left,
    input  wire        btn_right,
    input  wire        btn_fire,

    output wire [9:0]  player_x,
    output wire [9:0]  player_y,
    output wire        bullet_active,
    output wire [9:0]  bullet_x,
    output wire [9:0]  bullet_y,

    output wire [4:0]  enemies_alive,
    output wire [9:0]  enemy_group_x,
    output wire [9:0]  enemy_group_y,

    output wire        game_playing,
    output wire        game_over,

    // score digits (BCD, 0..9 each)
    output reg  [3:0]  score_h,
    output reg  [3:0]  score_t,
    output reg  [3:0]  score_o
);

    // ---------------------------
    // FSM
    // ---------------------------
    localparam [1:0] ST_MENU = 2'd0,
                     ST_PLAY = 2'd1,
                     ST_OVER = 2'd2;

    reg [1:0] state, state_n;

    assign game_playing = (state == ST_PLAY);

    // Start/restart when FIRE pressed
    wire start_pulse = btn_fire;

    // ---------------------------
    // Submodule reset gating
    // - outside PLAY: keep game logic reset so it starts clean
    // ---------------------------
    wire logic_rst_ni = rst_ni & (state == ST_PLAY);

    // ---------------------------
    // Player
    // ---------------------------
    player_control u_player (
        .clk   (clk),
        .rst_ni(logic_rst_ni),
        .tick  (tick),
        .btn_left  (btn_left),
        .btn_right (btn_right),
        .x(player_x),
        .y(player_y)
    );

    // ---------------------------
    // Bullet
    // ---------------------------
    wire bullet_hit_ack;

    bullet u_bullet (
        .clk   (clk),
        .rst_ni(logic_rst_ni),
        .tick  (tick),
        .fire  (btn_fire),
        .hit   (bullet_hit_ack),     // IMPORTANT: bullet disappears on hit
        .player_x(player_x),
        .player_y(player_y),
        .active(bullet_active),
        .bullet_x(bullet_x),
        .bullet_y(bullet_y)
    );

    // ---------------------------
    // Enemy control + collision
    // ---------------------------
    wire enemy_go;

    enemy_control #(
        .MOVE_DELAY (ENEMY_MOVE_DELAY),
        .STEP_X     (ENEMY_STEP_X),
        .STEP_Y     (ENEMY_STEP_Y),
        .GAME_OVER_Y(ENEMY_GAME_OVER_Y)
    ) u_enemy (
        .clk   (clk),
        .rst_ni(logic_rst_ni),
        .tick  (tick),

        .bullet_active(bullet_active),
        .bullet_x     (bullet_x),
        .bullet_y     (bullet_y),

        .bullet_hit_ack(bullet_hit_ack),

        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x),
        .group_y(enemy_group_y),
        .game_over(enemy_go)
    );

    assign game_over = (state == ST_OVER);

    // ---------------------------
    // FSM next-state
    // ---------------------------
    always @(*) begin
        state_n = state;
        case (state)
            ST_MENU: begin
                if (start_pulse) state_n = ST_PLAY;
            end
            ST_PLAY: begin
                if (enemy_go) state_n = ST_OVER;
            end
            ST_OVER: begin
                if (start_pulse) state_n = ST_PLAY;
            end
            default: state_n = ST_MENU;
        endcase
    end

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) state <= ST_MENU;
        else        state <= state_n;
    end

    // ---------------------------
    // Score (BCD) : +5 on each bullet hit
    // Reset score when entering PLAY from MENU or OVER
    // ---------------------------
    wire enter_play = (state != ST_PLAY) && (state_n == ST_PLAY);

    // helper: add 5 to BCD (000..999)
    task automatic add5_bcd;
        inout reg [3:0] h;
        inout reg [3:0] t;
        inout reg [3:0] o;
        reg [4:0] tmp;
        begin
            // add to ones
            tmp = {1'b0,o} + 5;
            if (tmp >= 10) begin
                o = tmp - 10;
                // carry to tens
                tmp = {1'b0,t} + 1;
                if (tmp >= 10) begin
                    t = tmp - 10;
                    // carry to hundreds
                    tmp = {1'b0,h} + 1;
                    if (tmp >= 10) h = 9; // saturate at 999
                    else h = tmp[3:0];
                end else t = tmp[3:0];
            end else o = tmp[3:0];
        end
    endtask

    always @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            score_h <= 0;
            score_t <= 0;
            score_o <= 0;
        end else begin
            if (enter_play) begin
                score_h <= 0;
                score_t <= 0;
                score_o <= 0;
            end else if (state == ST_PLAY) begin
                if (tick && bullet_hit_ack) begin
                    // +5 per enemy hit
                    add5_bcd(score_h, score_t, score_o);
                end
            end
        end
    end

endmodule
