`timescale 1ns / 1ps

module screen_menu(
    input  wire clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [15:0] frame_cnt, 
    output reg  [3:0] r, g, b
);
   
    wire blink_on = frame_cnt[5];
    wire star_on  = ((x[3]^y[4]) & (x[7]^y[6]) & ~x[1]); // Background Effect

    localparam integer MENU_SCALE = 4;
    localparam integer MENU_W     = 6 * 8 * MENU_SCALE;
    localparam integer MENU_H     = 8 * MENU_SCALE;
    localparam integer MENU_X0    = (640 - MENU_W)/2;
    localparam integer MENU_Y0    = 120;
    
    localparam integer PROMPT_SCALE = 2;
    localparam integer PROMPT_W     = 15 * 8 * PROMPT_SCALE;
    localparam integer PROMPT_H     = 8 * PROMPT_SCALE;
    localparam integer PROMPT_X0    = (640 - PROMPT_W)/2;
    localparam integer PROMPT_Y0    = 300;

    function [7:0] menu_char(input [5:0] idx);
        case(idx)
            0: menu_char = "G"; 1: menu_char = "A"; 2: menu_char = "N";
            3: menu_char = "I"; 4: menu_char = "G"; 5: menu_char = "A";
            default: menu_char = " ";
        endcase
    endfunction

    function [7:0] prompt_char(input [4:0] idx);
        case(idx)
            0: prompt_char="<"; 1: prompt_char="F"; 2: prompt_char="I"; 3: prompt_char="R"; 4: prompt_char="E";
            5: prompt_char=">"; 6: prompt_char=" "; 7: prompt_char="T"; 8: prompt_char="O"; 9: prompt_char=" ";
            10:prompt_char="S"; 11:prompt_char="T"; 12:prompt_char="A"; 13:prompt_char="R"; 14:prompt_char="T";
            default: prompt_char=" ";
        endcase
    endfunction

    // Calculate position
    wire in_menu_box = (x>=MENU_X0) && (x<MENU_X0+MENU_W) && (y>=MENU_Y0) && (y<MENU_Y0+MENU_H);
    wire [9:0] menu_dx = x - MENU_X0;
    wire [9:0] menu_dy = y - MENU_Y0;
    wire [3:0] menu_ci = menu_dx / (8*MENU_SCALE);
    wire [2:0] menu_col = (menu_dx / MENU_SCALE) % 8;
    wire [2:0] menu_row = (menu_dy / MENU_SCALE) % 8;
    wire [7:0] menu_bits0, menu_bits_up, menu_bits_dn;
    
    font8x8_rom f_menu0(.ch(menu_char(menu_ci)), .row(menu_row), .bits(menu_bits0));
    // (??????? Neighbor check ????????????????????????????? ????????????)
    wire menu_on = in_menu_box && menu_bits0[7 - menu_col];

    wire in_prompt_box = (x>=PROMPT_X0) && (x<PROMPT_X0+PROMPT_W) && (y>=PROMPT_Y0) && (y<PROMPT_Y0+PROMPT_H);
    wire [9:0] pr_dx = x - PROMPT_X0;
    wire [9:0] pr_dy = y - PROMPT_Y0;
    wire [4:0] pr_ci = pr_dx / (8*PROMPT_SCALE);
    wire [2:0] pr_col = (pr_dx / PROMPT_SCALE) % 8;
    wire [2:0] pr_row = (pr_dy / PROMPT_SCALE) % 8;
    wire [7:0] pr_bits;
    
    font8x8_rom f_prompt(.ch(prompt_char(pr_ci)), .row(pr_row), .bits(pr_bits));
    wire prompt_on = in_prompt_box && pr_bits[7 - pr_col] && blink_on;

    // Gradient Color
    reg [3:0] menu_fill_g;
    always @(*) begin
        case (menu_dy[9:3])
            0: menu_fill_g = 4'hF; 1: menu_fill_g = 4'hD;
            2: menu_fill_g = 4'hA; default: menu_fill_g = 4'h7;
        endcase
    end

    always @(*) begin
        if (menu_on) begin
            r = 4'hF; g = menu_fill_g; b = 4'h0;
        end else if (prompt_on) begin
            r = 4'hF; g = 4'hF; b = 4'hF;
        end else if (star_on) begin
            r = 4'h2; g = 4'h2; b = 4'h2;
        end else begin
            r = 0; g = 0; b = 0;
        end
    end
endmodule