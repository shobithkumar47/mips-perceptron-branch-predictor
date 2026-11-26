`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: TB_MIPS_CPU
// Description: Testbench + performance report for the 16-bit baseline MIPS
//
// FIX (error 14):
//  1. A branch is counted only when it is actually decided (not stalled).
//     Before, a branch was counted again on every stall cycle.
//  2. "Instructions retired" counts every real instruction that reaches WB
//     (instrW != 0), including SW / BEQ / BNE / J. Before, only register
//     writes were counted, so CPI was too high.
//  3. The simulation runs until the program signals "done" by storing to
//     address 0xFFFE (sw rX, -2(r0)), with a timeout. Before, it stopped
//     after a fixed 300 ns (~30 cycles), before the program finished.
//  4. "Branch/jump flushes" counts IF/ID flushes (taken branch or jump).
//     Before, flushE was counted, which is the stall bubble, not a flush.
//  5. NEW: data memory and R1 are checked against the expected results
//     of the test program (meminstr.mem) -> TEST PASSED / FAILED.
//////////////////////////////////////////////////////////////////////////////////

module TB_MIPS_CPU;

    // =========================================================
    // DUT
    // =========================================================

    reg clk;
    reg res;

    wire [15:0] writedataM;
    wire [15:0] aluoutM;
    wire        memwriteM;

    wire [6:0] segment0;
    wire [6:0] segment1;
    wire [6:0] segment2;
    wire [6:0] segment3;
    wire [6:0] segment4;
    wire [6:0] segment5;

    M_MIPS_CPU MIPS_DUT(

        .clk        (clk),
        .reset      (res),

        .writedataM (writedataM),
        .aluoutM    (aluoutM),
        .memwriteM  (memwriteM),

        .segment0   (segment0),
        .segment1   (segment1),
        .segment2   (segment2),
        .segment3   (segment3),
        .segment4   (segment4),
        .segment5   (segment5)

    );


    // =========================================================
    // SETTINGS
    // =========================================================

    localparam [15:0] HALT_ADDR  = 16'hFFFE;   // program writes here when done
    localparam integer MAX_CYCLES = 10000;     // timeout


    // =========================================================
    // PERFORMANCE COUNTERS
    // =========================================================

    real CLOCK_PERIOD_NS;
    real CLOCK_FREQUENCY_MHZ;

    integer cycle_count;
    integer instruction_count;

    integer branch_count;
    integer taken_branch_count;
    integer not_taken_branch_count;

    integer stall_count;
    integer flush_count;
    integer forwarding_count;

    real execution_time_ns;
    real cpi;
    real throughput_ipc;
    real throughput_mips;

    reg done;


    // =========================================================
    // CLOCK  (10 ns = 100 MHz)
    // =========================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // =========================================================
    // INITIALIZE COUNTERS
    // =========================================================

    initial begin

        CLOCK_PERIOD_NS     = 10.0;
        CLOCK_FREQUENCY_MHZ = 1000.0 / CLOCK_PERIOD_NS;

        cycle_count            = 0;
        instruction_count      = 0;

        branch_count           = 0;
        taken_branch_count     = 0;
        not_taken_branch_count = 0;

        stall_count            = 0;
        flush_count            = 0;
        forwarding_count       = 0;

        done                   = 0;

    end


    // =========================================================
    // PERFORMANCE MONITOR
    // =========================================================

    always @(posedge clk) begin

        if (!res && !done) begin

            cycle_count = cycle_count + 1;

            // -------------------------------------------------
            // FIX 2: every real instruction that reaches WB.
            // Bubbles / flushed slots are 0000.
            // -------------------------------------------------
            if (MIPS_DUT.instrW != 16'h0000)
                instruction_count = instruction_count + 1;

            // -------------------------------------------------
            // FIX 1: count a branch only when it is decided
            // (not while it is stalled in Decode)
            // -------------------------------------------------
            if (MIPS_DUT.branch && !MIPS_DUT.stallD) begin

                branch_count = branch_count + 1;

                if (MIPS_DUT.pcsrcD)
                    taken_branch_count = taken_branch_count + 1;
                else
                    not_taken_branch_count = not_taken_branch_count + 1;

            end

            // Stall cycles
            if (MIPS_DUT.stallF || MIPS_DUT.stallD)
                stall_count = stall_count + 1;

            // -------------------------------------------------
            // FIX 4: IF/ID flush = taken branch or jump
            // (each one throws away 1 fetched instruction)
            // -------------------------------------------------
            if (!MIPS_DUT.stallD && (MIPS_DUT.pcsrcD || MIPS_DUT.jump))
                flush_count = flush_count + 1;

            // Forwarding events
            if ((MIPS_DUT.forwardAE != 2'b00) ||
                (MIPS_DUT.forwardBE != 2'b00))
                forwarding_count = forwarding_count + 1;

            // -------------------------------------------------
            // FIX 3: program finished (store to 0xFFFE)
            // -------------------------------------------------
            if (memwriteM && (aluoutM == HALT_ADDR))
                done = 1;

        end

    end


    // =========================================================
    // EXPECTED RESULTS OF THE TEST PROGRAM (meminstr.mem)
    // =========================================================

    reg [15:0] expected [0:17];
    integer i;
    integer errors;

    initial begin
        expected[0]  = 16'h000A;   // add
        expected[1]  = 16'h0004;   // sub
        expected[2]  = 16'h0003;   // and
        expected[3]  = 16'h0007;   // or
        expected[4]  = 16'h0004;   // xor
        expected[5]  = 16'h0001;   // slt (3 < 7)
        expected[6]  = 16'h0000;   // slt (7 < 3)
        expected[7]  = 16'h0015;   // mul 7*3 = 21
        expected[8]  = 16'h0005;   // andi
        expected[9]  = 16'h0007;   // ori
        expected[10] = 16'h0006;   // xori
        expected[11] = 16'h0000;   // slti 3 < -1
        expected[12] = 16'h0001;   // slti 3 < 10
        expected[13] = 16'h0014;   // load-use: 10 + 10
        expected[14] = 16'h000C;   // backward-branch loop
        expected[15] = 16'h000C;   // jump flush (not 31)
        expected[16] = 16'hFFFB;   // negative immediate / offset
        expected[17] = 16'h0001;   // pass marker (1 = all branches correct)
    end


    // =========================================================
    // RESET, RUN, CHECK, REPORT
    // =========================================================

    initial begin

        // Reset for 2 clock edges
        res = 1;
        #22;
        res = 0;

        // FIX 3: run until the program is done (or timeout)
        wait (done || cycle_count >= MAX_CYCLES);
        repeat (5) @(posedge clk);


        // =====================================================
        // RESULT CHECK
        // =====================================================

        errors = 0;

        $display("");
        $display("==========================================================");
        $display("                     RESULT CHECK                         ");
        $display("==========================================================");

        if (!done) begin
            $display("ERROR: program did not finish within %0d cycles", MAX_CYCLES);
            errors = errors + 1;
        end

        for (i = 0; i < 18; i = i + 1) begin
            if (MIPS_DUT.dmem.RAM[i] !== expected[i]) begin
                $display("  M[%0d] = %h   expected %h   <-- WRONG",
                         i, MIPS_DUT.dmem.RAM[i], expected[i]);
                errors = errors + 1;
            end
            else
                $display("  M[%0d] = %h   OK", i, MIPS_DUT.dmem.RAM[i]);
        end

        if (MIPS_DUT.rf.rf[1] !== 16'h0001) begin
            $display("  R1 = %h   expected 0001 (7-segment PASS value)  <-- WRONG",
                     MIPS_DUT.rf.rf[1]);
            errors = errors + 1;
        end
        else
            $display("  R1 = %h   OK (7-segment shows 0001)", MIPS_DUT.rf.rf[1]);


        // =====================================================
        // CALCULATE PERFORMANCE
        // =====================================================

        execution_time_ns = cycle_count * CLOCK_PERIOD_NS;

        if (instruction_count > 0) begin
            cpi             = cycle_count * 1.0 / instruction_count;
            throughput_ipc  = instruction_count * 1.0 / cycle_count;
            throughput_mips = instruction_count / (execution_time_ns / 1000.0);
        end
        else begin
            cpi             = 0.0;
            throughput_ipc  = 0.0;
            throughput_mips = 0.0;
        end


        // =====================================================
        // PERFORMANCE REPORT
        // =====================================================

        $display("");
        $display("==========================================================");
        $display("          16-BIT BASELINE MIPS PERFORMANCE REPORT         ");
        $display("==========================================================");

        $display("");
        $display("--------------- CLOCK PERFORMANCE -----------------------");
        $display("Clock Period              = %.2f ns",  CLOCK_PERIOD_NS);
        $display("Clock Frequency           = %.2f MHz", CLOCK_FREQUENCY_MHZ);

        $display("");
        $display("--------------- EXECUTION PERFORMANCE ------------------");
        $display("Total Clock Cycles        = %0d",      cycle_count);
        $display("Instructions Retired      = %0d",      instruction_count);
        $display("CPI                       = %.3f",     cpi);
        $display("Execution Time            = %.2f ns",  execution_time_ns);
        $display("IPC                       = %.3f",     throughput_ipc);
        $display("Throughput                = %.3f MIPS",throughput_mips);

        $display("");
        $display("--------------- BRANCH PERFORMANCE ---------------------");
        $display("Total Branches            = %0d", branch_count);
        $display("Taken Branches            = %0d", taken_branch_count);
        $display("Not-Taken Branches        = %0d", not_taken_branch_count);
        if (branch_count > 0)
            $display("Static not-taken accuracy = %.2f %%",
                     not_taken_branch_count * 100.0 / branch_count);

        $display("");
        $display("--------------- PIPELINE PERFORMANCE -------------------");
        $display("Pipeline Stall Cycles     = %0d", stall_count);
        $display("Branch/Jump Flushes       = %0d", flush_count);
        $display("Forwarding Events         = %0d", forwarding_count);

        $display("");
        $display("==========================================================");
        if (errors == 0)
            $display("                    TEST PASSED                           ");
        else
            $display("              TEST FAILED  (%0d errors)                   ", errors);
        $display("==========================================================");
        $display("");

        $finish;

    end

endmodule