`timescale 1ns / 1ps

module enemy_sprite_rom (
    input wire clk,
    input wire [7:0] addr,    // 16x16 = 256 pixels (8 bit address)
    output reg [11:0] data
    );
    (* rom_style = "block" *)
    reg [11:0] rom_memory [0:255];

    initial begin
        $readmemh("enemy.mem", rom_memory);
    end
    
    always @(posedge clk) begin
        data <= rom_memory[addr];
    end
endmodule