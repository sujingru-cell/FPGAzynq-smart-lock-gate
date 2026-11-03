`timescale 1ns/1ps
// Arrival FIFO used by each policy core.
module arrival_fifo_v5p #(
    parameter integer DEPTH = 32,
    parameter integer AW = 5
)(
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire push_large,
    input  wire pop,
    output wire valid,
    output wire head_large,
    output reg  [6:0] count,
    output reg  [15:0] overflow_count
);
    reg mem [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    wire full = (count >= DEPTH);
    wire do_pop = pop && (count != 0);
    wire do_push = push && (!full || do_pop);

    assign valid = (count != 0);
    assign head_large = mem[rd_ptr];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            overflow_count <= 0;
        end else begin
            if (push && full && !do_pop && overflow_count != 16'hFFFF)
                overflow_count <= overflow_count + 1'b1;

            if (do_push) begin
                mem[wr_ptr] <= push_large;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_pop)
                rd_ptr <= rd_ptr + 1'b1;

            case ({do_push,do_pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
