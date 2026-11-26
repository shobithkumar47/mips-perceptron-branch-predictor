##==================================================================
## ADITHSDC.xdc  -  constraints for FPGA_MIPS_TOP (16-bit MIPS)
##
## FIX:
##  - every top-level port now has a PACKAGE_PIN and IOSTANDARD
##    (missing ones caused DRC NSTD-1 / UCIO-1 and blocked the bitstream)
##  - pin names in UPPERCASE
##  - clock constraint added
##  - port names match the corrected FPGA_MIPS_TOP
##
## Replace every <PIN> with the pin from your board's manual / master XDC.
## Change LVCMOS33 if your board's bank voltage is different.
##==================================================================

## ---------------- Clock (board oscillator) ----------------
set_property PACKAGE_PIN <PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
## period in ns: 10.000 = 100 MHz, 20.000 = 50 MHz  (match your oscillator)
create_clock -name sys_clk -period 20.000 [get_ports clk]

## Divided CPU clock (FPGA_MIPS_TOP, CLK_DIV_BITS = 24 -> divide by 2^24)
create_generated_clock -name cpu_clk -source [get_ports clk] -divide_by 16777216 \
    [get_pins {div_count_reg[23]/Q}]

## ---------------- Reset push button ----------------
set_property PACKAGE_PIN <PIN> [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

## ---------------- 7-segment digit 0 (R1[3:0]) ----------------
set_property PACKAGE_PIN <PIN> [get_ports {segment0[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[1]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[2]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[3]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[4]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[5]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment0[6]}]

## ---------------- 7-segment digit 1 (R1[7:4]) ----------------
set_property PACKAGE_PIN <PIN> [get_ports {segment1[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[1]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[2]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[3]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[4]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[5]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment1[6]}]

## ---------------- 7-segment digit 2 (R1[11:8]) ----------------
set_property PACKAGE_PIN <PIN> [get_ports {segment2[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[1]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[2]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[3]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[4]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[5]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment2[6]}]

## ---------------- 7-segment digit 3 (R1[15:12]) ----------------
set_property PACKAGE_PIN <PIN> [get_ports {segment3[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[1]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[2]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[3]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[4]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[5]}]
set_property PACKAGE_PIN <PIN> [get_ports {segment3[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {segment0[*] segment1[*] segment2[*] segment3[*]}]

## ---------------- LEDs (aluoutM[7:0]) ----------------
set_property PACKAGE_PIN <PIN> [get_ports {led[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[1]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[2]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[3]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[4]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[5]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[6]}]
set_property PACKAGE_PIN <PIN> [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]

## ---------------- Configuration (7-series, 3.3 V bank 0) ----------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]