`timescale 1ns/1ps

module vga_timing(
    input  wire       clk,
    input  wire       rst,
    output reg  [9:0] x,
    output reg  [9:0] y,
    output wire       active,
    output wire       hsync,
    output wire       vsync,
    output reg        pixel_ce
);
    reg [1:0] pix_div;

    assign active = (x < 10'd640) && (y < 10'd480);
    assign hsync  = ~((x >= 10'd656) && (x < 10'd752));
    assign vsync  = ~((y >= 10'd490) && (y < 10'd492));

    always @(posedge clk) begin
        if (rst) begin
            pix_div  <= 0;
            pixel_ce <= 1'b0;
            x        <= 0;
            y        <= 0;
        end else begin
            pix_div  <= pix_div + 1'b1;
            pixel_ce <= 1'b0;
            if (pix_div == 2'b11) begin
                pixel_ce <= 1'b1;
                if (x == 10'd799) begin
                    x <= 0;
                    if (y == 10'd524)
                        y <= 0;
                    else
                        y <= y + 1'b1;
                end else begin
                    x <= x + 1'b1;
                end
            end
        end
    end
endmodule
