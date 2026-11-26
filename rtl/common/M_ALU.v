`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_ALU
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit ALU
//
// Dependencies:
// M_ADDER.v
// M_MULT.v
//
// ALU Control:
// 000 = AND
// 001 = OR
// 010 = ADD
// 110 = SUB
// 011 = MUL
// 100 = XOR
// 111 = SLT (signed: result = 1 if a < b, else 0)
//
// FIX: the case statement decoded only alucontrol[1:0], so
//      XOR (100) did AND and SLT (111) did SUB.
//      All 3 bits are decoded now, and XOR / SLT are implemented.
//
//////////////////////////////////////////////////////////////////////////////////

module M_ALU(
    input  [15:0] a,
    input  [15:0] b,
    input  [2:0]  alucontrol,
    output reg [15:0] result
);

    wire [15:0] condinvb;
    wire [15:0] sum;
    wire [15:0] product;
    wire carry;

    // For subtraction:
    // condinvb = ~b
    // carry-in = 1
    //
    // For addition:
    // condinvb = b
    // carry-in = 0
    assign condinvb = alucontrol[2] ? ~b : b;

    // 16-bit adder
    M_ADDER #(.N(16)) adder(
        a,
        condinvb,
        alucontrol[2],
        sum,
        carry
    );

    // 16-bit multiplier
    M_MULT #(.N(16)) multiplier(
        a,
        b,
        product
    );

    always @(*)
    begin
        case (alucontrol)               // FIX: all 3 bits

            // AND
            3'b000:
                result = a & b;

            // OR
            3'b001:
                result = a | b;

            // ADD
            3'b010:
                result = sum;

            // SUB
            3'b110:
                result = sum;

            // MUL
            3'b011:
                result = product;

            // XOR                       // FIX: new
            3'b100:
                result = a ^ b;

            // SLT (signed)              // FIX: new
            3'b111:
                result = {15'b0, ($signed(a) < $signed(b))};

            // unused code (101)
            default:
                result = 16'b0;

        endcase
    end

endmodule