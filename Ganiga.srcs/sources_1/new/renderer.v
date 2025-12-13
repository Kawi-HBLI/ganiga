`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 11:50:17 AM
// Design Name: 
// Module Name: renderer
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


module renderer(
    input  wire       clk,
    input  wire       blank,
    input  wire [9:0] x,
    input  wire [9:0] y,

    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    input  wire [4:0] enemies_alive,
    input  wire [9:0] enemy_group_x,
    input  wire [9:0] enemy_group_y,

    // UI
    input  wire       game_playing,
    input  wire       game_over,
    input  wire [3:0] score_h,
    input  wire [3:0] score_t,
    input  wire [3:0] score_o,

    output reg  [3:0] r, g, b
);

    // ---------- sprites ----------
    // Player sprite
    wire px_player;
    wire [3:0] p_r, p_g, p_b;
    player_sprite u_player_sprite(
        .x(x), .y(y),
        .player_x(player_x), .player_y(player_y),
        .px_on(px_player),
        .r(p_r), .g(p_g), .b(p_b)
    );

    // Bullet (simple rect)
    wire px_bullet = bullet_active &&
                     (x >= bullet_x && x < bullet_x + 2) &&
                     (y >= bullet_y && y < bullet_y + 8);

    // Enemy sprite
    wire px_enemy;
    wire [3:0] e_r, e_g, e_b;
    enemy_sprite u_enemy_sprite(
        .x(x), .y(y),
        .group_x(enemy_group_x),
        .group_y(enemy_group_y),
        .enemies_alive(enemies_alive),
        .px_on(px_enemy),
        .r(e_r), .g(e_g), .b(e_b)
    );

    // ---------- blink (toggle ~0.5s) using frame start ----------
    reg [5:0] frame_cnt = 0;
    always @(posedge clk) begin
        if (!blank && x==0 && y==0) frame_cnt <= frame_cnt + 1;
    end
    wire blink = frame_cnt[5];

    // ---------- font ----------
    wire [7:0] font_bits;
    reg  [7:0] font_ch;
    reg  [2:0] font_row;

    font8x8_rom U_FONT(.ch(font_ch), .row(font_row), .bits(font_bits));

    // helper: select char for MENU (len=4)
    function [7:0] menu_char(input [2:0] idx);
        begin
            case(idx)
                0: menu_char = "M";
                1: menu_char = "E";
                2: menu_char = "N";
                3: menu_char = "U";
                default: menu_char = " ";
            endcase
        end
    endfunction

    function [7:0] gameover_char(input [3:0] idx); // "GAME OVER" len=9 incl space
        begin
            case(idx)
                0: gameover_char="G";
                1: gameover_char="A";
                2: gameover_char="M";
                3: gameover_char="E";
                4: gameover_char=" ";
                5: gameover_char="O";
                6: gameover_char="V";
                7: gameover_char="E";
                8: gameover_char="R";
                default: gameover_char=" ";
            endcase
        end
    endfunction

    function [7:0] start_char(input [4:0] idx); // "<FIRE> TO START" len=14
        begin
            case(idx)
                0: start_char="<";
                1: start_char="F";
                2: start_char="I";
                3: start_char="R";
                4: start_char="E";
                5: start_char=">";
                6: start_char=" ";
                7: start_char="T";
                8: start_char="O";
                9: start_char=" ";
                10:start_char="S";
                11:start_char="T";
                12:start_char="A";
                13:start_char="R";
                14:start_char="T";
                default: start_char=" ";
            endcase
        end
    endfunction

    function [7:0] score_char(input [3:0] idx); // "SCORE " + 3 digits => len=9
        begin
            case(idx)
                0: score_char="S";
                1: score_char="C";
                2: score_char="O";
                3: score_char="R";
                4: score_char="E";
                5: score_char=" ";
                6: score_char = "0" + score_h;
                7: score_char = "0" + score_t;
                8: score_char = "0" + score_o;
                default: score_char=" ";
            endcase
        end
    endfunction

    // generic draw string (combinational): returns 1 if current pixel is on
    function draw_string;
        input [9:0] x0;
        input [9:0] y0;
        input [5:0] len;
        input [2:0] scale; // 1..7
        input [1:0] which; // 0=MENU,1=GAMEOVER,2=START,3=SCORE
        reg [9:0] dx, dy;
        reg [9:0] gx, gy;
        reg [5:0] ci;
        reg [2:0] row, col;
        reg [7:0] ch;
        begin
            draw_string = 1'b0;
            if (x >= x0 && x < x0 + len*(8*scale) &&
                y >= y0 && y < y0 + (8*scale)) begin
                dx = x - x0;
                dy = y - y0;
                ci = dx / (8*scale);
                gx = dx % (8*scale);
                gy = dy % (8*scale);
                col = gx / scale;
                row = gy / scale;

                case(which)
                    2'd0: ch = menu_char(ci[2:0]);
                    2'd1: ch = gameover_char(ci[3:0]);
                    2'd2: ch = start_char(ci[4:0]);
                    default: ch = score_char(ci[3:0]);
                endcase

                // drive font rom
                font_ch  = ch;
                font_row = row;
                // NOTE: font_bits is a wire from the ROM; use it
                draw_string = font_bits[7 - col];
            end
        end
    endfunction

    // Because function can't directly set regs safely in some tools, we also compute font using a small combinational block below.
    // We'll implement each string with explicit logic (robust for Vivado).

    // ---------- MENU big text (scale 4) ----------
    localparam [9:0] MENU_X0 = 256; // centered for 4 chars * 32px = 128
    localparam [9:0] MENU_Y0 = 120;
    wire menu_box = (x >= MENU_X0 && x < MENU_X0 + 128) && (y >= MENU_Y0 && y < MENU_Y0 + 32);
    wire [9:0] menu_dx = x - MENU_X0;
    wire [9:0] menu_dy = y - MENU_Y0;
    wire [2:0] menu_ci = menu_dx / 32;        // 8*4
    wire [2:0] menu_col= (menu_dx % 32) / 4;
    wire [2:0] menu_row= (menu_dy % 32) / 4;

    reg [7:0] menu_ch;
    always @(*) begin
        case(menu_ci)
            0: menu_ch="M";
            1: menu_ch="E";
            2: menu_ch="N";
            3: menu_ch="U";
            default: menu_ch=" ";
        endcase
    end
    wire [7:0] menu_bits;
    font8x8_rom FONT_MENU(.ch(menu_ch), .row(menu_row), .bits(menu_bits));
    wire menu_on = menu_box && menu_bits[7 - menu_col];

    // outline by reusing same check with +/-1 pixel (cheap)
    wire menu_on_outline =
        (x>0  && ((x-1)>=MENU_X0) && ((x-1)<MENU_X0+128) && menu_on) ||
        (x<639&& ((x+1)>=MENU_X0) && ((x+1)<MENU_X0+128) && menu_on) ||
        (y>0  && ((y-1)>=MENU_Y0) && ((y-1)<MENU_Y0+32)  && menu_on) ||
        (y<479&& ((y+1)>=MENU_Y0) && ((y+1)<MENU_Y0+32)  && menu_on);

    // ---------- GAME OVER big text (scale 4) ----------
    localparam [9:0] GO_X0 = 176; // 9 chars * 32 = 288, center => (640-288)/2=176
    localparam [9:0] GO_Y0 = 120;
    wire go_box = (x >= GO_X0 && x < GO_X0 + 288) && (y >= GO_Y0 && y < GO_Y0 + 32);
    wire [9:0] go_dx = x - GO_X0;
    wire [9:0] go_dy = y - GO_Y0;
    wire [3:0] go_ci = go_dx / 32;
    wire [2:0] go_col= (go_dx % 32) / 4;
    wire [2:0] go_row= (go_dy % 32) / 4;

    reg [7:0] go_ch;
    always @(*) begin
        case(go_ci)
            0: go_ch="G";
            1: go_ch="A";
            2: go_ch="M";
            3: go_ch="E";
            4: go_ch=" ";
            5: go_ch="O";
            6: go_ch="V";
            7: go_ch="E";
            8: go_ch="R";
            default: go_ch=" ";
        endcase
    end
    wire [7:0] go_bits;
    font8x8_rom FONT_GO(.ch(go_ch), .row(go_row), .bits(go_bits));
    wire go_on = go_box && go_bits[7 - go_col];

    // ---------- "<FIRE> TO START" (scale 2) ----------
    localparam [9:0] ST_X0 = 96;  // 15 chars * 16 = 240, center => 200. But we put a bit left; adjust
    localparam [9:0] ST_Y0 = 200;
    // real len=15 ("<FIRE> TO START" = 15 incl space), width=240
    wire st_box = (x >= ST_X0 && x < ST_X0 + 240) && (y >= ST_Y0 && y < ST_Y0 + 16);
    wire [9:0] st_dx = x - ST_X0;
    wire [9:0] st_dy = y - ST_Y0;
    wire [4:0] st_ci = st_dx / 16;
    wire [2:0] st_col= (st_dx % 16) / 2;
    wire [2:0] st_row= (st_dy % 16) / 2;

    reg [7:0] st_ch;
    always @(*) begin
        case(st_ci)
            0: st_ch="<";
            1: st_ch="F";
            2: st_ch="I";
            3: st_ch="R";
            4: st_ch="E";
            5: st_ch=">";
            6: st_ch=" ";
            7: st_ch="T";
            8: st_ch="O";
            9: st_ch=" ";
            10: st_ch="S";
            11: st_ch="T";
            12: st_ch="A";
            13: st_ch="R";
            14: st_ch="T";
            default: st_ch=" ";
        endcase
    end
    wire [7:0] st_bits;
    font8x8_rom FONT_ST(.ch(st_ch), .row(st_row), .bits(st_bits));
    wire st_on = st_box && st_bits[7 - st_col] && blink;

    // ---------- SCORE (scale 2) ----------
    localparam [9:0] SC_X0 = 12;
    localparam [9:0] SC_Y0 = 12;
    // len=9 => 9*16=144, height=16
    wire sc_box = (x >= SC_X0 && x < SC_X0 + 144) && (y >= SC_Y0 && y < SC_Y0 + 16);
    wire [9:0] sc_dx = x - SC_X0;
    wire [9:0] sc_dy = y - SC_Y0;
    wire [3:0] sc_ci = sc_dx / 16;
    wire [2:0] sc_col= (sc_dx % 16) / 2;
    wire [2:0] sc_row= (sc_dy % 16) / 2;

    reg [7:0] sc_ch;
    always @(*) begin
        case(sc_ci)
            0: sc_ch="S";
            1: sc_ch="C";
            2: sc_ch="O";
            3: sc_ch="R";
            4: sc_ch="E";
            5: sc_ch=" ";
            6: sc_ch="0" + score_h;
            7: sc_ch="0" + score_t;
            8: sc_ch="0" + score_o;
            default: sc_ch=" ";
        endcase
    end
    wire [7:0] sc_bits;
    font8x8_rom FONT_SC(.ch(sc_ch), .row(sc_row), .bits(sc_bits));
    wire sc_on = sc_box && sc_bits[7 - sc_col];

    // ---------- background: simple stars ----------
    wire star = ((x[4:0] == 0) && (y[4:0] == 0)) ||
                ((x[5:1] == 0) && (y[5:1] == 15));

    // ---------- final pixel selection ----------
    always @(*) begin
        if (blank) begin
            r = 0; g = 0; b = 0;
        end else if (!game_playing) begin
            // MENU or GAME OVER
            // background
            r = 0; g = 0; b = 0;
            if (star) begin r=4'h2; g=4'h2; b=4'h2; end

            if (!game_over) begin
                // MENU title: outline then gradient fill
                if (menu_on_outline) begin
                    r = 4'h1; g = 4'h1; b = 4'h1;
                end
                if (menu_on) begin
                    if (menu_dy < 10) begin r=4'hF; g=4'hC; b=4'h6; end
                    else if (menu_dy < 20) begin r=4'hE; g=4'h8; b=4'h2; end
                    else begin r=4'hB; g=4'h3; b=4'h1; end
                end
                if (st_on) begin
                    r = 4'hF; g = 4'hF; b = 4'hF;
                end
            end else begin
                // GAME OVER screen
                if (go_on) begin
                    if (go_dy < 10) begin r=4'hF; g=4'h6; b=4'h6; end
                    else if (go_dy < 20) begin r=4'hE; g=4'h2; b=4'h2; end
                    else begin r=4'hA; g=4'h1; b=4'h1; end
                end
                if (st_on) begin
                    r = 4'hF; g = 4'hF; b = 4'hF;
                end
            end
        end else begin
            // PLAY mode: sprites + score overlay
            if (sc_on) begin
                r = 4'hF; g = 4'hF; b = 4'hF;
            end else if (px_player) begin
                r = p_r; g = p_g; b = p_b;
            end else if (px_bullet) begin
                r = 4'hF; g = 4'hF; b = 4'hF;
            end else if (px_enemy) begin
                r = e_r; g = e_g; b = e_b;
            end else begin
                r = 0; g = 0; b = 4'h1;
            end
        end
    end
endmodule
