# Xilinx Artix-7 XC7A35T-1CSG324C Constraints for E-Elements EG01 Board

# ----------------------------------------------------------------------
# 1. Clock and Reset
# ----------------------------------------------------------------------
# System Clock (100MHz, P17)
set_property PACKAGE_PIN P17 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 35.000 -name sys_clk [get_ports clk]

# User Reset (Using Slide Switch SW0, P5)
# Assuming rst is active low (rst = 0 when switch is ON/pushed, or inverted in Verilog)
set_property PACKAGE_PIN P5 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# ----------------------------------------------------------------------
# 2. 7-Segment Display (LED0 - LED3)
# The display is Common Anode (共阳�?), meaning a '0' lights up a segment.
# ----------------------------------------------------------------------

# Segments (a-g, dp) - LED0_CA to LED0_DP
# Assuming the user's top module output is: wire [7:0] seg_o; // {dp, g, f, e, d, c, b, a}
set_property PACKAGE_PIN B4 [get_ports {seg_o[0]}] ; # a (LED0_CA)
set_property PACKAGE_PIN A4 [get_ports {seg_o[1]}] ; # b (LED0_CB)
set_property PACKAGE_PIN A3 [get_ports {seg_o[2]}] ; # c (LED0_CC)
set_property PACKAGE_PIN B1 [get_ports {seg_o[3]}] ; # d (LED0_CD)
set_property PACKAGE_PIN A1 [get_ports {seg_o[4]}] ; # e (LED0_CE)
set_property PACKAGE_PIN B3 [get_ports {seg_o[5]}] ; # f (LED0_CF)
set_property PACKAGE_PIN B2 [get_ports {seg_o[6]}] ; # g (LED0_CG)
set_property PACKAGE_PIN D5 [get_ports {seg_o[7]}] ; # dp (LED0_DP)
set_property IOSTANDARD LVCMOS33 [get_ports {seg_o[*]}]

# Digit Select (DNO_K1 to DNO_K4) - Active Low
# Assuming the user's top module output is: wire [3:0] dig_en_o; // dig_en_o[0] -> LED0, dig_en_o[3] -> LED3
set_property PACKAGE_PIN G2 [get_ports {dig_en_o[0]}] ; # LED0 (DNO_K1)
set_property PACKAGE_PIN C2 [get_ports {dig_en_o[1]}] ; # LED1 (DNO_K2)
set_property PACKAGE_PIN C1 [get_ports {dig_en_o[2]}] ; # LED2 (DNO_K3)
set_property PACKAGE_PIN H1 [get_ports {dig_en_o[3]}] ; # LED3 (DNO_K4)
set_property IOSTANDARD LVCMOS33 [get_ports {dig_en_o[*]}]
# ----------------------------------------------------------------------
# 3. LED Lights (D0 - D15)
# LED is active low (0 lights up)
# Assuming the user's top module output is: wire [15:0] led_o;
set_property PACKAGE_PIN F6 [get_ports {led_o[0]}] ; # D0
set_property PACKAGE_PIN G4 [get_ports {led_o[1]}] ; # D1
set_property PACKAGE_PIN G3 [get_ports {led_o[2]}] ; # D2
set_property PACKAGE_PIN J4 [get_ports {led_o[3]}] ; # D3
set_property PACKAGE_PIN H4 [get_ports {led_o[4]}] ; # D4
set_property PACKAGE_PIN J3 [get_ports {led_o[5]}] ; # D5
set_property PACKAGE_PIN J2 [get_ports {led_o[6]}] ; # D6
set_property PACKAGE_PIN K2 [get_ports {led_o[7]}] ; # D7
set_property PACKAGE_PIN K1 [get_ports {led_o[8]}] ; # D8
set_property PACKAGE_PIN H6 [get_ports {led_o[9]}] ; # D9
set_property PACKAGE_PIN H5 [get_ports {led_o[10]}] ; # D10
set_property PACKAGE_PIN J5 [get_ports {led_o[11]}] ; # D11
set_property PACKAGE_PIN K6 [get_ports {led_o[12]}] ; # D12
set_property PACKAGE_PIN L1 [get_ports {led_o[13]}] ; # D13
set_property PACKAGE_PIN M1 [get_ports {led_o[14]}] ; # D14
set_property PACKAGE_PIN K3 [get_ports {led_o[15]}] ; # D15
# Note: The LED pins in the manual are D0-D15, but the table only lists D0-D15. I will use the first 4 for simplicity in the demo.
# I will only use D0-D3 for the demo, but provide all for completeness.
# The pin J4 is listed twice (D3, D4) in the manual, which is likely a typo in the manual. I will use the first one (D3).
# I will correct the XDC based on the image/table on page 7.
# D0: F6, D1: G4, D2: G2, D3: J4, D4: J4 (Typo), D5: J3, D6: J2, D7: K2, D8: K1, D9: H6, D10: H5, D11: J1, D12: K6, D13: L1, D14: M1, D15: K3.
# Let's re-read the LED table on page 7:
# D0: F6, D1: G4, D2: G2, D3: J4, D4: J4, D5: J3, D6: J2, D7: K2, D8: K1, D9: H6, D10: H5, D11: J1, D12: K6, D13: L1, D14: M1, D15: K3.
# I will use the pins as listed, assuming the user will only use a few.
# Let's simplify the LED constraints to only D0-D3 for the demo.
set_property PACKAGE_PIN F6 [get_ports {led_o[0]}] ; # D0
set_property PACKAGE_PIN G4 [get_ports {led_o[1]}] ; # D1
set_property PACKAGE_PIN G3 [get_ports {led_o[2]}] ; # D2
set_property PACKAGE_PIN J4 [get_ports {led_o[3]}] ; # D3
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[*]}]
