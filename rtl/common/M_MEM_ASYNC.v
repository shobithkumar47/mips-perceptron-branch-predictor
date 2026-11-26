`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026 13:12:44
// Design Name:
// Module Name: M_MEM_ASYNC
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
// 16-bit Asynchronous Instruction Memory
//
// FIX (error 12): the program file was loaded from a hard-coded path
//   "D:/MIPS Project/.../meminstr.dat". If that path is not found, Vivado
//   only warns, leaves the memory empty and removes the whole CPU.
//   Now only the file name is used (parameter INIT_FILE). Add the file
//   to the Vivado project (Add Sources) so synthesis and simulation
//   both find it, wherever the project folder is.
//
//////////////////////////////////////////////////////////////////////////////////

module M_MEM_ASYNC #(
    parameter RAM_SIZE  = 1024,
    parameter INIT_FILE = "meminstr.mem"        // FIX: file name only
)(
    input clk,

    // Address width depends on RAM_SIZE
    input [$clog2(RAM_SIZE)-1:0] address,

    // 16-bit instruction output
    output [15:0] instruction
);

    //========================================================
    // 16-BIT INSTRUCTION MEMORY
    //========================================================

    reg [15:0] RAM [0:RAM_SIZE-1];

    //========================================================
    // ADDRESS
    //========================================================

    wire [$clog2(RAM_SIZE)-1:0] addr;

    assign addr = address;

    //========================================================
    // ASYNCHRONOUS READ
    //========================================================

    assign instruction = RAM[addr];

    //========================================================
    // INITIALIZE MEMORY
    //========================================================

    integer i;

    initial begin

        // Clear complete memory
        for(i = 0; i < RAM_SIZE; i = i + 1)
            RAM[i] = 16'h0000;

        //====================================================
        // LOAD 16-BIT INSTRUCTIONS
        //====================================================

        $display("Loading 16-bit %s ...", INIT_FILE);

        $readmemh(INIT_FILE, RAM);              // FIX: no absolute path

        //====================================================
        // DISPLAY FIRST INSTRUCTIONS
        //====================================================

        $display("========================================");
        $display("16-BIT INSTRUCTION MEMORY");
        $display("========================================");

        $display("IMEM[0] = %h", RAM[0]);
        $display("IMEM[1] = %h", RAM[1]);
        $display("IMEM[2] = %h", RAM[2]);
        $display("IMEM[3] = %h", RAM[3]);

        $display("========================================");

    end

    //========================================================
    // DEBUG
    //========================================================

    always @(posedge clk) begin

        $display(
            "IMEM address=%0d instruction=%h",
            addr,
            instruction
        );

    end

endmodule