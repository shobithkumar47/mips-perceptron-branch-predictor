`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: perceptron
// Description: Perceptron branch predictor (ML model) for the 16-bit MIPS
//
//   3 weights, inputs are the last 2 branch outcomes (+1 taken, -1 not taken)
//
//   x1,x2   : LIVE history used to PREDICT   (Fetch stage)
//   tx1,tx2 : SNAPSHOT history used to TRAIN (travels with the branch to Decode)
//
//   y = bias + w1*x1 + w2*x2          predict TAKEN if y >= 0
//
// Training (perceptron learning rule, Jimenez & Lin, HPCA 2001):
//   When a branch resolves, recompute y with the snapshot history (ty).
//   Update the weights if the perceptron was WRONG, or if it was right but
//   NOT CONFIDENT (|ty| <= THETA):
//       bias += t,   w_i += t * x_i      (t = +1 taken, -1 not taken)
//
// FIX (P16): the old version only trained on a misprediction, so it never
//            became confident and kept flipping (63% accuracy -> now ~81%).
//
// Weights saturate at -128..127. No multipliers needed (inputs are +/-1).
//////////////////////////////////////////////////////////////////////////////////

module perceptron #(
    parameter THETA = 17                 // floor(1.93 * history_length + 14), history_length = 2
)(
    input clk,
    input reset,

    // prediction history (live, Fetch)
    input signed [7:0] x1,
    input signed [7:0] x2,

    // training history (snapshot, Decode)
    input signed [7:0] tx1,
    input signed [7:0] tx2,

    input actual,            // 1 = branch was TAKEN
    input train,             // 1 = a branch is resolved this cycle

    output signed [7:0]  w1,
    output signed [7:0]  w2,
    output signed [7:0]  bias,
    output signed [15:0] sum,
    output               prediction
);

    reg signed [7:0] w1_reg;
    reg signed [7:0] w2_reg;
    reg signed [7:0] bias_reg;


    //========================================================
    // SATURATING ADD (keeps weights in -128..127)
    //========================================================

    function signed [7:0] sat_add;
        input signed [7:0] a;
        input signed [7:0] b;
        reg   signed [8:0] t;
        begin
            t = a + b;
            if (t > 9'sd127)        sat_add = 8'sd127;
            else if (t < -9'sd128)  sat_add = -8'sd128;
            else                    sat_add = t[7:0];
        end
    endfunction


    // sign-extend weights to 16 bits
    wire signed [15:0] w1_ext = {{8{w1_reg[7]}},   w1_reg};
    wire signed [15:0] w2_ext = {{8{w2_reg[7]}},   w2_reg};
    wire signed [15:0] b_ext  = {{8{bias_reg[7]}}, bias_reg};


    //========================================================
    // PREDICTION (Fetch) - live history
    // x is +1 / -1, so x*w is just +w or -w
    //========================================================

    wire signed [15:0] mult1 = x1[7] ? -w1_ext : w1_ext;
    wire signed [15:0] mult2 = x2[7] ? -w2_ext : w2_ext;

    assign sum        = mult1 + mult2 + b_ext;
    assign prediction = (sum >= 0);


    //========================================================
    // TRAINING (Decode) - snapshot history
    //========================================================

    wire signed [15:0] tmult1 = tx1[7] ? -w1_ext : w1_ext;
    wire signed [15:0] tmult2 = tx2[7] ? -w2_ext : w2_ext;
    wire signed [15:0] tsum   = tmult1 + tmult2 + b_ext;

    wire               tpred    = (tsum >= 0);
    wire signed [15:0] tabs     = tsum[15] ? -tsum : tsum;
    wire               do_train = train && ((tpred != actual) || (tabs <= THETA));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w1_reg   <= 8'sd0;
            w2_reg   <= 8'sd0;
            bias_reg <= 8'sd0;
        end
        else if (do_train) begin
            if (actual) begin                           // t = +1
                w1_reg   <= sat_add(w1_reg,   tx1);
                w2_reg   <= sat_add(w2_reg,   tx2);
                bias_reg <= sat_add(bias_reg, 8'sd1);
            end
            else begin                                  // t = -1
                w1_reg   <= sat_add(w1_reg,   -tx1);
                w2_reg   <= sat_add(w2_reg,   -tx2);
                bias_reg <= sat_add(bias_reg, -8'sd1);
            end
        end
    end


    assign w1   = w1_reg;
    assign w2   = w2_reg;
    assign bias = bias_reg;

endmodule