`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2025 11:09:32 PM
// Design Name: 
// Module Name: clk_divider
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


module clk_divider(
    input wire rst_ni,
    input wire clk_i,
    output wire clk_o
    );
    reg [31:0] counter_r;
    reg clk_r;
    
    always @(posedge clk_i) begin
    if (!rst_ni) begin
      clk_r <= 0;
      counter_r <= 0;
    end else begin
      if (counter_r == (100_000_000 / 120) - 1) begin
        clk_r <= ~clk_r;
        counter_r <= 0;
      end else begin
        counter_r <= counter_r + 1;
      end
    end
    end
    
    assign clk_o = clk_r;
endmodule
