`timescale 1ns/1ps

module tick_gen #(
    parameter integer CLK_HZ  = 100_000_000,
    parameter integer TICK_HZ = 10
)(
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    localparam integer DIVISOR = CLK_HZ / TICK_HZ;
    localparam integer CW = 32;
    reg [CW-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            tick  <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (count >= DIVISOR-1) begin
                count <= 0;
                tick  <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule
