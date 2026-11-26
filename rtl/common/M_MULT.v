`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_MULT
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Parameterized Multiplier
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_MULT #(
    parameter N = 16
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    output [N-1:0] product
);

    assign product = a * b;

endmodule