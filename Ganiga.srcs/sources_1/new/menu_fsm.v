`timescale 1ns / 1ps

// menu_fsm.v
// Reset => MENU. Press FIRE => PLAY.
// PLAY => GAMEOVER when player_hit.
// GAMEOVER => PLAY when FIRE pressed.
module menu_fsm(
    input  wire clk,
    input  wire rst_ni,
    input  wire btn_fire,
    input  wire player_hit,
    output wire [1:0] game_state,
    output wire       game_playing,
    output wire       game_over
);
    localparam [1:0] ST_MENU = 2'd0;
    localparam [1:0] ST_PLAY = 2'd1;
    localparam [1:0] ST_OVER = 2'd2;

    reg [1:0] state;
    reg       fire_prev;
    reg       hit_latched;

    wire fire_rise = btn_fire & ~fire_prev;

    always @(posedge clk) begin
        if (!rst_ni) begin
            state       <= ST_MENU;
            fire_prev   <= 1'b0;
            hit_latched <= 1'b0;
        end else begin
            // Edge detect FIRE
            fire_prev <= btn_fire;

            // Latch hit so we can't miss it (player_hit can be 1-cycle pulse)
            if (state == ST_PLAY && player_hit)
                hit_latched <= 1'b1;

            case (state)
                ST_MENU: begin
                    hit_latched <= 1'b0;
                    if (fire_rise) state <= ST_PLAY;
                end

                ST_PLAY: begin
                    if (hit_latched) state <= ST_OVER;
                end

                ST_OVER: begin
                    hit_latched <= 1'b0;
                    if (fire_rise) state <= ST_PLAY; // restart
                end

                default: begin
                    state       <= ST_MENU;
                    hit_latched <= 1'b0;
                end
            endcase
        end
    end

    assign game_state   = state;
    assign game_playing = (state == ST_PLAY);
    assign game_over    = (state == ST_OVER);

endmodule