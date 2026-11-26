`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_MUX_2_DONTCARE
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 2-to-1 Multiplexer (parameterized width, default 16-bit)
//
//   s = 0 : y = d0
//   s = 1 : y = d1
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Cleanup: removed the "1'bx" case item (x does not exist in
//                 hardware, synthesis ignores it) and replaced the
//                 non-blocking "<=" in combinational logic with a simple
//                 continuous assignment. Same behaviour, same ports.
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_MUX_2_DONTCARE #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] d0,
    input  [WIDTH-1:0] d1,
    input              s,
    output [WIDTH-1:0] y
);

    assign y = s ? d1 : d0;

endmodule