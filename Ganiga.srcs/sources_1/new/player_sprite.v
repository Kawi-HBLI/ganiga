module player_sprite #(
    parameter SPRITE_W = 16,
    parameter SPRITE_H = 16
)(
    input  wire       clk,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    output reg        px_on,
    output reg [3:0]  r, g, b
);
 
    wire inside = (x >= player_x) && (x < player_x + SPRITE_W) &&
                  (y >= player_y) && (y < player_y + SPRITE_H);

    wire [9:0] sx = x - player_x;
    wire [9:0] sy = y - player_y;
    wire [7:0] addr = sy * SPRITE_W + sx;

    wire [11:0] rom_data;
    player_sprite_rom player_rom (
        .clk (clk),
        .addr(addr),
        .data(rom_data)
    );

    reg inside_reg;
    always @(posedge clk) begin
        inside_reg <= inside;
    end

 
    always @(*) begin
        if (inside_reg) begin
            px_on = 1'b1;
            r     = rom_data[11:8]; 
            g     = rom_data[7:4];
            b     = rom_data[3:0];
        end else begin
            px_on = 1'b0;
            r = 0; g = 0; b = 0;
        end
    end

endmodule