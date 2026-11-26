`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: M_IF_ID_REG
// Description: IF/ID pipeline register (16-bit MIPS)
//
// FIX (error 7): stall now has priority over flush.
//   Before, a flush (pcsrcD) during a branch stall cleared IF/ID and
//   wiped out the stalled branch itself while the PC was held, so the
//   branch was lost. Now:
//     stallD = 1  -> hold (ignore flush, data not ready yet)
//     flushD = 1  -> clear (wrong-path instruction after taken branch / jump)
//     otherwise   -> load the fetched instruction
//
//   Port renamed pcsrcD -> flushD, because in error 8 the jump also
//   flushes through this same input.
//////////////////////////////////////////////////////////////////////////////////

module M_IF_ID_REG(

    input reset,
    input flushD,                       // FIX: was pcsrcD
    input stallD,
    input clk,

    input [15:0] instr,
    input [15:0] pcplus2,

    output reg [15:0] instrD,
    output reg [15:0] pcplus2D

);

    always @(posedge clk) begin

        if (reset) begin

            instrD   <= 16'b0;
            pcplus2D <= 16'b0;

        end

        else if (!stallD) begin         // FIX: stall checked first -> hold

            if (flushD) begin

                // Flush the wrong-path instruction
                instrD   <= 16'b0;
                pcplus2D <= 16'b0;

            end

            else begin

                instrD   <= instr;
                pcplus2D <= pcplus2;

            end

        end

        // stallD = 1 : keep instrD / pcplus2D (branch stays in Decode)

    end

endmodule