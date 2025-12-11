`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 11:50:34 AM
// Design Name: 
// Module Name: player_sprite
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


 module player_sprite #(
    parameter SPRITE_W = 16,
    parameter SPRITE_H = 16
)(
        input  wire       clk,        // ??? clk ???????? VGA
        input  wire [9:0] x,          // ?????? X ??? VGA
        input  wire [9:0] y,          // ?????? Y ??? VGA
        input  wire [9:0] player_x,   // ??????? X ????????????? sprite
        input  wire [9:0] player_y,   // ??????? Y ????????????? sprite
        
        output reg        px_on,      // 1 = pixel ?????????? sprite
        output reg [3:0]  r,
        output reg [3:0]  g,
        output reg [3:0]  b
        );
        
        // 1) ?????????????????????????? sprite ???
        wire inside =
            (x >= player_x) && (x < player_x + SPRITE_W) &&
            (y >= player_y) && (y < player_y + SPRITE_H);
        
        // 2) ?????????????????? sprite (0..15)
        wire [4:0] sx = x - player_x;  // col
        wire [4:0] sy = y - player_y;  // row
        
        // 3) addr = row * SPRITE_W + col (0..255)
        wire [7:0] addr = sy * SPRITE_W + sx;
        
        // 4) ??????? Block Memory IP (??? .coe)
        //    ? Width = 12, Depth = 256 ??????????????? IP
        wire [11:0] rom_data;
        
        // ??????????? blk_mem_gen_0 ????????? IP ??????
        blk_mem_gen_0 player_rom (
            .clka (clk),
            .addra(addr),
            .douta(rom_data)
        );
        
        // 5) Pipeline: ?????? rom_data & inside ?????? clock ????????
        reg [11:0] rgb_reg;
        reg        inside_reg;
        
        always @(posedge clk) begin
            rgb_reg    <= rom_data;
            inside_reg <= inside;
        end
        
        // 6) ??? RGB 4:4:4 ?????????
        always @(*) begin
            if (inside_reg) begin
                px_on = 1'b1;
                r     = rgb_reg[11:8];
                g     = rgb_reg[7:4];
                b     = rgb_reg[3:0];
            end else begin
                px_on = 1'b0;
                r     = 4'h0;
                g     = 4'h0;
                b     = 4'h0;
            end
    end
    
endmodule