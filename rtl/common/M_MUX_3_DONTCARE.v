`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_MUX_3_DONTCARE
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit 3-to-1 Multiplexer (forwarding mux)
//
//   s = 00 : d0  (value from register file / ID-EX register)
//   s = 01 : d1  (forwarded from MEM/WB)
//   s = 10 : d2  (forwarded from EX/MEM)
//   s = 11 : d0  (not used by the hazard unit)
//
// FIX (error 9): there was no case for s = 2'b11 and no default, so
//   Vivado inferred a 16-bit latch for y ([Synth 8-327]). A default
//   branch is added, the "2'bxx" item is removed (x does not exist in
//   hardware), and blocking "=" is used for combinational logic.
//
//////////////////////////////////////////////////////////////////////////////////

module M_MUX_3_DONTCARE(
    input  [15:0] d0,
    input  [15:0] d1,
    input  [15:0] d2,

    input  [1:0] s,

    output reg [15:0] y
);

    always @(*)
    begin
        case(s)

            2'b01:   y = d1;
            2'b10:   y = d2;
            default: y = d0;    // FIX: covers 00 and 11 -> no latch

        endcase
    end

endmodule