module ps2_rx(
    input  wire clk,        // System Clock
    input  wire rst_ni,
    input  wire ps2_clk,    // ???????? PS2_CLK ????????
    input  wire ps2_data,   // ???????? PS2_DATA ????????
    output reg  [7:0] rx_data,
    output reg  rx_done_tick
    );

    // Synchronize PS2 Clock signal
    reg [1:0] ps2_clk_sync;
    always @(posedge clk) ps2_clk_sync <= {ps2_clk_sync[0], ps2_clk};

    // Detect falling edge of PS2 Clock
    wire falling_edge = (ps2_clk_sync[1:0] == 2'b10);

    // State machine to read 11 bits (Start, 8 Data, Parity, Stop)
    reg [3:0] b_count;
    reg [10:0] shift_reg; // ?????????????

    always @(posedge clk) begin
        if (!rst_ni) begin
            b_count <= 0; rx_done_tick <= 0;
        end else begin
            rx_done_tick <= 0; // default
            if (falling_edge) begin
                shift_reg <= {ps2_data, shift_reg[10:1]}; // Shift data in
                if (b_count == 10) begin
                    b_count <= 0;
                    rx_done_tick <= 1;
                    rx_data <= shift_reg[8:1]; // ????????? 8 bit ??????
                end else begin
                    b_count <= b_count + 1;
                end
            end
        end
    end
endmodule