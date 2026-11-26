`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_SEXT_6
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 6-bit to 16-bit Sign Extension
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_SEXT_6(
    input  [5:0] a,
    output [15:0] y
);

    assign y = {{10{a[5]}}, a};

endmodule