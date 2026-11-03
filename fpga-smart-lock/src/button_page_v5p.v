`timescale 1ns/1ps
// PB1 is page-only: release cycles MAIN -> COMPARE -> TREND -> MAIN.
module button_page_v5p #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire pb_n,
    output reg [1:0] page
);
    reg sync1, sync2;
    reg stable_pressed, candidate_pressed;
    reg [19:0] debounce_count;
    wire raw_pressed = ~sync2;

    always @(posedge clk) begin
        if (rst) begin
            sync1 <= 1'b1;
            sync2 <= 1'b1;
            stable_pressed <= 1'b0;
            candidate_pressed <= 1'b0;
            debounce_count <= 0;
            page <= 0;
        end else begin
            sync1 <= pb_n;
            sync2 <= sync1;
            if (raw_pressed != candidate_pressed) begin
                candidate_pressed <= raw_pressed;
                debounce_count <= 0;
            end else if (candidate_pressed != stable_pressed) begin
                if (debounce_count >= DEBOUNCE_CYCLES-1) begin
                    stable_pressed <= candidate_pressed;
                    debounce_count <= 0;
                    if (!candidate_pressed) begin
                        if (page == 2'd2) page <= 0;
                        else page <= page + 1'b1;
                    end
                end else debounce_count <= debounce_count + 1'b1;
            end else debounce_count <= 0;
        end
    end
endmodule
