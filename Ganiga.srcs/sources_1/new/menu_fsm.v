`timescale 1ns / 1ps

// menu_fsm_user.v
// Reset => MENU. Press FIRE => PLAY.
module menu_fsm(
    input  wire clk,
    input  wire rst_ni,
    input  wire tick,
    input  wire btn_fire,
    input  wire player_hit,
    output wire game_playing
);
    localparam ST_MENU = 1'b0;
    localparam ST_PLAY = 1'b1;

    reg state;
    always @(posedge clk) begin
        if (!rst_ni) begin
            state <= ST_MENU;
        end else if (tick) begin
            // MENU -> PLAY when FIRE pressed
            if (state==ST_MENU && btn_fire) state <= ST_PLAY;

            // PLAY -> MENU when player is hit (simple "game over")
            if (state==ST_PLAY && player_hit) state <= ST_MENU;
        end
    end

    assign game_playing = (state==ST_PLAY);
endmodule