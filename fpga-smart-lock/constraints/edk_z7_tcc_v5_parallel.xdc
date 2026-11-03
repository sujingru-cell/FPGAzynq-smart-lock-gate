# EDK_Z7_TCC / XC7Z020CLG484-1

# PL clock: 100 MHz
set_property PACKAGE_PIN AA18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name clk100m -period 10.000 -waveform {0.000 5.000} [get_ports clk]

# Buttons
set_property PACKAGE_PIN H17 [get_ports pb0]
set_property IOSTANDARD LVCMOS18 [get_ports pb0]
set_property PACKAGE_PIN C19 [get_ports pb1]
set_property IOSTANDARD LVCMOS18 [get_ports pb1]

# Switches
set_property PACKAGE_PIN E19 [get_ports {sw[0]}]
set_property PACKAGE_PIN H18 [get_ports {sw[1]}]
set_property PACKAGE_PIN F19 [get_ports {sw[2]}]
set_property PACKAGE_PIN G22 [get_ports {sw[3]}]
# SW4 uses the pin verified on the target board used for this project.
set_property PACKAGE_PIN G19 [get_ports {sw[4]}]
set_property PACKAGE_PIN H22 [get_ports {sw[5]}]
set_property PACKAGE_PIN H20 [get_ports {sw[6]}]
set_property PACKAGE_PIN F22 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {sw[*]}]

# LEDs
set_property PACKAGE_PIN B20 [get_ports {led[0]}]
set_property PACKAGE_PIN D20 [get_ports {led[1]}]
set_property PACKAGE_PIN C20 [get_ports {led[2]}]
set_property PACKAGE_PIN A21 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[*]}]

# VGA: 4 bits per RGB channel
set_property PACKAGE_PIN U15  [get_ports {vga_r[0]}]
set_property PACKAGE_PIN U16  [get_ports {vga_r[1]}]
set_property PACKAGE_PIN U17  [get_ports {vga_r[2]}]
set_property PACKAGE_PIN V15  [get_ports {vga_r[3]}]
set_property PACKAGE_PIN AA17 [get_ports {vga_g[0]}]
set_property PACKAGE_PIN AB17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN AA16 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN AB16 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN W15  [get_ports {vga_b[0]}]
set_property PACKAGE_PIN Y15  [get_ports {vga_b[1]}]
set_property PACKAGE_PIN AA14 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN AB15 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN W16 [get_ports vga_hsync]
set_property PACKAGE_PIN Y16 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*] vga_g[*] vga_b[*] vga_hsync vga_vsync}]
