`timescale 1ns / 1ps

module screen_game_over(
    input  wire clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [15:0] frame_cnt,
    output reg  [3:0] r, g, b
);
    wire blink_on = frame_cnt[5];
    wire star_on  = ((x[3]^y[4]) & (x[7]^y[6]) & ~x[1]);

    localparam integer OVER_SCALE = 4;
    localparam integer OVER_W     = 9 * 8 * OVER_SCALE; // "GAME OVER"
    localparam integer OVER_H     = 8 * OVER_SCALE;
    localparam integer OVER_X0    = (640 - OVER_W)/2;
    localparam integer OVER_Y0    = 140;
    
    localparam integer OVERP_SCALE = 2;
    localparam integer OVERP_W     = 15 * 8 * OVERP_SCALE;
    localparam integer OVERP_H     = 8 * OVERP_SCALE;
    localparam integer OVERP_X0    = (640 - OVERP_W)/2;
    localparam integer OVERP_Y0    = 300;

    function [7:0] over_char(input [5:0] idx);
        case(idx)
            0: over_char="G"; 1: over_char="A"; 2: over_char="M"; 3: over_char="E"; 4: over_char=" ";
            5: over_char="O"; 6: over_char="V"; 7: over_char="E"; 8: over_char="R"; default: over_char=" ";
        endcase
    endfunction

    function [7:0] prompt_char(input [4:0] idx);
        case(idx)
            0: prompt_char="<"; 1: prompt_char="F"; 2: prompt_char="I"; 3: prompt_char="R"; 4: prompt_char="E";
            5: prompt_char=">"; 6: prompt_char=" "; 7: prompt_char="T"; 8: prompt_char="O"; 9: prompt_char=" ";
            10:prompt_char="R"; 11:prompt_char="E"; 12:prompt_char="T"; 13:prompt_char="R"; 14:prompt_char="Y";
            default: prompt_char=" ";
        endcase
    endfunction

    wire in_over = (x>=OVER_X0) && (x<OVER_X0+OVER_W) && (y>=OVER_Y0) && (y<OVER_Y0+OVER_H);
    wire [9:0] over_dx = x - OVER_X0;
    wire [9:0] over_dy = y - OVER_Y0;
    wire [3:0] over_ci = over_dx / (8*OVER_SCALE);
    wire [2:0] over_col = (over_dx / OVER_SCALE) % 8;
    wire [2:0] over_row = (over_dy / OVER_SCALE) % 8;
    wire [7:0] over_bits;
    font8x8_rom f_over(.ch(over_char(over_ci)), .row(over_row), .bits(over_bits));
    wire over_on = in_over && over_bits[7 - over_col];

    wire in_p = (x>=OVERP_X0) && (x<OVERP_X0+OVERP_W) && (y>=OVERP_Y0) && (y<OVERP_Y0+OVERP_H);
    wire [9:0] p_dx = x - OVERP_X0;
    wire [9:0] p_dy = y - OVERP_Y0;
    wire [4:0] p_ci = p_dx / (8*OVERP_SCALE);
    wire [2:0] p_col = (p_dx / OVERP_SCALE) % 8;
    wire [2:0] p_row = (p_dy / OVERP_SCALE) % 8;
    wire [7:0] p_bits;
    font8x8_rom f_p(.ch(prompt_char(p_ci)), .row(p_row), .bits(p_bits));
    wire p_on = in_p && p_bits[7 - p_col] && blink_on;

    always @(*) begin
        if (over_on) begin
            r = 4'hF; g = 0; b = 0; // RED
        end else if (p_on) begin
            r = 4'hF; g = 4'hF; b = 4'hF;
        end else if (star_on) begin
            r = 4'h2; g = 4'h2; b = 4'h2;
        end else begin
            r = 0; g = 0; b = 0;
        end
    end
endmodule