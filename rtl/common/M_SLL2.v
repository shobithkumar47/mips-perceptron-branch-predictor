`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_SLL2
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Branch Offset Shift
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_SLL2(
    input  [15:0] a,
    output [15:0] y
);

    // Shift left by 1
    // 16-bit instructions = 2 bytes
    assign y = {a[14:0], 1'b0};

endmodule