`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/13/2025 11:49:02 AM
// Design Name: 
// Module Name: enemy_sprite
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


module enemy_sprite #(
    parameter ENEMY_W = 32,
    parameter ENEMY_H = 32,
    parameter GAP     = 16
)(
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [4:0] enemies_alive,
    input  wire [9:0] group_x,
    input  wire [9:0] group_y,
    output reg        px_on,
    output reg [3:0]  r, g, b
);

    integer k;

    always @(*) begin
        px_on = 0;
        r = 0; g = 0; b = 0;
        
        // Loop check 5 enemies [cite: 59]
        for (k = 0; k < 5; k = k + 1) begin
            if (enemies_alive[k]) begin
                if (x >= (group_x + k*(ENEMY_W + GAP)) && 
                    x <  (group_x + k*(ENEMY_W + GAP) + ENEMY_W) &&
                    y >= group_y &&
                    y <  group_y + ENEMY_H) 
                begin
                    px_on = 1'b1;
                    // Yellow color as per original renderer [cite: 66-67]
                    r = 4'hF; 
                    g = 4'hF; 
                    b = 4'h0; 
                end
            end
        end
    end

endmodule