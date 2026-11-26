`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_PC_REG
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Program Counter Register
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_PC_REG #(
    parameter WIDTH = 16
)(
    input stallF,
    input clk,
    input reset,

    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);

always @(posedge clk or posedge reset)
begin
    if(reset)
        q <= {WIDTH{1'b0}};

    else if(!stallF)
        q <= d;

    else
        q <= q;      // hold PC
end

endmodule