`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: FPGA_MIPS_TOP
// Board      : EDGE Artix 7 (xc7a35tftg256-1)
// Description: FPGA top level for the 16-bit pipelined MIPS (baseline)
//
//  - Board clock -> clock divider -> slow CPU clock (watch it run)
//  - Reset push button (2-flop synchronizer)
//  - 4-digit 7-segment display, COMMON ANODE, MULTIPLEXED:
//      shared segments a..g + dp (active low)
//      digit enables DIGIT1..DIGIT4 (active low, PNP transistors)
//      shows R1 in hex  (DIGIT4 = R1[15:12] ... DIGIT1 = R1[3:0])
//  - 16 LEDs show aluoutM[15:0]
//
// CPU clock = board clock / 2^CLK_DIV_BITS
//   50 MHz / 2^24 = ~3 Hz  (test program finishes in ~30 s, R1 -> 0001)
//   use a smaller value to run faster
//////////////////////////////////////////////////////////////////////////////////

module FPGA_MIPS_TOP #(
    parameter CLK_DIV_BITS = 24
)(
    input  wire        clk,          // board oscillator
    input  wire        btn_reset,    // push button, active high

    output reg  [6:0]  seg,          // {g,f,e,d,c,b,a}, active low (shared)
    output wire        dp,           // decimal point, active low
    output reg  [3:0]  digit,        // digit[0]=DIGIT1 (right) .. digit[3]=DIGIT4 (left), active low

    output wire [15:0] led           // aluoutM[15:0]
);

    //========================================================
    // CLOCK DIVIDER (CPU clock)
    //========================================================
    reg [CLK_DIV_BITS-1:0] div_count = 0;

    always @(posedge clk)
        div_count <= div_count + 1'b1;

    wire cpu_clk;

    BUFG cpu_clk_bufg (
        .I(div_count[CLK_DIV_BITS-1]),
        .O(cpu_clk)
    );

    //========================================================
    // RESET SYNCHRONIZER (CPU clock domain)
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
    wire [6:0]  segment0, segment1, segment2, segment3;   // R1 digits (decoded)
    wire [6:0]  segment4_unused, segment5_unused;

    M_MIPS_CPU cpu (
        .clk        (cpu_clk),
        .reset      (cpu_reset),
        .writedataM (writedataM),
        .aluoutM    (aluoutM),
        .memwriteM  (memwriteM),
        .segment0   (segment0),          // R1[3:0]
        .segment1   (segment1),          // R1[7:4]
        .segment2   (segment2),          // R1[11:8]
        .segment3   (segment3),          // R1[15:12]
        .segment4   (segment4_unused),
        .segment5   (segment5_unused)
    );

    //========================================================
    // 7-SEGMENT MULTIPLEXER (board clock domain)
    //   refresh counter bits [17:16] select the digit
    //   50 MHz / 2^16 = ~763 Hz per digit -> no flicker
    //========================================================
    reg [17:0] refresh = 0;

    always @(posedge clk)
        refresh <= refresh + 1'b1;

    always @(*) begin
        case (refresh[17:16])
            2'd0: begin digit = 4'b1110; seg = segment0; end   // DIGIT1 (right)
            2'd1: begin digit = 4'b1101; seg = segment1; end   // DIGIT2
            2'd2: begin digit = 4'b1011; seg = segment2; end   // DIGIT3
            default: begin digit = 4'b0111; seg = segment3; end // DIGIT4 (left)
        endcase
    end

    assign dp = 1'b1;                    // decimal point off

    //========================================================
    // LEDS
    //========================================================
    assign led = aluoutM;

endmodule