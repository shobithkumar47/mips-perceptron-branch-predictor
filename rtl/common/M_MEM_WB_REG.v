`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_MEM_WB_REG
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit MEM/WB Pipeline Register
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_MEM_WB_REG(

    input clk,
    input reset,

    input [15:0] instrM,

    input regwriteM,
    input memtoregM,

    input [15:0] aluoutM,
    input [15:0] readdata,

    input [2:0] writeregM,

    output reg regwriteW,
    output reg memtoregW,

    output reg [15:0] aluoutW,
    output reg [15:0] readdataW,

    output reg [2:0] writeregW,

    output reg [15:0] instrW

);

always @(posedge clk)
begin

    if(reset)
    begin
        regwriteW <= 0;
        memtoregW <= 0;

        aluoutW   <= 16'b0;
        readdataW <= 16'b0;

        writeregW <= 3'b000;
        instrW    <= 16'b0;
    end

    else
    begin
        regwriteW <= regwriteM;
        memtoregW <= memtoregM;

        aluoutW   <= aluoutM;
        readdataW <= readdata;

        writeregW <= writeregM;
        instrW    <= instrM;
    end

end

endmodule