`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/23/2025 02:04:36 PM
// Design Name: 
// Module Name: game_tick
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


module game_tick #(
    parameter integer CLK_HZ  = 100_000_000,
    parameter integer TICK_HZ = 60
    )(
    input  wire clk_i,
    input  wire rst_ni,   // active low
    output reg  tick_o    // pulse = 1 ??? 1 clock ??? ? 1/TICK_HZ ??????
    );

    localparam integer COUNT_MAX = CLK_HZ / TICK_HZ - 1;
    reg [31:0] counter_r = 0;

    always @(posedge clk_i) begin
        if (!rst_ni) begin
            counter_r <= 32'd0;
            tick_o    <= 1'b0;
        end else begin
            if (counter_r == COUNT_MAX) begin
                counter_r <= 32'd0;
                tick_o    <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                tick_o    <= 1'b0;
            end
        end
    end

endmodule
