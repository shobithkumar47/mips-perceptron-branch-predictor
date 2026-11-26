`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_REG_FILE
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Register File
//
// 8 registers:
// R0 = constant zero
// R1-R7 = general purpose registers
//
// Dependencies:
// M_7SEG_DECODER
//
// FIX: rf[0] was also assigned in a posedge always block, which made the
//      register array multi-driven (Vivado multi-driven net / DRC MDRV-1).
//      Removed: R0 already reads as 0 and writes to R0 are already blocked.
//
//////////////////////////////////////////////////////////////////////////////////

module M_REG_FILE(
    input clk,
    input reg_write,

    input [2:0] read_reg1,
    input [2:0] read_reg2,
    input [2:0] write_reg,

    input [15:0] write_data,

    output [15:0] read_data1,
    output [15:0] read_data2,

    output [6:0] segment0,
    output [6:0] segment1,
    output [6:0] segment2,
    output [6:0] segment3,
    output [6:0] segment4,
    output [6:0] segment5
);

    // 8 registers × 16 bits
    reg [15:0] rf [7:0];

    reg [3:0] hex_num_0;
    reg [3:0] hex_num_1;
    reg [3:0] hex_num_2;
    reg [3:0] hex_num_3;
    reg [3:0] hex_num_4;
    reg [3:0] hex_num_5;

    integer i;

    initial begin

        for(i = 0; i < 8; i = i + 1)
            rf[i] = 16'h0000;

        hex_num_0 = 4'h0;
        hex_num_1 = 4'h0;
        hex_num_2 = 4'h0;
        hex_num_3 = 4'h0;
        hex_num_4 = 4'h0;
        hex_num_5 = 4'h0;

    end

    // Double-pumped register file
    // Write occurs on negative edge of clock
    // This is the ONLY always block that writes rf[]
    always @(negedge clk)
    begin

        if(reg_write && (write_reg != 3'b000))
        begin

            rf[write_reg] <= write_data;

            // Display data from register R1
            if(write_reg == 3'b001)
            begin
                $display("----------------------------------------------------------");
                $display("Data is being written to R1 = %h", write_data);
                $display("----------------------------------------------------------");

                // 16-bit data requires only 4 hexadecimal digits
                hex_num_0 <= write_data[3:0];
                hex_num_1 <= write_data[7:4];
                hex_num_2 <= write_data[11:8];
                hex_num_3 <= write_data[15:12];

                // Remaining displays cleared
                hex_num_4 <= 4'h0;
                hex_num_5 <= 4'h0;
            end

            $display("content of R%0d = %h", write_reg, write_data);
        end

    end

    // Register R0 is always zero (read side)
    assign read_data1 =
        (read_reg1 != 3'b000) ? rf[read_reg1] : 16'h0000;

    assign read_data2 =
        (read_reg2 != 3'b000) ? rf[read_reg2] : 16'h0000;


    // FIX: debug print only - no assignment to rf[] here any more
    always @(posedge clk)
    begin

        $display("--------------------------------");
        $display("READ R%0d = %h", read_reg1, read_data1);
        $display("READ R%0d = %h", read_reg2, read_data2);
        $display("WRITE EN = %b", reg_write);
        $display("WRITE REG = %0d", write_reg);
        $display("WRITE DATA = %h", write_data);

    end


    // 7-segment displays
    M_7SEG_DECODER display_0(hex_num_0, segment0);
    M_7SEG_DECODER display_1(hex_num_1, segment1);
    M_7SEG_DECODER display_2(hex_num_2, segment2);
    M_7SEG_DECODER display_3(hex_num_3, segment3);
    M_7SEG_DECODER display_4(hex_num_4, segment4);
    M_7SEG_DECODER display_5(hex_num_5, segment5);

endmodule