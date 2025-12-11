`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 11:12:49 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input CLK100MHZ,
    input BTNL,
    input BTNR,
    input BTNC,
    input BTNU,
    input sw0,
    input sw1,
    input sw2,
    output HS,
    output VS,
    output [3:0] RED,
    output [3:0] GREEN,
    output [3:0] BLUE
    );
    
    localparam PLAYER_W = 16;
    
    wire [9:0] x, y;
    wire blank;
    wire [3:0] r, g, b;
    wire rst_ni = ~BTNC;
//    wire rst_ni = 1'b1;
    wire game_tick_w;
    wire [7:0] bullet_active;
    wire [9:0] bullet_x;
    wire [9:0] bullet_y;
    
    game_tick #(
        .CLK_HZ (100_000_000),
        .TICK_HZ(60)
    ) game_tick_i (
        .clk_i (CLK100MHZ),
        .rst_ni(rst_ni),
        .tick_o(game_tick_w)
    );
    
//    clk_divider div(
//        .clk_i(CLK100MHZ),
//        .rst_ni(1'b1),
//        .clk_o(clk60hz)
//    );
    
    vga_sync u1(
        .clk(CLK100MHZ), 
        .HS(HS), 
        .VS(VS), 
        .x(x), 
        .y(y),
        .blank(blank)
    );
    
    
    reg [9:0] player_x = 320;
    wire [9:0] player_y = 440;
    
    always @(posedge CLK100MHZ) begin
        if (!rst_ni) begin
            player_x <= 320;
        end else if (game_tick_w) begin
            if (BTNL && player_x > 0)
                player_x <= player_x - 1;
            else if (BTNR && player_x < 640-PLAYER_W)
                player_x <= player_x + 1;
        end
    end
    renderer ren(
        .clk         (CLK100MHZ),   // ???????????
        .blank       (blank),
        .x           (x),
        .y           (y),
        .player_x    (player_x),
        .player_y    (player_y),
        .bullet_active(bullet_active),
        .bullet_x    (bullet_x),
        .bullet_y    (bullet_y),
        .r           (r),
        .g           (g),
        .b           (b)
    );
    
    bullet bullet_i(
        .clk       (CLK100MHZ),
        .rst_ni    (rst_ni),
        .fire      (BTNU),
        .tick      (game_tick_w),
        .player_x  (player_x),
        .player_y  (player_y),
        .active    (bullet_active),
        .bullet_x  (bullet_x),
        .bullet_y  (bullet_y)
    );
    
    assign RED = r;
    assign GREEN = g;
    assign BLUE = b;
endmodule