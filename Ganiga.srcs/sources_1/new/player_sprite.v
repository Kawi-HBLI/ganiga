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
    parameter PLAYER_W = 16,
    parameter PLAYER_H = 8
    )(
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [9:0] player_x,
    input  wire [9:0] player_y,
    output wire       px_on
    );
    
    wire in_bounds = (x >= player_x) && (x < player_x + PLAYER_W) && 
                     (y >= player_y) && (y < player_y + PLAYER_H);
    
    assign px_on = in_bounds;
endmodule
