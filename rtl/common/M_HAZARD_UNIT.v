`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 15.06.2026 13:50:25
// Design Name: 16-bit MIPS
// Module Name: M_HAZARD_UNIT
// Project Name:
// Target Devices:
// Tool Versions:
// Description: 16-bit Hazard Detection and Forwarding Unit
//
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - FIX (error 10): every register match in the stall logic
//                 now excludes R0. A flushed slot (instruction 0000) looks
//                 like "add r0,r0,r0" with regwrite = 1, which caused false
//                 branch stalls for branches that read r0
//                 (e.g. "bne r3, r0, loop").
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module M_HAZARD_UNIT (
    input branch,

    input memtoregE,
    input memtoregM,

    // 3-bit register addresses for 8-register 16-bit MIPS
    input [2:0] rsD,
    input [2:0] rtD,

    input regwriteE,
    input regwriteM,
    input regwriteW,

    input [2:0] rsE,
    input [2:0] rtE,

    input [2:0] writeregE,
    input [2:0] writeregM,
    input [2:0] writeregW,

    output reg [1:0] forwardAE,
    output reg [1:0] forwardBE,

    output reg stallF,
    output reg stallD,
    output reg flushE,

    output reg forwardAD,
    output reg forwardBD
);

    reg lwstall;
    reg branchstall;

    always @(*) begin

        //==========================================================
        // FORWARDING LOGIC - EX STAGE
        //   10 = forward from EX/MEM (aluoutM)
        //   01 = forward from MEM/WB (result)
        //==========================================================

        if((rsE != 3'b000) &&
           (rsE == writeregM) &&
           regwriteM)

            forwardAE = 2'b10;

        else if((rsE != 3'b000) &&
                (rsE == writeregW) &&
                regwriteW)

            forwardAE = 2'b01;

        else

            forwardAE = 2'b00;


        if((rtE != 3'b000) &&
           (rtE == writeregM) &&
           regwriteM)

            forwardBE = 2'b10;

        else if((rtE != 3'b000) &&
                (rtE == writeregW) &&
                regwriteW)

            forwardBE = 2'b01;

        else

            forwardBE = 2'b00;


        //==========================================================
        // LOAD-USE HAZARD
        // Instruction in D needs a value that a LW in E is still loading
        //==========================================================

        lwstall =
            memtoregE &&
            (rtE != 3'b000) &&                      // FIX: R0 never needs a stall
            ((rsD == rtE) || (rtD == rtE));


        //==========================================================
        // FORWARDING FOR BRANCH COMPARISON
        // (MEM/WB is covered by the negedge register-file write)
        //==========================================================

        forwardAD =
            ((rsD != 3'b000) &&
             (rsD == writeregM) &&
             regwriteM);

        forwardBD =
            ((rtD != 3'b000) &&
             (rtD == writeregM) &&
             regwriteM);


        //==========================================================
        // BRANCH HAZARD
        // Branch in D needs a result that is not ready yet:
        //  - ALU result still in E, or
        //  - LW result still in M
        //==========================================================

        branchstall =
            (branch &&
             regwriteE &&
             (writeregE != 3'b000) &&               // FIX: R0 never needs a stall
             ((writeregE == rsD) ||
              (writeregE == rtD)))

            ||

            (branch &&
             memtoregM &&
             (writeregM != 3'b000) &&               // FIX: R0 never needs a stall
             ((writeregM == rsD) ||
              (writeregM == rtD)));


        //==========================================================
        // STALL / FLUSH CONTROL
        //==========================================================

        stallF = lwstall || branchstall;

        stallD = lwstall || branchstall;

        flushE = lwstall || branchstall;

    end


    //==============================================================
    // DEBUG: LOAD-USE STALL
    //==============================================================

    always @(lwstall)
    begin
        case(lwstall)

            1'b1:
                $display("lwstall = %b", lwstall);

        endcase
    end


    //==============================================================
    // DEBUG: BRANCH STALL
    //==============================================================

    always @(branchstall)
    begin
        case(branchstall)

            1'b1:
                $display("branchstall = %b", branchstall);

        endcase
    end

endmodule