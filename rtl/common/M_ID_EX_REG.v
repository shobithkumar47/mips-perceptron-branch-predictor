`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_ID_EX_REG
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit ID/EX Pipeline Register
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_ID_EX_REG(

    input flushE,
    input reset,
    input clk,

    // 16-bit instruction format uses 3-bit register addresses
    input [2:0] rsD,
    input [15:0] instrD,

    input regwrite,
    input memtoreg,
    input memwrite,

    input [2:0] alucontrol,

    input alusrc,
    input regdst,

    // 16-bit datapath
    input [15:0] srca,
    input [15:0] writedata,

    input [2:0] rtD,
    input [2:0] rdD,

    // 6-bit immediate for 16-bit instruction
    input [15:0] signimmD,

    output reg regwriteE,
    output reg memtoregE,
    output reg memwriteE,

    output reg [2:0] alucontrolE,

    output reg alusrcE,
    output reg regdstE,

    output reg [15:0] srcaMUX,
    output reg [15:0] writedataMUX,

    output reg [2:0] rtE,
    output reg [2:0] rdE,

    output reg [15:0] signimmE,
    output reg [15:0] instrE,

    output reg [2:0] rsE
);

always @(posedge clk)
begin

    $display("========= ID_EX =========");
    $display("srca        = %h", srca);
    $display("writedata   = %h", writedata);
    $display("signimmD    = %h", signimmD);
    $display("alucontrol  = %b", alucontrol);
    $display("instrD      = %h", instrD);
    $display("rsD         = %d", rsD);
    $display("rtD         = %d", rtD);
    $display("rdD         = %d", rdD);
    $display("regwrite    = %b", regwrite);
    $display("memtoreg    = %b", memtoreg);
    $display("memwrite    = %b", memwrite);

    if(reset)
    begin
        regwriteE    <= 0;
        memtoregE    <= 0;
        memwriteE    <= 0;

        alucontrolE  <= 3'b000;

        alusrcE      <= 0;
        regdstE      <= 0;

        srcaMUX      <= 16'b0;
        writedataMUX <= 16'b0;

        rtE          <= 3'b000;
        rdE          <= 3'b000;
        rsE          <= 3'b000;

        signimmE     <= 16'b0;
        instrE       <= 16'b0;
    end

    else if(flushE)
    begin
        regwriteE    <= 0;
        memtoregE    <= 0;
        memwriteE    <= 0;

        alucontrolE  <= 3'b000;

        alusrcE      <= 0;
        regdstE      <= 0;

        srcaMUX      <= 16'b0;
        writedataMUX <= 16'b0;

        rtE          <= 3'b000;
        rdE          <= 3'b000;
        rsE          <= 3'b000;

        signimmE     <= 16'b0;
        instrE       <= 16'b0;
    end

    else
    begin
        regwriteE    <= regwrite;
        memtoregE    <= memtoreg;
        memwriteE    <= memwrite;

        alucontrolE  <= alucontrol;

        alusrcE      <= alusrc;
        regdstE      <= regdst;

        srcaMUX      <= srca;
        writedataMUX <= writedata;

        rtE          <= rtD;
        rdE          <= rdD;
        rsE          <= rsD;

        signimmE     <= signimmD;
        instrE       <= instrD;
    end

end

endmodule