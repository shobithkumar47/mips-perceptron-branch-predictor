`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026
// Design Name: 16-bit MIPS
// Module Name: M_ALU_CONTROLLER
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit ALU Controller
//
// aluop (from M_CONTROLLER):
// 000 = ADD   (ADDI, LW, SW)
// 001 = SUB   (BEQ, BNE)
// 010 = R-type -> use funct
// 011 = AND   (ANDI)
// 100 = OR    (ORI)
// 101 = XOR   (XORI)
// 110 = SLT   (SLTI)
//
// 16-bit funct encoding (R-type):
// 000 = ADD
// 001 = SUB
// 010 = AND
// 011 = OR
// 100 = XOR
// 101 = SLT
// 110 = MUL
// 111 = Reserved
//
// alucontrol (to M_ALU):
// 000 AND, 001 OR, 010 ADD, 110 SUB, 011 MUL, 100 XOR, 111 SLT
//
// FIX: aluop is 3 bits. Before, aluop=11 (ANDI/ORI/XORI) fell into the
//      R-type default and used the immediate bits as funct.
//////////////////////////////////////////////////////////////////////////////////

module M_ALU_CONTROLLER(
    input  [2:0] funct,
    input  [2:0] aluop,                    // FIX: was [1:0]
    output reg [2:0] alucontrol
);

    always @(*) begin

        case(aluop)

            // ADDI, LW, SW
            3'b000:
                alucontrol = 3'b010;   // ADD

            // BEQ, BNE
            3'b001:
                alucontrol = 3'b110;   // SUB

            // ANDI                    // FIX: new
            3'b011:
                alucontrol = 3'b000;   // AND

            // ORI                     // FIX: new
            3'b100:
                alucontrol = 3'b001;   // OR

            // XORI                    // FIX: new
            3'b101:
                alucontrol = 3'b100;   // XOR

            // SLTI                    // FIX: new
            3'b110:
                alucontrol = 3'b111;   // SLT

            // R-type instructions (aluop = 010)
            default: begin

                case(funct)

                    3'b000:
                        alucontrol = 3'b010;   // ADD

                    3'b001:
                        alucontrol = 3'b110;   // SUB

                    3'b010:
                        alucontrol = 3'b000;   // AND

                    3'b011:
                        alucontrol = 3'b001;   // OR

                    3'b100:
                        alucontrol = 3'b100;   // XOR

                    3'b101:
                        alucontrol = 3'b111;   // SLT

                    3'b110:
                        alucontrol = 3'b011;   // MUL

                    default:
                        alucontrol = 3'b010;   // ADD

                endcase

            end

        endcase

    end

endmodule