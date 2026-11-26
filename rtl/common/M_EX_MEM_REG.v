`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_EX_MEM_REG
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit EX/MEM Pipeline Register
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_EX_MEM_REG(

    input clk,
    input reset,

    input [15:0] instrE,

    input regwriteE,
    input memtoregE,
    input memwriteE,

    input [15:0] aluout,
    input [15:0] writedataE,

    input [2:0] writeregE,

    output reg regwriteM,
    output reg memtoregM,
    output reg memwriteM,

    output reg [15:0] aluoutM,
    output reg [15:0] writedataM,

    output reg [2:0] writeregM,

    output reg [15:0] instrM

);

always @(posedge clk)
begin

    $display("========= EX_MEM =========");
    $display("aluout      = %h", aluout);
    $display("aluoutM old = %h", aluoutM);
    $display("memwriteE   = %b", memwriteE);
    $display("regwriteE   = %b", regwriteE);
    $display("writedataE  = %h", writedataE);
    $display("writeregE   = %d", writeregE);
    $display("instrE      = %h", instrE);

    if(reset)
    begin
        regwriteM  <= 0;
        memtoregM  <= 0;
        memwriteM  <= 0;

        aluoutM    <= 16'b0;
        writedataM <= 16'b0;

        writeregM  <= 3'b000;
        instrM     <= 16'b0;
    end

    else
    begin
        regwriteM  <= regwriteE;
        memtoregM  <= memtoregE;
        memwriteM  <= memwriteE;

        aluoutM    <= aluout;
        writedataM <= writedataE;

        writeregM  <= writeregE;
        instrM     <= instrE;
    end

end

endmodule