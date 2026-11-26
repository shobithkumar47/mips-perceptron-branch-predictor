# 16-bit 5-Stage Pipelined MIPS Processor with Perceptron Branch Predictor

A 16-bit, 5-stage pipelined MIPS-style processor written in Verilog HDL, built in two versions:

- **Baseline** – static *predict-not-taken* branch handling
- **Perceptron** – the same datapath with a hardware **perceptron (machine-learning) branch predictor**

Both versions include full hazard handling (data forwarding, load-use stalls, branch stalls), pass the same self-checking testbench, and were synthesized and implemented in Xilinx Vivado for an Artix-7 FPGA.

## Results

Same test program, same testbench, 100 MHz simulation clock:

| Metric                  | Baseline (not-taken) | Perceptron | Change |
|-------------------------|---------------------:|-----------:|-------:|
| Total clock cycles      | 84                   | 81         | −3.6 % |
| Instructions retired    | 63                   | 63         |        |
| CPI                     | 1.333                | 1.286      | lower  |
| Branch prediction accuracy | 25.0 % (2 / 8)    | 62.5 % (5 / 8) | +37.5 pts |
| Branch / jump flushes   | 9                    | 6          | −3     |
| Stall cycles            | 9                    | 9          |        |
| Forwarding events       | 16                   | 16         |        |
| Self-check              | TEST PASSED          | TEST PASSED |       |

Full reports: [`results/baseline_sim_report.txt`](results/baseline_sim_report.txt), [`results/perceptron_sim_report.txt`](results/perceptron_sim_report.txt).

### FPGA implementation (perceptron version)

Target: **Artix-7 `xc7a35tftg256-1`** (EDGE Artix 7 board), Xilinx Vivado

| Resource        | Used | Available | Utilization |
|-----------------|-----:|----------:|------------:|
| Slice LUTs      | 384  | 20,800    | 1.85 %      |
| Slice registers | 205  | 41,600    | 0.49 %      |
| DSP slices      | 1    | 90        | 1.11 %      |

Timing met on the routed design with a 50 MHz board-clock constraint (worst negative slack **+17.5 ns**, no failing endpoints). Estimated on-chip power: **0.075 W**.
Reports: [`results/`](results/).

## Architecture

```
IF  ->  ID  ->  EX  ->  MEM  ->  WB
```

| Feature            | Detail |
|--------------------|--------|
| Data width         | 16 bits |
| Instruction width  | 16 bits |
| Registers          | 8 (3-bit register address), R0 = 0 |
| Instruction format | `[15:12] opcode · [11:9] rs · [8:6] rt · [5:3] rd · [2:0] funct` |
| Branches           | Resolved in the ID stage |

### Instruction set

| Type      | Instructions |
|-----------|--------------|
| R-type    | `ADD` `SUB` `AND` `OR` `XOR` `SLT` `MUL` |
| Immediate | `ADDI` `ANDI` `ORI` `XORI` `SLTI` |
| Memory    | `LW` `SW` |
| Control   | `BEQ` `BNE` `J` |

### Hazard handling (`M_HAZARD_UNIT`)

- **Forwarding to EX** from EX/MEM and MEM/WB
- **Forwarding to ID** for branch comparison
- **Load-use stall** when an instruction needs a value a `LW` is still loading
- **Branch stall** when a branch needs a result that is not ready yet
- R0 is never forwarded or stalled on (a flushed slot looks like `add r0,r0,r0`)

### Perceptron branch predictor (`rtl/perceptron/perceptron.v`)

Based on the perceptron predictor of Jiménez & Lin (HPCA 2001):

- Inputs: the last **2 global branch outcomes** (+1 taken, −1 not taken)
- Weights: `bias`, `w1`, `w2` – 8-bit signed, saturating at −128..127
- Prediction: `y = bias + w1·x1 + w2·x2`, predict **taken if y ≥ 0**
- Training: when a branch resolves, update the weights if the prediction was wrong **or** not confident (`|y| ≤ θ`, θ = 17)
- No multipliers needed, since inputs are ±1

How it fits the pipeline:

- **IF:** the fetched instruction is pre-decoded. If it is `BEQ`/`BNE` and the perceptron predicts *taken*, the branch target is fetched in the next cycle (**0 bubbles** instead of 1).
- **ID:** the branch is resolved as in the baseline. On a misprediction, IF/ID is flushed and the PC is corrected (1 bubble). The perceptron is trained and the history updated here.

### FPGA top level (`fpga/`)

- Clock divider (board clock / 2²⁴ ≈ 3 Hz) so the CPU can be watched running
- Reset push button with a 2-flop synchronizer
- 4-digit multiplexed 7-segment display showing register **R1** in hex
- 16 LEDs showing the ALU output

## Repository structure

```
├── rtl/
│   ├── common/       # Shared modules: ALU, controllers, register file, hazard unit,
│   │                 #   pipeline registers, memories, muxes, multiplier, 7-seg decoder
│   ├── baseline/     # CPU top + IF/ID register (predict-not-taken)
│   └── perceptron/   # CPU top + IF/ID register + perceptron predictor
├── tb/
│   ├── baseline/     # Self-checking testbench + performance report
│   └── perceptron/   # Same, plus prediction accuracy and final weights
├── fpga/
│   ├── baseline/     # FPGA top module + constraints (EDGE Artix 7)
│   └── perceptron/
├── mem/              # meminstr.mem (test program), memdata.mem (data memory)
├── results/          # Simulation reports + Vivado utilization, timing, power
└── run_sim.sh        # One-command simulation with Icarus Verilog
```

## How to run

### Icarus Verilog (quick)

```sh
git clone https://github.com/shobithkumar47/mips-perceptron-branch-predictor.git
cd mips-perceptron-branch-predictor
./run_sim.sh baseline
./run_sim.sh perceptron
```

### Xilinx Vivado

1. Create a new RTL project.
2. Add `rtl/common/*.v` and **one** of `rtl/baseline/` or `rtl/perceptron/` as design sources.
3. Add the matching `tb/<version>/TB_MIPS_CPU.v` as a simulation source, and `mem/*.mem` as simulation files.
4. Run Behavioral Simulation. The testbench prints a performance report and `TEST PASSED` / `TEST FAILED`.
5. For the board: add `fpga/<version>/FPGA_TOP_MODULE.v` and its `.xdc`, set `FPGA_MIPS_TOP` as top, and fill in the `PACKAGE_PIN` values for your board.

## Tools

Verilog HDL · Xilinx Vivado · Icarus Verilog · Artix-7 FPGA

## Author

**K Shobith Kumar**
B.E. Electronics and Communication Engineering, Dayananda Sagar Academy of Technology and Management, Bengaluru
[LinkedIn](www.linkedin.com/in/k-shobith-kumar) · shobithgowda33@gmail.com
