`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026 13:43:59
// Design Name:
// Module Name: M_CONTROLLER
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
// 16-bit MIPS Controller
//
// Instruction format:
//
// 15        12 11       9 8        6 5        3 2        0
// +-----------+----------+----------+----------+----------+
// |  opcode   |    rs    |    rt    |    rd    |  funct   |
// +-----------+----------+----------+----------+----------+
//
// Opcode = 4 bits
//
// FIX:
//  - aluop widened from 2 to 3 bits so ANDI / ORI / XORI / SLTI can select
//    their own ALU operation (before, ANDI/ORI/XORI used aluop=11, which
//    took the ALU operation from the immediate bits, and SLTI did ADD)
//  - new output "bne" so BNE branches when NOT equal (it was identical
//    to BEQ)
//
// aluop:
//  000 = ADD   (ADDI, LW, SW)
//  001 = SUB   (BEQ, BNE)
//  010 = R-type (use funct)
//  011 = AND   (ANDI)
//  100 = OR    (ORI)
//  101 = XOR   (XORI)
//  110 = SLT   (SLTI)
//
//////////////////////////////////////////////////////////////////////////////////

module M_CONTROLLER(

    input [3:0] opcode,

    output memtoreg,
    output memwrite,
    output branch,
    output bne,                 // FIX: new - 1 for BNE, 0 for BEQ
    output alusrc,
    output regdst,
    output regwrite,
    output jump,

    output [2:0] aluop          // FIX: was [1:0]

);


    //========================================================
    // CONTROL SIGNALS
    //
    // {regwrite,
    //  regdst,
    //  alusrc,
    //  branch,
    //  bne,
    //  memwrite,
    //  memtoreg,
    //  jump,
    //  aluop[2:0]}
    //
    // Total = 11 bits
    //========================================================

    reg [10:0] controls;


    //========================================================
    // CONTROL SIGNAL ASSIGNMENT
    //========================================================

    assign {
        regwrite,
        regdst,
        alusrc,
        branch,
        bne,
        memwrite,
        memtoreg,
        jump,
        aluop
    } = controls;


    //========================================================
    // 16-BIT OPCODES
    //========================================================

    localparam OP_RTYPE = 4'b0000;
    localparam OP_ADDI  = 4'b0001;
    localparam OP_ANDI  = 4'b0010;
    localparam OP_ORI   = 4'b0011;
    localparam OP_LW    = 4'b0100;
    localparam OP_SW    = 4'b0101;
    localparam OP_BEQ   = 4'b0110;
    localparam OP_BNE   = 4'b0111;
    localparam OP_J     = 4'b1000;
    localparam OP_SLTI  = 4'b1001;
    localparam OP_XORI  = 4'b1010;
    localparam OP_NOP   = 4'b1111;


    //========================================================
    // CONTROLLER
    //
    //            regwrite regdst alusrc branch bne memwrite memtoreg jump aluop
    //========================================================

    always @(*) begin

        case(opcode)

            // R-TYPE: ADD SUB AND OR XOR SLT MUL      rd = rs op rt
            OP_RTYPE: controls = 11'b1_1_0_0_0_0_0_0_010;

            // ADDI                                    rt = rs + imm
            OP_ADDI:  controls = 11'b1_0_1_0_0_0_0_0_000;

            // ANDI                                    rt = rs & imm
            OP_ANDI:  controls = 11'b1_0_1_0_0_0_0_0_011;

            // ORI                                     rt = rs | imm
            OP_ORI:   controls = 11'b1_0_1_0_0_0_0_0_100;

            // XORI                                    rt = rs ^ imm
            OP_XORI:  controls = 11'b1_0_1_0_0_0_0_0_101;

            // SLTI                                    rt = (rs < imm) ? 1 : 0
            OP_SLTI:  controls = 11'b1_0_1_0_0_0_0_0_110;

            // LW                                      rt = MEM[rs + imm]
            OP_LW:    controls = 11'b1_0_1_0_0_0_1_0_000;

            // SW                                      MEM[rs + imm] = rt
            OP_SW:    controls = 11'b0_0_1_0_0_1_0_0_000;

            // BEQ                                     branch if rs == rt
            OP_BEQ:   controls = 11'b0_0_0_1_0_0_0_0_001;

            // BNE                                     branch if rs != rt
            OP_BNE:   controls = 11'b0_0_0_1_1_0_0_0_001;

            // J
            OP_J:     controls = 11'b0_0_0_0_0_0_0_1_000;

            // NOP
            OP_NOP:   controls = 11'b0_0_0_0_0_0_0_0_000;

            // ILLEGAL OPCODE
            default:  controls = 11'b0_0_0_0_0_0_0_0_000;

        endcase

    end


endmodule