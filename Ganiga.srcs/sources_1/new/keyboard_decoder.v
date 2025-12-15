module keyboard_decoder(
    input  wire clk,
    input  wire rst_ni,
    input  wire [7:0] rx_data, // ????????? ps2_rx
    input  wire rx_done_tick,
    
    output reg btn_left,
    output reg btn_right,
    output reg btn_fire
    );

    reg key_release_waiting; // ?????????????? F0 ???????

    always @(posedge clk) begin
        if (!rst_ni) begin
            btn_left <= 0; btn_right <= 0; btn_fire <= 0;
            key_release_waiting <= 0;
        end else if (rx_done_tick) begin
            // ?????????? F0 ?????????????????????
            if (rx_data == 8'hF0) begin
                key_release_waiting <= 1;
            end 
            else begin
                // ????? F0 ???????????? ??????????? "???" ????????
                if (key_release_waiting) begin
                    case (rx_data)
                        8'h6B: btn_left  <= 0; // Left Arrow
                        8'h74: btn_right <= 0; // Right Arrow
                        8'h29: btn_fire  <= 0; // Spacebar
                    endcase
                    key_release_waiting <= 0;
                end 
                // ???????? F0 ???????????? "??" ????????
                else begin
                    case (rx_data)
                        8'h6B: btn_left  <= 1; // Left Arrow
                        8'h74: btn_right <= 1; // Right Arrow
                        8'h29: btn_fire  <= 1; // Spacebar
                    endcase
                end
            end
        end
    end
endmodule