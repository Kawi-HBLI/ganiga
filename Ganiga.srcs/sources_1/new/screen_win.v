`timescale 1ns / 1ps

module screen_win(
    input  wire clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [15:0] frame_cnt,
    output reg  [3:0] r, g, b
);
    wire star_on  = ((x[3]^y[4]) & (x[7]^y[6]) & ~x[1]);
    wire blink_on = frame_cnt[5];

    localparam integer WIN_SCALE = 8; // ????????
    localparam integer WIN_W     = 2 * 8 * WIN_SCALE; // "GG"
    localparam integer WIN_H     = 8 * WIN_SCALE;
    localparam integer WIN_X0    = (640 - WIN_W)/2;
    localparam integer WIN_Y0    = 140;

    localparam integer PROMPT_SCALE = 2;
    localparam integer PROMPT_W     = 15 * 8 * PROMPT_SCALE;
    localparam integer PROMPT_H     = 8 * PROMPT_SCALE;
    localparam integer PROMPT_X0    = (640 - PROMPT_W)/2;
    localparam integer PROMPT_Y0    = 360;

    function [7:0] prompt_char(input [4:0] idx);
        case(idx)
            0: prompt_char="<"; 1: prompt_char="F"; 2: prompt_char="I"; 3: prompt_char="R"; 4: prompt_char="E";
            5: prompt_char=">"; 6: prompt_char=" "; 7: prompt_char="T"; 8: prompt_char="O"; 9: prompt_char=" ";
            10:prompt_char="R"; 11:prompt_char="E"; 12:prompt_char="S"; 13:prompt_char="T"; 14:prompt_char="!";
            default: prompt_char=" ";
        endcase
    endfunction

    wire in_win = (x>=WIN_X0) && (x<WIN_X0+WIN_W) && (y>=WIN_Y0) && (y<WIN_Y0+WIN_H);
    wire [9:0] w_dx = x - WIN_X0;
    wire [9:0] w_dy = y - WIN_Y0;
    wire [2:0] w_col = (w_dx / WIN_SCALE) % 8;
    wire [2:0] w_row = (w_dy / WIN_SCALE) % 8;
    wire [7:0] w_bits;
    font8x8_rom f_win(.ch("G"), .row(w_row), .bits(w_bits)); // GG
    wire win_on = in_win && w_bits[7 - w_col];

    wire in_p = (x>=PROMPT_X0) && (x<PROMPT_X0+PROMPT_W) && (y>=PROMPT_Y0) && (y<PROMPT_Y0+PROMPT_H);
    wire [9:0] p_dx = x - PROMPT_X0;
    wire [9:0] p_dy = y - PROMPT_Y0;
    wire [4:0] p_ci = p_dx / (8*PROMPT_SCALE);
    wire [2:0] p_col = (p_dx / PROMPT_SCALE) % 8;
    wire [2:0] p_row = (p_dy / PROMPT_SCALE) % 8;
    wire [7:0] p_bits;
    font8x8_rom f_p(.ch(prompt_char(p_ci)), .row(p_row), .bits(p_bits));
    wire p_on = in_p && p_bits[7 - p_col] && blink_on;

    always @(*) begin
        if (win_on) begin
            r = 0; g = 4'hF; b = 0; // GREEN for GG
        end else if (p_on) begin
            r = 4'hF; g = 4'hF; b = 4'hF;
        end else if (star_on) begin
            r = 4'h2; g = 4'h2; b = 4'h2;
        end else begin
            r = 0; g = 0; b = 0;
        end
    end
endmodule