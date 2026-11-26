`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: FPGA_MIPS_TOP
// Description: FPGA top level for the 16-bit pipelined MIPS (baseline)
//
// FIX: the old top was a 1-bit adder demo and did not contain the CPU.
//      This top instantiates M_MIPS_CPU and adds:
//        - board clock input + clock divider (slow CPU clock so the
//          7-segment display can be followed by eye)
//        - reset button with a 2-flop synchronizer
//        - 7-segment outputs (R1 in hex) and status LEDs
//
// Set CLK_DIV_BITS for your board:
//   CPU clock = board clock / 2^CLK_DIV_BITS
//   e.g. 100 MHz / 2^24 = ~6 Hz  (one instruction step visible per blink)
//        use a small value (e.g. 1) to run at full speed
//////////////////////////////////////////////////////////////////////////////////

module FPGA_MIPS_TOP #(
    parameter CLK_DIV_BITS = 24
)(
    input  wire       clk,          // board oscillator
    input  wire       btn_reset,    // push button, active high

    output wire [6:0] segment0,     // R1[3:0]
    output wire [6:0] segment1,     // R1[7:4]
    output wire [6:0] segment2,     // R1[11:8]
    output wire [6:0] segment3,     // R1[15:12]

    output wire [7:0] led           // led[7:0] = aluoutM[7:0]
);

    //========================================================
    // CLOCK DIVIDER
    //========================================================
    reg [CLK_DIV_BITS-1:0] div_count = 0;

    always @(posedge clk)
        div_count <= div_count + 1'b1;

    wire cpu_clk_raw = div_count[CLK_DIV_BITS-1];
    wire cpu_clk;

    // Put the divided clock on a global clock buffer
    BUFG cpu_clk_bufg (
        .I(cpu_clk_raw),
        .O(cpu_clk)
    );

    //========================================================
    // RESET SYNCHRONIZER (in the CPU clock domain)
    //========================================================
    reg [1:0] reset_sync = 2'b11;

    always @(posedge cpu_clk)
        reset_sync <= {reset_sync[0], btn_reset};

    wire cpu_reset = reset_sync[1];

    //========================================================
    // MIPS CPU
    //========================================================
    wire [15:0] writedataM;
    wire [15:0] aluoutM;
    wire        memwriteM;
    wire [6:0]  segment4_unused;
    wire [6:0]  segment5_unused;

    M_MIPS_CPU cpu (
        .clk        (cpu_clk),
        .reset      (cpu_reset),
        .writedataM (writedataM),
        .aluoutM    (aluoutM),
        .memwriteM  (memwriteM),
        .segment0   (segment0),
        .segment1   (segment1),
        .segment2   (segment2),
        .segment3   (segment3),
        .segment4   (segment4_unused),   // 16-bit value needs only 4 digits
        .segment5   (segment5_unused)
    );

    //========================================================
    // STATUS LEDS
    //========================================================
    assign led = aluoutM[7:0];

endmodule