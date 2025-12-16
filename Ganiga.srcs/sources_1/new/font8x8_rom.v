`timescale 1ns / 1ps
// Simple 8x8 font ROM (MSB = leftmost pixel)
// Includes glyphs needed for: "MENU" and "<FIRE> TO START"
module font8x8_rom(
    input  wire [7:0] ch,     // ASCII
    input  wire [2:0] row,    // 0..7
    output reg  [7:0] bits    // bitmap row
);
always @(*) begin
    bits = 8'b00000000;
    case (ch)
        " ": bits = 8'b00000000;

        "<": case(row)
            0: bits=8'b00000110;
            1: bits=8'b00001100;
            2: bits=8'b00011000;
            3: bits=8'b00110000;
            4: bits=8'b00011000;
            5: bits=8'b00001100;
            6: bits=8'b00000110;
            default: bits=8'b00000000;
        endcase
        ">": case(row)
            0: bits=8'b01100000;
            1: bits=8'b00110000;
            2: bits=8'b00011000;
            3: bits=8'b00001100;
            4: bits=8'b00011000;
            5: bits=8'b00110000;
            6: bits=8'b01100000;
            default: bits=8'b00000000;
        endcase

        // Letters
        "A": case(row)
            0: bits=8'b00011000;
            1: bits=8'b00111100;
            2: bits=8'b01100110;
            3: bits=8'b01100110;
            4: bits=8'b01111110;
            5: bits=8'b01100110;
            6: bits=8'b01100110;
            default: bits=8'b00000000;
        endcase
        "E": case(row)
            0: bits=8'b01111110;
            1: bits=8'b01100000;
            2: bits=8'b01100000;
            3: bits=8'b01111100;
            4: bits=8'b01100000;
            5: bits=8'b01100000;
            6: bits=8'b01111110;
            default: bits=8'b00000000;
        endcase
        "F": case(row)
            0: bits=8'b01111110;
            1: bits=8'b01100000;
            2: bits=8'b01100000;
            3: bits=8'b01111100;
            4: bits=8'b01100000;
            5: bits=8'b01100000;
            6: bits=8'b01100000;
            default: bits=8'b00000000;
        endcase
        "I": case(row)
            0: bits=8'b00111100;
            1: bits=8'b00011000;
            2: bits=8'b00011000;
            3: bits=8'b00011000;
            4: bits=8'b00011000;
            5: bits=8'b00011000;
            6: bits=8'b00111100;
            default: bits=8'b00000000;
        endcase
        
        "Y": case(row)
            0: bits = 8'b01100110; //  **  **
            1: bits = 8'b01100110; //  **  **
            2: bits = 8'b00111100; //   ****
            3: bits = 8'b00011000; //    **
            4: bits = 8'b00011000; //    **
            5: bits = 8'b00011000; //    **
            6: bits = 8'b00011000; //    **
            default: bits = 8'b00000000;
        endcase

        "M": case(row)
            0: bits=8'b01100011;
            1: bits=8'b01110111;
            2: bits=8'b01111111;
            3: bits=8'b01101011;
            4: bits=8'b01100011;
            5: bits=8'b01100011;
            6: bits=8'b01100011;
            default: bits=8'b00000000;
        endcase
        "N": case(row)
            0: bits=8'b01100011;
            1: bits=8'b01110011;
            2: bits=8'b01111011;
            3: bits=8'b01101111;
            4: bits=8'b01100111;
            5: bits=8'b01100011;
            6: bits=8'b01100011;
            default: bits=8'b00000000;
        endcase
        "O": case(row)
            0: bits=8'b00111100;
            1: bits=8'b01100110;
            2: bits=8'b01100110;
            3: bits=8'b01100110;
            4: bits=8'b01100110;
            5: bits=8'b01100110;
            6: bits=8'b00111100;
            default: bits=8'b00000000;
        endcase
        "R": case(row)
            0: bits=8'b01111100;
            1: bits=8'b01100110;
            2: bits=8'b01100110;
            3: bits=8'b01111100;
            4: bits=8'b01111000;
            5: bits=8'b01101100;
            6: bits=8'b01100110;
            default: bits=8'b00000000;
        endcase
        "S": case(row)
            0: bits=8'b00111110;
            1: bits=8'b01100000;
            2: bits=8'b01100000;
            3: bits=8'b00111100;
            4: bits=8'b00000110;
            5: bits=8'b00000110;
            6: bits=8'b01111100;
            default: bits=8'b00000000;
        endcase
        "T": case(row)
            0: bits=8'b01111110;
            1: bits=8'b00011000;
            2: bits=8'b00011000;
            3: bits=8'b00011000;
            4: bits=8'b00011000;
            5: bits=8'b00011000;
            6: bits=8'b00011000;
            default: bits=8'b00000000;
        endcase
        "V": case(row)
            0: bits = 8'b01100110; //  **  **
            1: bits = 8'b01100110; //  **  **
            2: bits = 8'b01100110; //  **  **
            3: bits = 8'b01100110; //  **  **
            4: bits = 8'b00111100; //   ****
            5: bits = 8'b00011000; //    **
            6: bits = 8'b00011000; //    **
            default: bits = 8'b00000000;
        endcase

        "U": case(row)
            0: bits=8'b01100110;
            1: bits=8'b01100110;
            2: bits=8'b01100110;
            3: bits=8'b01100110;
            4: bits=8'b01100110;
            5: bits=8'b01100110;
            6: bits=8'b00111100;
            default: bits=8'b00000000;
        endcase
        "G": case(row)
            0: bits=8'b00111100; //   ****
            1: bits=8'b01100110; //  ** **
            2: bits=8'b01100000; //  **
            3: bits=8'b01101110; //  ** ***
            4: bits=8'b01100110; //  ** **
            5: bits=8'b01100110; //  ** **
            6: bits=8'b00111100; //   ****
            default: bits=8'b00000000;
        endcase

        default: bits = 8'b00000000;
    endcase
end
endmodule
