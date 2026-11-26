`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026 13:47:33
// Design Name: 16-bit MIPS
// Module Name: M_EQUAL
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Equality Comparator
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_EQUAL(
    input  [15:0] srca,
    input  [15:0] writedata,
    output        equalD
);

    assign equalD = (srca == writedata);

    always @(*)
    begin
        $display("==== EQUAL ====");
        $display("srca      = %h", srca);
        $display("writedata = %h", writedata);
        $display("equalD    = %b", equalD);
    end

endmodule