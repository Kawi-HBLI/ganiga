`timescale 1ns / 1ps

module enemy_bullet_manager #(
    parameter BULLET_W = 4,
    parameter BULLET_H = 8,
    parameter SPEED_Y  = 8,
    parameter SCREEN_H = 480
)(
    input  wire       clk,
    input  wire       rst_ni,
    input  wire       tick,
    input  wire       enemy_fire,      
    input  wire [9:0] spawn_x,
    input  wire [9:0] spawn_y,
    input  wire [9:0] player_x,        
    input  wire [9:0] player_y,

    output wire       eb1_active, output wire [9:0] eb1_x, output wire [9:0] eb1_y,
    output wire       eb2_active, output wire [9:0] eb2_x, output wire [9:0] eb2_y,
    output wire       eb3_active, output wire [9:0] eb3_x, output wire [9:0] eb3_y,

    output wire       player_hit      
);

    reg trig_1, trig_2, trig_3;
    
    always @(*) begin
        trig_1 = 0; trig_2 = 0; trig_3 = 0;
        if (enemy_fire) begin
            if (!eb1_active)      trig_1 = 1;
            else if (!eb2_active) trig_2 = 1;
            else if (!eb3_active) trig_3 = 1;
        end
    end

    wire hit1 = eb1_active && (eb1_x + 4 >= player_x) && (eb1_x < player_x + 16) && (eb1_y + 8 >= player_y) && (eb1_y < player_y + 16);
    wire hit2 = eb2_active && (eb2_x + 4 >= player_x) && (eb2_x < player_x + 16) && (eb2_y + 8 >= player_y) && (eb2_y < player_y + 16);
    wire hit3 = eb3_active && (eb3_x + 4 >= player_x) && (eb3_x < player_x + 16) && (eb3_y + 8 >= player_y) && (eb3_y < player_y + 16);

    assign player_hit = hit1 | hit2 | hit3;

    enemy_bullet #(.BULLET_W(BULLET_W), .BULLET_H(BULLET_H), .SPEED_Y(SPEED_Y), .SCREEN_H(SCREEN_H))
    bullet1 (.clk(clk), .rst_ni(rst_ni), .tick(tick), .enemy_fire(trig_1), .spawn_x(spawn_x), .spawn_y(spawn_y), .hit(hit1), .active(eb1_active), .bullet_x(eb1_x), .bullet_y(eb1_y));

    enemy_bullet #(.BULLET_W(BULLET_W), .BULLET_H(BULLET_H), .SPEED_Y(SPEED_Y), .SCREEN_H(SCREEN_H))
    bullet2 (.clk(clk), .rst_ni(rst_ni), .tick(tick), .enemy_fire(trig_2), .spawn_x(spawn_x), .spawn_y(spawn_y), .hit(hit2), .active(eb2_active), .bullet_x(eb2_x), .bullet_y(eb2_y));

    enemy_bullet #(.BULLET_W(BULLET_W), .BULLET_H(BULLET_H), .SPEED_Y(SPEED_Y), .SCREEN_H(SCREEN_H))
    bullet3 (.clk(clk), .rst_ni(rst_ni), .tick(tick), .enemy_fire(trig_3), .spawn_x(spawn_x), .spawn_y(spawn_y), .hit(hit3), .active(eb3_active), .bullet_x(eb3_x), .bullet_y(eb3_y));

endmodule