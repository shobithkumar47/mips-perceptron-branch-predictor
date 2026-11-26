`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_PC_ADDER
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit PC Adder
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_PC_ADDER(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] y
);

    assign y = a + b;

endmodule