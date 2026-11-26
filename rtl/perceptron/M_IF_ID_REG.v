`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: M_IF_ID_REG  (PERCEPTRON version)
// Description: IF/ID pipeline register (16-bit MIPS)
//
// Carries the Fetch-stage prediction (predTaken) and the history snapshot
// (hist) with the instruction, so Decode can resolve and train with exactly
// what Fetch used.
//
// Stall has priority over flush (same as the fixed baseline):
//   stallD = 1  -> hold (branch stays in Decode, data not ready yet)
//   flushD = 1  -> clear (wrong-path instruction: misprediction / jump)
//   otherwise   -> load the fetched instruction
//////////////////////////////////////////////////////////////////////////////////

module M_IF_ID_REG(

    input reset,
    input flushD,
    input stallD,
    input clk,

    input [15:0] instr,
    input [15:0] pcplus2,

    input        predTakenF,        // PERCEPTRON: prediction made in Fetch
    input [1:0]  histF,             // PERCEPTRON: history used for it

    output reg [15:0] instrD,
    output reg [15:0] pcplus2D,

    output reg        predTakenD,   // PERCEPTRON: prediction, now in Decode
    output reg [1:0]  histD         // PERCEPTRON: history, now in Decode

);

    always @(posedge clk) begin

        if (reset) begin

            instrD     <= 16'b0;
            pcplus2D   <= 16'b0;
            predTakenD <= 1'b0;
            histD      <= 2'b00;

        end

        else if (!stallD) begin             // stall checked first -> hold

            if (flushD) begin

                instrD     <= 16'b0;
                pcplus2D   <= 16'b0;
                predTakenD <= 1'b0;
                histD      <= 2'b00;

            end

            else begin

                instrD     <= instr;
                pcplus2D   <= pcplus2;
                predTakenD <= predTakenF;
                histD      <= histF;

            end

        end

        // stallD = 1 : keep everything

    end

endmodule