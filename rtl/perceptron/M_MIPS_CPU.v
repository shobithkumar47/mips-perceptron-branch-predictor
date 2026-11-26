`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Design Name: 16-bit MIPS
// Module Name: M_MIPS_CPU   (PERCEPTRON version)
// Project Name:
// Target Devices:
// Tool Versions:
//
// Description:
// 16-bit 5-stage pipelined MIPS processor
// WITH ML (PERCEPTRON) BRANCH PREDICTOR
//
// Same datapath as the baseline CPU, plus:
//   FETCH : the fetched instruction is pre-decoded. If it is a BEQ/BNE and
//           the perceptron predicts TAKEN, the branch target is fetched in
//           the very next cycle (0 bubbles instead of 1).
//   DECODE: the branch is resolved exactly as in the baseline. If the
//           prediction was wrong, IF/ID is flushed and the PC is corrected
//           (1 bubble). The perceptron is trained and the global history
//           is updated here (only when the branch is not stalled).
//
// Pipeline:
// IF -> ID -> EX -> MEM -> WB
//
// Data width        : 16 bits
// Instruction width : 16 bits
// Register address  : 3 bits
// Number of registers: 8
//
// Instruction format:
//
// [15:12] = opcode
// [11:9]  = rs
// [8:6]   = rt
// [5:3]   = rd
// [2:0]   = funct
//
// FIX (error 6): aluop is 3 bits, new bne signal, BNE branches when NOT equal
// FIX (error 7): pcsrcD ignored while stalled; IF/ID port renamed to flushD
// FIX (error 8): jump flushes IF/ID; jump target = {PC+2[15:13], addr, 0}
//
//////////////////////////////////////////////////////////////////////////////////

module M_MIPS_CPU(

    input clk,
    input reset,

    output [15:0] writedataM,
    output [15:0] aluoutM,
    output memwriteM,

    output [6:0] segment0,
    output [6:0] segment1,
    output [6:0] segment2,
    output [6:0] segment3,
    output [6:0] segment4,
    output [6:0] segment5

);

    //========================================================
    // CLOCK COUNTER
    //========================================================

    reg [31:0] count = 0;

    always @(posedge clk)
    begin
        count = count + 1;

        $display("**********************************************************");
        $display("Clock cycle: %d", count);
    end


    //========================================================
    // MAIN 16-BIT SIGNALS
    //========================================================

    wire [15:0] pc;
    wire [15:0] instr;
    wire [15:0] readdata;

    wire [2:0] alucontrol;

    // 16-bit instruction:
    //
    // [15:12] = opcode
    // [11:9]  = rs
    // [8:6]   = rt
    // [5:3]   = rd
    // [2:0]   = funct

    wire [3:0] op;
    wire [2:0] funct;

    wire [2:0] aluop;               // FIX (error 6): was [1:0]

    wire branch;
    wire bne;                       // FIX (error 6): new - 1 = BNE, 0 = BEQ


    //========================================================
    // REGISTER ADDRESSES
    //========================================================

    wire [2:0] writereg;
    wire [2:0] writeregE;
    wire [2:0] writeregM;
    wire [2:0] writeregW;


    //========================================================
    // PC LOGIC
    //========================================================

    wire [15:0] pcnext;
    wire [15:0] pcnextbr;

    wire [15:0] pcplus2;
    wire [15:0] pcplus2D;

    wire [15:0] pcbranchD;


    //========================================================
    // IMMEDIATE
    //========================================================

    wire [15:0] signimmD;
    wire [15:0] signimmsh;


    //========================================================
    // REGISTER FILE DATA
    //========================================================

    wire [15:0] srca;
    wire [15:0] srcb;

    wire [15:0] result;


    //========================================================
    // PIPELINE INSTRUCTION SIGNALS
    //========================================================

    wire [15:0] instrD;
    wire [15:0] instrE;
    wire [15:0] instrM;
    wire [15:0] instrW;


    //========================================================
    // CONTROL SIGNALS
    //========================================================

    wire memtoreg;
    wire memwrite;
    wire alusrc;
    wire regdst;
    wire regwrite;
    wire jump;

    wire zero;


    //========================================================
    // ID -> EX SIGNALS
    //========================================================

    wire regwriteE;
    wire memtoregE;
    wire memwriteE;

    wire [2:0] alucontrolE;

    wire alusrcE;
    wire regdstE;

    wire [15:0] srcaE;
    wire [15:0] writedataE;
    wire [15:0] srcbE;

    wire [15:0] srcaMUX;
    wire [15:0] writedataMUX;

    wire [2:0] rtE;
    wire [2:0] rdE;
    wire [2:0] rsE;

    wire [15:0] signimmE;


    //========================================================
    // EX -> MEM SIGNALS
    //========================================================

    wire regwriteM;
    wire memtoregM;

    wire [15:0] aluout;
    wire [15:0] writedata;


    //========================================================
    // MEM -> WB SIGNALS
    //========================================================

    wire regwriteW;
    wire memtoregW;

    wire [15:0] aluoutW;
    wire [15:0] readdataW;


    //========================================================
    // FORWARDING
    //========================================================

    wire [1:0] forwardAE;
    wire [1:0] forwardBE;

    wire forwardAD;
    wire forwardBD;


    //========================================================
    // HAZARD CONTROL
    //========================================================

    wire stallF;
    wire stallD;
    wire flushE;


    //========================================================
    // BRANCH
    //========================================================

    wire equalD;
    wire pcsrcD;

    wire [15:0] srcaEQ;
    wire [15:0] writedataEQ;


    //========================================================
    // PERCEPTRON BRANCH PREDICTION
    //========================================================

    // Fetch stage
    wire        isBranchF;          // fetched instruction is BEQ / BNE
    wire [15:0] targetF;            // its taken-target (computed in Fetch)
    wire        predTakenF;         // prediction for the fetched instruction
    wire [15:0] pc_pred;            // next PC according to the prediction

    // Decode stage
    wire        predTakenD;         // prediction carried with the branch
    wire [1:0]  histD;              // history the prediction was based on
    wire        branch_valid;       // branch in D and not stalled -> resolve once
    wire        mispredict;         // predicted direction != actual direction
    wire [15:0] recovery_pc;        // correct PC after a misprediction

    // Global branch history (2 most recent outcomes, 1 = taken)
    reg  [1:0]  branch_history;

    // Perceptron inputs / outputs  (x = +1 taken, -1 not taken)
    wire signed [7:0]  perceptron_x1;
    wire signed [7:0]  perceptron_x2;
    wire signed [7:0]  perceptron_tx1;
    wire signed [7:0]  perceptron_tx2;
    wire signed [7:0]  perceptron_w1;
    wire signed [7:0]  perceptron_w2;
    wire signed [7:0]  perceptron_bias;
    wire signed [15:0] perceptron_sum;
    wire               perceptron_prediction;
    wire               perceptron_train;

    // Statistics (also usable on the FPGA)
    reg  [15:0] total_branches;
    reg  [15:0] misprediction_count;


    //========================================================
    // INSTRUCTION MEMORY
    //========================================================

    M_MEM_ASYNC #(
        .RAM_SIZE(256)
    ) imem (

        .clk(clk),

        // 16-bit instruction = 2 bytes
        // 256 locations -> 8-bit address
        .address(pc[8:1]),

        .instruction(instr)

    );


    //========================================================
    // DATA MEMORY
    //========================================================

    M_MEM_SYNC #(
        .RAM_SIZE(256)
    ) dmem (

        .clk(clk),

        .mem_write(memwriteM),

        .address(aluoutM),

        .write_data(writedataM),

        .read_data(readdata)

    );


    //========================================================
    // INSTRUCTION DECODE
    //========================================================

    assign op    = instrD[15:12];

    assign funct = instrD[2:0];


    //========================================================
    // CONTROLLER
    //========================================================

    M_CONTROLLER controller(

        .opcode(op),

        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .branch(branch),
        .bne(bne),                  // FIX (error 6): new port
        .alusrc(alusrc),
        .regdst(regdst),
        .regwrite(regwrite),
        .jump(jump),
        .aluop(aluop)

    );


    //========================================================
    // ALU CONTROLLER
    //========================================================

    M_ALU_CONTROLLER aluController(

        .funct(funct),

        .aluop(aluop),

        .alucontrol(alucontrol)

    );


    //========================================================
    // IF / ID PIPELINE REGISTER
    //========================================================

    M_IF_ID_REG ifIdReg(

        .reset(reset),

        .flushD(mispredict | jump), // PERCEPTRON: flush only on a misprediction or a jump

        .stallD(stallD),

        .clk(clk),

        .instr(instr),

        .pcplus2(pcplus2),

        .instrD(instrD),

        .pcplus2D(pcplus2D),

        // PERCEPTRON: prediction + history travel with the instruction
        .predTakenF(predTakenF),

        .histF(branch_history),

        .predTakenD(predTakenD),

        .histD(histD)

    );


    //========================================================
    // ID / EX PIPELINE REGISTER
    //========================================================

    M_ID_EX_REG idExReg(

        .flushE(flushE),

        .reset(reset),

        .clk(clk),

        // Register address
        .rsD(instrD[11:9]),

        .instrD(instrD),

        // Control signals
        .regwrite(regwrite),

        .memtoreg(memtoreg),

        .memwrite(memwrite),

        .alucontrol(alucontrol),

        .alusrc(alusrc),

        .regdst(regdst),

        // Register data
        .srca(srca),

        .writedata(writedata),

        // Register addresses
        .rtD(instrD[8:6]),

        .rdD(instrD[5:3]),

        // Immediate
        .signimmD(signimmD),

        // Outputs
        .regwriteE(regwriteE),

        .memtoregE(memtoregE),

        .memwriteE(memwriteE),

        .alucontrolE(alucontrolE),

        .alusrcE(alusrcE),

        .regdstE(regdstE),

        .srcaMUX(srcaMUX),

        .writedataMUX(writedataMUX),

        .rtE(rtE),

        .rdE(rdE),

        .signimmE(signimmE),

        .instrE(instrE),

        .rsE(rsE)

    );


    //========================================================
    // EX / MEM PIPELINE REGISTER
    //========================================================

    M_EX_MEM_REG exMemReg(

        .clk(clk),

        .reset(reset),

        .instrE(instrE),

        .regwriteE(regwriteE),

        .memtoregE(memtoregE),

        .memwriteE(memwriteE),

        .aluout(aluout),

        .writedataE(writedataE),

        .writeregE(writeregE),

        .regwriteM(regwriteM),

        .memtoregM(memtoregM),

        .memwriteM(memwriteM),

        .aluoutM(aluoutM),

        .writedataM(writedataM),

        .writeregM(writeregM),

        .instrM(instrM)

    );


    //========================================================
    // MEM / WB PIPELINE REGISTER
    //========================================================

    M_MEM_WB_REG memWbReg(

        .clk(clk),

        .reset(reset),

        .instrM(instrM),

        .regwriteM(regwriteM),

        .memtoregM(memtoregM),

        .aluoutM(aluoutM),

        .readdata(readdata),

        .writeregM(writeregM),

        .regwriteW(regwriteW),

        .memtoregW(memtoregW),

        .aluoutW(aluoutW),

        .readdataW(readdataW),

        .writeregW(writeregW),

        .instrW(instrW)

    );


    //========================================================
    // PC CONTROL
    //
    // BEQ : taken when equal
    // BNE : taken when NOT equal
    // Not decided while stalled (operands not ready yet)
    //========================================================

    assign pcsrcD = branch & (bne ? ~equalD : equalD) & ~stallD;   // FIX (error 6+7): BNE + not while stalled


    //========================================================
    // PERCEPTRON - FETCH STAGE PREDICTION
    //
    // The instruction memory is read asynchronously, so the fetched
    // instruction is available in the same cycle: pre-decode it.
    //========================================================

    assign isBranchF  = (instr[15:12] == 4'b0110) ||      // BEQ
                        (instr[15:12] == 4'b0111);        // BNE

    // same target as pcbranchD: (PC+2) + (sign-extended imm << 1)
    assign targetF    = pcplus2 + {{9{instr[5]}}, instr[5:0], 1'b0};

    assign predTakenF = isBranchF & perceptron_prediction;

    assign pc_pred    = predTakenF ? targetF : pcplus2;


    //========================================================
    // PERCEPTRON - DECODE STAGE RESOLVE / RECOVER
    //========================================================

    // branch is decided once, when it is not stalled
    assign branch_valid = branch & ~stallD;

    // wrong prediction -> flush IF/ID and correct the PC
    assign mispredict   = branch_valid & (predTakenD ^ pcsrcD);

    // actually taken     -> branch target
    // actually not taken -> instruction after the branch
    assign recovery_pc  = pcsrcD ? pcbranchD : pcplus2D;


    //========================================================
    // PERCEPTRON - GLOBAL HISTORY + TRAINING
    //========================================================

    // live history -> prediction (Fetch)
    assign perceptron_x1  = branch_history[1] ? 8'sd1 : -8'sd1;
    assign perceptron_x2  = branch_history[0] ? 8'sd1 : -8'sd1;

    // history snapshot that this branch was predicted with -> training (Decode)
    assign perceptron_tx1 = histD[1] ? 8'sd1 : -8'sd1;
    assign perceptron_tx2 = histD[0] ? 8'sd1 : -8'sd1;

    // train every resolved branch (the perceptron decides: wrong or not confident)
    assign perceptron_train = branch_valid;

    perceptron u_perceptron(
        .clk(clk),
        .reset(reset),
        .x1(perceptron_x1),
        .x2(perceptron_x2),
        .tx1(perceptron_tx1),
        .tx2(perceptron_tx2),
        .actual(pcsrcD),
        .train(perceptron_train),
        .w1(perceptron_w1),
        .w2(perceptron_w2),
        .bias(perceptron_bias),
        .sum(perceptron_sum),
        .prediction(perceptron_prediction)
    );

    // shift the real outcome into the history when the branch resolves
    always @(posedge clk)
    begin
        if (reset)
            branch_history <= 2'b00;
        else if (branch_valid)
            branch_history <= {branch_history[0], pcsrcD};
    end

    // branch / misprediction counters
    always @(posedge clk)
    begin
        if (reset) begin
            total_branches      <= 16'd0;
            misprediction_count <= 16'd0;
        end
        else if (branch_valid) begin
            total_branches <= total_branches + 1'b1;
            if (mispredict)
                misprediction_count <= misprediction_count + 1'b1;
        end
    end


    //========================================================
    // PROGRAM COUNTER
    //========================================================

    M_PC_REG #(16) pcreg(

        .stallF(stallF),

        .clk(clk),

        .reset(reset),

        .d(pcnext),

        .q(pc)

    );


    //========================================================
    // PC + 2
    //
    // 16-bit instruction = 2 bytes
    //========================================================

    M_PC_ADDER pcadd1(

        .a(pc),

        .b(16'd2),

        .y(pcplus2)

    );


    //========================================================
    // BRANCH OFFSET
    //
    // 6-bit immediate is sign extended to 16 bits
    // Then shifted left by 1 because instructions are 2 bytes
    //========================================================

    M_SLL2 immsh(

        .a(signimmD),

        .y(signimmsh)

    );


    //========================================================
    // BRANCH TARGET
    //========================================================

    M_PC_ADDER pcadd2(

        .a(pcplus2D),

        .b(signimmsh),

        .y(pcbranchD)

    );


    //========================================================
    // BRANCH MUX (PERCEPTRON)
    //   normal      : follow the prediction (PC+2 or predicted target)
    //   mispredict  : go to the correct PC
    //========================================================

    M_MUX_2_DONTCARE pcbrmux(

        .d0(pc_pred),

        .d1(recovery_pc),

        .s(mispredict),

        .y(pcnextbr)

    );


    //========================================================
    // JUMP
    //
    // 16-bit instruction
    // Jump field [11:0] = word address -> byte address = addr << 1
    // Target = {PC+2[15:13], addr[11:0], 0}
    //========================================================

    M_MUX_2_DONTCARE pcmux(

        .d0(pcnextbr),

        .d1({
            pcplus2D[15:13],        // FIX (error 8): jump target = word address << 1
            instrD[11:0],
            1'b0
        }),

        .s(jump),

        .y(pcnext)

    );


    //========================================================
    // REGISTER FILE
    //========================================================

    M_REG_FILE rf(

        .clk(clk),

        .reg_write(regwriteW),

        // Read register 1
        .read_reg1(instrD[11:9]),

        // Read register 2
        .read_reg2(instrD[8:6]),

        // Write register
        .write_reg(writeregW),

        // Write data
        .write_data(result),

        // Outputs
        .read_data1(srca),

        .read_data2(writedata),

        .segment0(segment0),
        .segment1(segment1),
        .segment2(segment2),
        .segment3(segment3),
        .segment4(segment4),
        .segment5(segment5)

    );


    //========================================================
    // WRITE REGISTER MUX
    //========================================================

    M_MUX_2 #(3) wrmux(

        .d0(rtE),

        .d1(rdE),

        .s(regdstE),

        .y(writeregE)

    );


    //========================================================
    // WRITEBACK RESULT MUX
    //========================================================

    M_MUX_2 #(16) resmux(

        .d0(aluoutW),

        .d1(readdataW),

        .s(memtoregW),

        .y(result)

    );


    //========================================================
    // SIGN EXTENSION
    //
    // 6-bit immediate -> 16-bit
    //========================================================

    M_SEXT_6 se(

        .a(instrD[5:0]),

        .y(signimmD)

    );


    //========================================================
    // ALU INPUT FORWARDING
    //========================================================

    M_MUX_3_DONTCARE muxsrca(

        .d0(srcaMUX),

        .d1(result),

        .d2(aluoutM),

        .s(forwardAE),

        .y(srcaE)

    );


    M_MUX_3_DONTCARE muxwritedata(

        .d0(writedataMUX),

        .d1(result),

        .d2(aluoutM),

        .s(forwardBE),

        .y(writedataE)

    );


    //========================================================
    // ALU SECOND INPUT
    //========================================================

    M_MUX_2 #(16) srcbmux(

        .d0(writedataE),

        .d1(signimmE),

        .s(alusrcE),

        .y(srcbE)

    );


    //========================================================
    // 16-BIT ALU
    //========================================================

    M_ALU alu(

        .a(srcaE),

        .b(srcbE),

        .alucontrol(alucontrolE),

        .result(aluout)

    );


    //========================================================
    // HAZARD UNIT
    //========================================================

    M_HAZARD_UNIT hazardunit(

        .branch(branch),

        .memtoregE(memtoregE),

        .memtoregM(memtoregM),

        // ID register addresses
        .rsD(instrD[11:9]),

        .rtD(instrD[8:6]),

        // Register writes
        .regwriteE(regwriteE),

        .regwriteM(regwriteM),

        .regwriteW(regwriteW),

        // EX register addresses
        .rsE(rsE),

        .rtE(rtE),

        // Destination registers
        .writeregE(writeregE),

        .writeregM(writeregM),

        .writeregW(writeregW),

        // Forwarding
        .forwardAE(forwardAE),

        .forwardBE(forwardBE),

        // Stall
        .stallF(stallF),

        .stallD(stallD),

        .flushE(flushE),

        // Early branch forwarding
        .forwardAD(forwardAD),

        .forwardBD(forwardBD)

    );


    //========================================================
    // EARLY BRANCH COMPARISON
    //========================================================

    M_EQUAL equal(

        .srca(srcaEQ),

        .writedata(writedataEQ),

        .equalD(equalD)

    );


    //========================================================
    // BRANCH FORWARDING
    //========================================================

    M_MUX_2_DONTCARE srcsEQMUX(

        .d0(srca),

        .d1(aluoutM),

        .s(forwardAD),

        .y(srcaEQ)

    );


    M_MUX_2_DONTCARE writedataEQMUX(

        .d0(writedata),

        .d1(aluoutM),

        .s(forwardBD),

        .y(writedataEQ)

    );


    //========================================================
    // DEBUG
    //========================================================

    always @(posedge clk)
    begin

        $display("==============================================");
        $display("16-BIT MIPS CPU");

        $display("PC        = %h", pc);
        $display("PC+2      = %h", pcplus2);

        $display("INSTR     = %h", instr);
        $display("INSTRD    = %h", instrD);

        $display("srca      = %h", srca);
        $display("writedata = %h", writedata);

        $display("IMM       = %h", signimmD);

        $display("ALUOUT    = %h", aluout);
        $display("ALUOUTM   = %h", aluoutM);

        $display("MEMWRITE  = %b", memwriteM);

        $display("RESULT    = %h", result);

        $display("==============================================");

    end


    //========================================================
    // BRANCH DEBUG
    //========================================================

    always @(posedge clk)
    begin

        if(branch)
        begin

            $display("========== BRANCH ==========");

            $display("Instruction = %h", instrD);
            $display("branch      = %b", branch);
            $display("bne         = %b", bne);      // FIX (error 6): show BEQ/BNE
            $display("equalD      = %b", equalD);
            $display("pcsrcD      = %b", pcsrcD);
            $display("predicted   = %b", predTakenD);    // PERCEPTRON
            $display("mispredict  = %b", mispredict);    // PERCEPTRON
            $display("w1=%0d w2=%0d bias=%0d", perceptron_w1, perceptron_w2, perceptron_bias);

            if(pcsrcD)
                $display("Branch TAKEN");
            else
                $display("Branch NOT TAKEN");

        end

    end


    //========================================================
    // HAZARD DEBUG
    //========================================================

    always @(posedge clk)
    begin

        $display("stallF : %b", stallF);
        $display("stallD : %b", stallD);
        $display("flushE : %b", flushE);

    end


    //========================================================
    // FORWARDING DEBUG
    //========================================================

    always @(forwardAE)
    begin

        case(forwardAE)

            2'b01:
                $display(
                    "Forwarded %h to srcaE from MEM/WB",
                    result
                );

            2'b10:
                $display(
                    "Forwarded %h to srcaE from EX/MEM",
                    aluoutM
                );

        endcase

    end


    always @(forwardBE)
    begin

        case(forwardBE)

            2'b01:
                $display(
                    "Forwarded %h to writedataE from MEM/WB",
                    result
                );

            2'b10:
                $display(
                    "Forwarded %h to writedataE from EX/MEM",
                    aluoutM
                );

        endcase

    end

endmodule