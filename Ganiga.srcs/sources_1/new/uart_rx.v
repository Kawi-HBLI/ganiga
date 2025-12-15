`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input rst_ni,
    input rx,          // ?? RsRx ??? USB
    output reg [7:0] data,
    output reg valid   // ???? 1 ??? 1 clock cycle ????????????????????
    );

    // ??????? Baud Rate 9600 ?????? Clock 100MHz
    // 100,000,000 / 9600 = 10416 Clocks per bit
    localparam CLKS_PER_BIT = 868;

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state = IDLE;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] shift_reg = 0;

    always @(posedge clk) begin
        if (!rst_ni) begin
            state <= IDLE;
            valid <= 0;
            clk_count <= 0;
            bit_index <= 0;
            data <= 0;
        end else begin
            valid <= 0; // Default

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx == 0) state <= START; // Start bit detected (falling edge)
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx == 0) begin // Check start bit middle
                            clk_count <= 0;
                            state <= DATA;
                        end else state <= IDLE;
                    end else clk_count <= clk_count + 1;
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        shift_reg[bit_index] <= rx;
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else clk_count <= clk_count + 1;
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT-1) begin
                        state <= IDLE;
                        valid <= 1; // Done!
                        data <= shift_reg;
                    end else clk_count <= clk_count + 1;
                end
            endcase
        end
    end
endmodule