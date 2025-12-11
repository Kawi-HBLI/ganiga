`timescale 1ns / 1ps

module player_sprite_rom (
    input  wire        clk,
    input  wire [7:0]  addr,   // 0..255 (16x16)
    output reg  [31:0] data    // ARGB 8-8-8-8
);
    // 256 pixels, each 32-bit ARGB (from pixil-frame-0_rgb.txt)
    reg [31:0] rom [0:255];

    initial begin
        $readmemh("player_1.txt", rom);
    end

    always @(posedge clk) begin
        data <= rom[addr];
    end
endmodule
