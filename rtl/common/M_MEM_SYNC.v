`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026 13:54:45
// Design Name:
// Module Name: M_MEM_SYNC
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
// 16-bit Synchronous Data Memory
//
// FIX (error 12): memdata file loaded by file name only (parameter
//   INIT_FILE) instead of the hard-coded "D:/MIPS Project/..." path.
//   Add the file to the Vivado project.
//
//////////////////////////////////////////////////////////////////////////////////

module M_MEM_SYNC #(
    parameter RAM_SIZE  = 1024,
    parameter INIT_FILE = "memdata.mem"         // FIX: file name only
)(
    input clk,

    // Memory write enable
    input mem_write,

    // 16-bit address
    input [15:0] address,

    // 16-bit data to write
    input [15:0] write_data,

    // 16-bit data read
    output [15:0] read_data
);


    //========================================================
    // 16-BIT DATA MEMORY
    //========================================================

    reg [15:0] RAM [0:RAM_SIZE-1];


    //========================================================
    // MEMORY ADDRESS
    //========================================================

    wire [$clog2(RAM_SIZE)-1:0] addr;


    //========================================================
    // ADDRESS CALCULATION
    //
    // 16-bit data = 2 bytes
    //
    // Therefore:
    //
    // address[0] = byte offset
    // address[N:1] = memory word address
    //
    // For RAM_SIZE = 256 (as used in M_MIPS_CPU):
    //
    // address = 16 bits
    // addr    = 8 bits = address[8:1]
    //
    //========================================================

    assign addr = address[$clog2(RAM_SIZE):1];


    //========================================================
    // ASYNCHRONOUS READ
    //========================================================

    assign read_data = RAM[addr];


    //========================================================
    // INITIALIZE MEMORY
    //========================================================

    integer i;

    initial begin

        // Clear complete RAM

        for(i = 0; i < RAM_SIZE; i = i + 1)
            RAM[i] = 16'h0000;


        //====================================================
        // LOAD DATA MEMORY FILE
        //====================================================

        $display("Loading 16-bit %s ...", INIT_FILE);

        $readmemh(INIT_FILE, RAM);              // FIX: no absolute path


        //====================================================
        // DISPLAY INITIAL MEMORY CONTENT
        //====================================================

        $display("========================================");

        $display("RAM[0] = %h", RAM[0]);
        $display("RAM[1] = %h", RAM[1]);
        $display("RAM[2] = %h", RAM[2]);
        $display("RAM[3] = %h", RAM[3]);

        $display("========================================");

    end


    //========================================================
    // MEMORY WRITE / DEBUG
    //========================================================

    always @(posedge clk) begin

        if(mem_write) begin

            RAM[addr] <= write_data;

            $display(
                "WRITE MEM[%0d] = %h",
                addr,
                write_data
            );

        end

    end

endmodule