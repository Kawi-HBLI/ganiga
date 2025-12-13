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
    input  wire       game_playing,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    input  wire       bullet_active,
    input  wire [9:0] bullet_x,
    input  wire [9:0] bullet_y,
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

    // ===== MENU (font overlay) =====
    reg [15:0] frame_cnt;
    always @(posedge clk) begin
        if (!blank && x==0 && y==0) frame_cnt <= frame_cnt + 1'b1;
    end
    wire blink_on = frame_cnt[5];

    wire star_on = (~blank) && ((x[3]^y[4]) & (x[7]^y[6]) & ~x[1]);

    localparam integer MENU_SCALE = 4;
    localparam integer MENU_LEN   = 4;
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

    function [7:0] menu_char(input [3:0] idx);
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
        // 32px height -> 4 bands (thick retro gradient)
        case (menu_dy[9:3])
            0: menu_fill_g = 4'hF; // top
            1: menu_fill_g = 4'hD;
            2: menu_fill_g = 4'hA;
            default: menu_fill_g = 4'h7; // bottom
        endcase
    end

    // ===== END MENU =====

    // Bullet
    localparam BULLET_W = 2;
    localparam BULLET_H = 6;
    wire px_bullet = bullet_active &&
                     (x >= bullet_x) && (x < bullet_x + BULLET_W) &&
                     (y >= bullet_y) && (y < bullet_y + BULLET_H);

    always @(*) begin
        r = 0; g = 0; b = 0;

        if (blank) begin
            r = 0; g = 0; b = 0;
        end else if (!game_playing) begin
            if (menu_outline_on) begin
                r = 4'h1; g = 4'h1; b = 4'h1; // outline
            end else if (menu_fill_on) begin
                r = menu_fill_r; g = menu_fill_g; b = menu_fill_b; // gradient fill
            end else if (prompt_on) begin
                r = 4'hF; g = 4'hF; b = 4'hF;
            end else if (star_on) begin
                r = 4'h2; g = 4'h2; b = 4'h2;
            end else begin
                r = 0; g = 0; b = 0;
            end
        end else if (px_player) begin
            r = p_r; g = p_g; b = p_b;
        end else if (px_bullet) begin
            r = 4'hF; g = 4'hF; b = 4'hF;
        end else if (px_enemy) begin
            r = e_r; g = e_g; b = e_b;
        end else begin
            // ถ้าคุณมีเมนู: ตอน menu ให้พื้นหลังโล่ง, ตอนเล่นให้ใช้ map
            if (!game_playing) begin
                r = 0; g = 0; b = 0; // menu background
            end else begin
                r = map_r; g = map_g; b = map_b; // <<< ใช้สีจาก tile_map
            end
        end
    end

endmodule

