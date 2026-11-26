`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 13:33:50
// Design Name: 16-bit MIPS
// Module Name: M_7SEG_DECODER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Hex digit -> 7-segment pattern
//
//   segment = {g, f, e, d, c, b, a}, ACTIVE LOW (0 = segment ON)
//
//        a
//       ---
//    f |   | b
//       -g-
//    e |   | c
//       ---
//        d
//
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - FIX (error 13): letter "A" had segment g off
//                 (7'b100_1000 -> 7'b000_1000). casex -> case.
// Additional Comments:
//   If your board's display is ACTIVE HIGH (common cathode), invert the
//   output in the top module:  assign seg_pins = ~segment;
// 
//////////////////////////////////////////////////////////////////////////////////


module M_7SEG_DECODER(
    input      [3:0] hex_num,
    output reg [6:0] segment
);
    always @(*) begin
        case (hex_num)                                 // FIX: was casex
            4'h0: segment = 7'b100_0000;  // 0
            4'h1: segment = 7'b111_1001;  // 1
            4'h2: segment = 7'b010_0100;  // 2
            4'h3: segment = 7'b011_0000;  // 3
            4'h4: segment = 7'b001_1001;  // 4
            4'h5: segment = 7'b001_0010;  // 5
            4'h6: segment = 7'b000_0010;  // 6
            4'h7: segment = 7'b111_1000;  // 7
            4'h8: segment = 7'b000_0000;  // 8
            4'h9: segment = 7'b001_0000;  // 9
            4'hA: segment = 7'b000_1000;  // A     FIX: g segment ON
            4'hB: segment = 7'b000_0011;  // b
            4'hC: segment = 7'b100_0110;  // C
            4'hD: segment = 7'b010_0001;  // d
            4'hE: segment = 7'b000_0110;  // E
            4'hF: segment = 7'b000_1110;  // F
            default: segment = 7'b111_1111;  // all OFF
        endcase
    end
endmodule