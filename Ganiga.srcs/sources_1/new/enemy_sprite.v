`timescale 1ns / 1ps

module enemy_sprite #(
    parameter ENEMY_W = 24, 
    parameter ENEMY_H = 24,
    parameter GAP     = 16,
    parameter SPRITE_SIZE = 16 
)(
    input  wire       clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [7:0] enemies_alive,
    input  wire [9:0] group_x,
    input  wire [9:0] group_y,
    output reg        px_on,
    output reg [3:0]  r, g, b
);
    integer k;
    reg [2:0] hit_index;
    reg       hit_found;
    

    wire [9:0] local_x = x - (group_x + hit_index*(ENEMY_W + GAP));
    wire [9:0] local_y = y - group_y;
  
    wire inside_sprite = (local_x >= 4 && local_x < 20 && local_y >= 4 && local_y < 20);
    
    wire [7:0] addr = (local_y - 4) * SPRITE_SIZE + (local_x - 4);
    
    wire [11:0] rom_data;
    enemy_sprite_rom enemy_rom (
        .clk(clk),
        .addr(addr),
        .data(rom_data)
    );

    reg hit_found_reg;
    reg inside_sprite_reg;

    always @(posedge clk) begin
        hit_found = 0;
        hit_index = 0;
        for (k = 0; k < 8; k = k + 1) begin
            if (!hit_found && enemies_alive[k]) begin
                if (x >= (group_x + k*(ENEMY_W + GAP)) && 
                    x <  (group_x + k*(ENEMY_W + GAP) + ENEMY_W) &&
                    y >= group_y &&
                    y <  group_y + ENEMY_H) 
                begin
                    hit_found = 1;
                    hit_index = k;
                end
            end
        end
        hit_found_reg     <= hit_found;
        inside_sprite_reg <= inside_sprite;
    end

    always @(*) begin
        px_on = 0; r = 0; g = 0; b = 0;
        if (hit_found_reg && inside_sprite_reg) begin
            if (rom_data != 12'h000) begin
                px_on = 1'b1;
                r = rom_data[11:8];
                g = rom_data[7:4];
                b = rom_data[3:0];
            end
        end
    end

endmodule