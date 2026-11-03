`timescale 1ns/1ps

module tb_smoke;
    reg clk = 1'b0;
    reg pb0 = 1'b1;
    reg pb1 = 1'b1;
    reg [7:0] sw = 8'd0;

    wire [3:0] led;
    wire [3:0] vga_r;
    wire [3:0] vga_g;
    wire [3:0] vga_b;
    wire vga_hsync;
    wire vga_vsync;

    top dut(
        .clk(clk),
        .pb0(pb0),
        .pb1(pb1),
        .sw(sw),
        .led(led),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync)
    );

    always #5 clk = ~clk;

    initial begin
        #1000;
        sw = 8'b01_10_00_11;

        // Manual reset.
        #1000;
        pb0 = 1'b0;
        #2000;
        pb0 = 1'b1;

        // Hold PB1 longer than the 10 ms debounce interval.
        #1000000;
        pb1 = 1'b0;
        #12000000;
        pb1 = 1'b1;

        #20000000;
        $finish;
    end
endmodule
