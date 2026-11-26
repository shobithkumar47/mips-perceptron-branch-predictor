`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_MUX_2
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit 2-to-1 Multiplexer
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_MUX_2 #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              s,
    output [WIDTH-1:0] y
);

    assign y = s ? d1 : d0;

endmodule