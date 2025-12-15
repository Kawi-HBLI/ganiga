`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module renderer(
    input  wire       clk,
    input  wire       blank,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [1:0] game_state,
    input  wire       game_playing,
    input  wire       game_over,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
    input  wire       enemy_bullet_active,
    input  wire [9:0] enemy_bullet_x,
    input  wire [9:0] enemy_bullet_y,
    input  wire [4:0] enemies_alive,
    input  wire [9:0] enemy_group_x,
    input  wire [9:0] enemy_group_y,
    output reg  [3:0] r,
    output reg  [3:0] g,
    output reg  [3:0] b
);

    // Player
    wire px_player;
    wire [3:0] p_r, p_g, p_b;
    wire [3:0] map_r, map_g, map_b;
    wire       map_is_wall;

    tile_map map_inst (
        .x(x),
        .y(y),
        .r(map_r),
        .g(map_g),
        .b(map_b),
        .is_wall(map_is_wall)
    );

    player_sprite spr_player(
        .clk(clk), .x(x), .y(y),
        .player_x(player_x), .player_y(player_y),
        .px_on(px_player), .r(p_r), .g(p_g), .b(p_b)
    );

    // Enemy
    wire px_enemy;
    wire [3:0] e_r, e_g, e_b;
    enemy_sprite spr_enemy(
        .x(x), .y(y),
        .enemies_alive(enemies_alive),
        .group_x(enemy_group_x), .group_y(enemy_group_y),
        .px_on(px_enemy), .r(e_r), .g(e_g), .b(e_b)
    );

    // ===== MENU / GAMEOVER (font overlay) =====
    reg [15:0] frame_cnt;
    always @(posedge clk) begin
        if (!blank && x==0 && y==0) frame_cnt <= frame_cnt + 1'b1;
    end
    wire blink_on = frame_cnt[5];

    wire star_on = (~blank) && ((x[3]^y[4]) & (x[7]^y[6]) & ~x[1]);

    // ===== MENU text =====
    localparam integer MENU_SCALE = 4;
    localparam integer MENU_LEN   = 6;
    localparam integer MENU_W     = MENU_LEN * 8 * MENU_SCALE;
    localparam integer MENU_H     = 8 * MENU_SCALE;
    localparam integer MENU_X0    = (640 - MENU_W)/2;
    localparam integer MENU_Y0    = 120;

    localparam integer PROMPT_SCALE = 2;
    localparam integer PROMPT_LEN   = 15;
    localparam integer PROMPT_W     = PROMPT_LEN * 8 * PROMPT_SCALE;
    localparam integer PROMPT_H     = 8 * PROMPT_SCALE;
    localparam integer PROMPT_X0    = (640 - PROMPT_W)/2;
    localparam integer PROMPT_Y0    = 300;

    function [7:0] menu_char(input [5:0] idx);
        begin
            case(idx)
                0: menu_char = "G";
                1: menu_char = "A";
                2: menu_char = "N";
                3: menu_char = "I";
                4: menu_char = "G";
                5: menu_char = "A";
                default: menu_char = " ";
            endcase
        end
    endfunction

    function [7:0] prompt_char(input [4:0] idx);
        begin
            case(idx)
                0:  prompt_char = "<";
                1:  prompt_char = "F";
                2:  prompt_char = "I";
                3:  prompt_char = "R";
                4:  prompt_char = "E";
                5:  prompt_char = ">";
                6:  prompt_char = " ";
                7:  prompt_char = "T";
                8:  prompt_char = "O";
                9:  prompt_char = " ";
                10: prompt_char = "S";
                11: prompt_char = "T";
                12: prompt_char = "A";
                13: prompt_char = "R";
                14: prompt_char = "T";
                default: prompt_char = " ";
            endcase
        end
    endfunction

    wire in_menu_box = (~blank) && (x>=MENU_X0) && (x<MENU_X0+MENU_W) && (y>=MENU_Y0) && (y<MENU_Y0+MENU_H);
    wire [9:0] menu_dx = x - MENU_X0;
    wire [9:0] menu_dy = y - MENU_Y0;
    wire [3:0] menu_ci = menu_dx / (8*MENU_SCALE);
    wire [2:0] menu_col = (menu_dx / MENU_SCALE) % 8;
    wire [2:0] menu_row = (menu_dy / MENU_SCALE) % 8;
    wire [7:0] menu_ch  = menu_char(menu_ci);

    wire in_prompt_box = (~blank) && (x>=PROMPT_X0) && (x<PROMPT_X0+PROMPT_W) && (y>=PROMPT_Y0) && (y<PROMPT_Y0+PROMPT_H);
    wire [9:0] pr_dx = x - PROMPT_X0;
    wire [9:0] pr_dy = y - PROMPT_Y0;
    wire [4:0] pr_ci = pr_dx / (8*PROMPT_SCALE);
    wire [2:0] pr_col = (pr_dx / PROMPT_SCALE) % 8;
    wire [2:0] pr_row = (pr_dy / PROMPT_SCALE) % 8;
    wire [7:0] pr_ch  = prompt_char(pr_ci);

    // 3 ROM reads to build outline
    wire [2:0] menu_row_up = (menu_row==0) ? 3'd0 : (menu_row-3'd1);
    wire [2:0] menu_row_dn = (menu_row==7) ? 3'd7 : (menu_row+3'd1);
    wire [7:0] menu_bits0, menu_bits_up, menu_bits_dn;
    font8x8_rom u_font_menu0(.ch(menu_ch), .row(menu_row),    .bits(menu_bits0));
    font8x8_rom u_font_menuU(.ch(menu_ch), .row(menu_row_up), .bits(menu_bits_up));
    font8x8_rom u_font_menuD(.ch(menu_ch), .row(menu_row_dn), .bits(menu_bits_dn));

    wire [7:0] pr_bits;
    font8x8_rom u_font_prompt(.ch(pr_ch), .row(pr_row), .bits(pr_bits));

    wire menu_fill_on = in_menu_box && menu_bits0[7 - menu_col];
    wire [2:0] menu_col_l = (menu_col==0) ? 3'd0 : (menu_col-3'd1);
    wire [2:0] menu_col_r = (menu_col==7) ? 3'd7 : (menu_col+3'd1);

    wire menu_neigh_on =
        menu_bits0[7 - menu_col_l] | menu_bits0[7 - menu_col_r] |
        menu_bits_up[7 - menu_col] | menu_bits_dn[7 - menu_col] |
        menu_bits_up[7 - menu_col_l] | menu_bits_up[7 - menu_col_r] |
        menu_bits_dn[7 - menu_col_l] | menu_bits_dn[7 - menu_col_r];

    wire menu_outline_on = in_menu_box && menu_neigh_on && !menu_bits0[7 - menu_col];

    wire prompt_on = in_prompt_box && pr_bits[7 - pr_col] && blink_on;

    reg [3:0] menu_fill_r, menu_fill_g, menu_fill_b;
    always @(*) begin
        menu_fill_r = 4'hF;
        menu_fill_b = 4'h0;
        case (menu_dy[9:3])
            0: menu_fill_g = 4'hF;
            1: menu_fill_g = 4'hD;
            2: menu_fill_g = 4'hA;
            default: menu_fill_g = 4'h7;
        endcase
    end

    // ===== GAME OVER text =====
    localparam integer OVER_SCALE = 4;
    localparam integer OVER_LEN   = 9;   // "GAME OVER"
    localparam integer OVER_W     = OVER_LEN * 8 * OVER_SCALE;
    localparam integer OVER_H     = 8 * OVER_SCALE;
    localparam integer OVER_X0    = (640 - OVER_W)/2;
    localparam integer OVER_Y0    = 140;

    localparam integer OVERP_SCALE = 2;
    localparam integer OVERP_LEN   = 15; // "<FIRE> TO RETRY"
    localparam integer OVERP_W     = OVERP_LEN * 8 * OVERP_SCALE;
    localparam integer OVERP_H     = 8 * OVERP_SCALE;
    localparam integer OVERP_X0    = (640 - OVERP_W)/2;
    localparam integer OVERP_Y0    = 300;

    function [7:0] over_char(input [5:0] idx);
        begin
            case(idx)
                0: over_char = "G";
                1: over_char = "A";
                2: over_char = "M";
                3: over_char = "E";
                4: over_char = " ";
                5: over_char = "O";
                6: over_char = "V";
                7: over_char = "E";
                8: over_char = "R";
                default: over_char = " ";
            endcase
        end
    endfunction

    function [7:0] over_prompt_char(input [4:0] idx);
        begin
            case(idx)
                0:  over_prompt_char = "<";
                1:  over_prompt_char = "F";
                2:  over_prompt_char = "I";
                3:  over_prompt_char = "R";
                4:  over_prompt_char = "E";
                5:  over_prompt_char = ">";
                6:  over_prompt_char = " ";
                7:  over_prompt_char = "T";
                8:  over_prompt_char = "O";
                9:  over_prompt_char = " ";
                10: over_prompt_char = "R";
                11: over_prompt_char = "E";
                12: over_prompt_char = "T";
                13: over_prompt_char = "R";
                14: over_prompt_char = "Y";
                default: over_prompt_char = " ";
            endcase
        end
    endfunction

    wire in_over_box = (~blank) && (x>=OVER_X0) && (x<OVER_X0+OVER_W) && (y>=OVER_Y0) && (y<OVER_Y0+OVER_H);
    wire [9:0] over_dx = x - OVER_X0;
    wire [9:0] over_dy = y - OVER_Y0;
    wire [3:0] over_ci = over_dx / (8*OVER_SCALE);
    wire [2:0] over_col = (over_dx / OVER_SCALE) % 8;
    wire [2:0] over_row = (over_dy / OVER_SCALE) % 8;
    wire [7:0] over_ch  = over_char(over_ci);

    wire in_overp_box = (~blank) && (x>=OVERP_X0) && (x<OVERP_X0+OVERP_W) && (y>=OVERP_Y0) && (y<OVERP_Y0+OVERP_H);
    wire [9:0] ovp_dx = x - OVERP_X0;
    wire [9:0] ovp_dy = y - OVERP_Y0;
    wire [4:0] ovp_ci = ovp_dx / (8*OVERP_SCALE);
    wire [2:0] ovp_col = (ovp_dx / OVERP_SCALE) % 8;
    wire [2:0] ovp_row = (ovp_dy / OVERP_SCALE) % 8;
    wire [7:0] ovp_ch  = over_prompt_char(ovp_ci);

    wire [2:0] over_row_up = (over_row==0) ? 3'd0 : (over_row-3'd1);
    wire [2:0] over_row_dn = (over_row==7) ? 3'd7 : (over_row+3'd1);
    wire [7:0] over_bits0, over_bits_up, over_bits_dn;
    font8x8_rom u_font_over0(.ch(over_ch), .row(over_row),    .bits(over_bits0));
    font8x8_rom u_font_overU(.ch(over_ch), .row(over_row_up), .bits(over_bits_up));
    font8x8_rom u_font_overD(.ch(over_ch), .row(over_row_dn), .bits(over_bits_dn));

    wire [7:0] ovp_bits;
    font8x8_rom u_font_overp(.ch(ovp_ch), .row(ovp_row), .bits(ovp_bits));

    wire over_fill_on = in_over_box && over_bits0[7 - over_col];
    wire [2:0] over_col_l = (over_col==0) ? 3'd0 : (over_col-3'd1);
    wire [2:0] over_col_r = (over_col==7) ? 3'd7 : (over_col+3'd1);

    wire over_neigh_on =
        over_bits0[7 - over_col_l] | over_bits0[7 - over_col_r] |
        over_bits_up[7 - over_col] | over_bits_dn[7 - over_col] |
        over_bits_up[7 - over_col_l] | over_bits_up[7 - over_col_r] |
        over_bits_dn[7 - over_col_l] | over_bits_dn[7 - over_col_r];

    wire over_outline_on = in_over_box && over_neigh_on && !over_bits0[7 - over_col];

    wire over_prompt_on = in_overp_box && ovp_bits[7 - ovp_col] && blink_on;

    reg [3:0] over_fill_r, over_fill_g, over_fill_b;
    always @(*) begin
        over_fill_g = 4'h0;
        over_fill_b = 4'h0;
        case (over_dy[9:3])
            0: begin over_fill_r = 4'hF; over_fill_g = 4'h2; end
            1: begin over_fill_r = 4'hF; over_fill_g = 4'h6; end
            2: begin over_fill_r = 4'hF; over_fill_g = 4'hA; end
            default: begin over_fill_r = 4'hF; over_fill_g = 4'hD; end
        endcase
    end

    // Bullet
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    wire px_bullet = bullet_active &&
                     (x >= bullet_x) && (x < bullet_x + BULLET_W) &&
                     (y >= bullet_y) && (y < bullet_y + BULLET_H);

    // Enemy Bullet
    wire px_enemy_bullet = enemy_bullet_active &&
                           (x >= enemy_bullet_x) && (x < enemy_bullet_x + BULLET_W) &&
                           (y >= enemy_bullet_y) && (y < enemy_bullet_y + BULLET_H);

    always @(*) begin
        r = 0; g = 0; b = 0;

        if (blank) begin
            r = 0; g = 0; b = 0;

        // ===== GAME OVER SCREEN =====
        end else if (game_over) begin
            if (over_outline_on) begin
                r = 4'h1; g = 4'h1; b = 4'h1;
            end else if (over_fill_on) begin
                r = over_fill_r; g = over_fill_g; b = over_fill_b;
            end else if (over_prompt_on) begin
                r = 4'hF; g = 4'hF; b = 4'hF;
            end else if (star_on) begin
                r = 4'h2; g = 4'h2; b = 4'h2;
            end else begin
                r = 0; g = 0; b = 0;
            end

        // ===== MENU SCREEN =====
        end else if (!game_playing) begin
            if (menu_outline_on) begin
                r = 4'h1; g = 4'h1; b = 4'h1;
            end else if (menu_fill_on) begin
                r = menu_fill_r; g = menu_fill_g; b = menu_fill_b;
            end else if (prompt_on) begin
                r = 4'hF; g = 4'hF; b = 4'hF;
            end else if (star_on) begin
                r = 4'h2; g = 4'h2; b = 4'h2;
            end else begin
                r = 0; g = 0; b = 0;
            end

        // ===== PLAY SCREEN =====
        end else if (px_player) begin
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

endmodule