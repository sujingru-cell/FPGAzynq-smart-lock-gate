`timescale 1ns/1ps

module lfsr16(
    input  wire       clk,
    input  wire       rst,
    output reg [15:0] rnd
);
    wire feedback = rnd[15] ^ rnd[13] ^ rnd[12] ^ rnd[10];

    always @(posedge clk) begin
        if (rst)
            rnd <= 16'h1ACE;
        else
            rnd <= {rnd[14:0], feedback};
    end
endmodule
