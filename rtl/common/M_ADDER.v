`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_ADDER
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Parameterized Adder
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_ADDER #(
    parameter N = 16
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          c,
    output [N-1:0] sum,
    output         carry
);

    assign {carry, sum} = a + b + c;

endmodule