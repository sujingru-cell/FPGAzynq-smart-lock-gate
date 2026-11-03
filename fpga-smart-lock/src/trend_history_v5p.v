`timescale 1ns/1ps
// 32 one-second samples for the AUTO trend page.
module trend_history_v5p(
    input  wire clk,
    input  wire rst,
    input  wire sample_tick,
    input  wire [5:0] queue_pressure,
    input  wire [15:0] fresh_per_ship,
    input  wire policy_eff,
    input  wire [4:0] read_index,
    input  wire [4:0] read_prev_index,
    output reg  [4:0] write_ptr,
    output reg  [6:0] read_queue,
    output reg  [6:0] read_fresh,
    output reg        read_policy,
    output reg  [6:0] read_prev_queue,
    output reg  [6:0] read_prev_fresh,
    output reg        read_prev_policy
);
    (* ram_style = "distributed" *) reg [6:0] qhist [0:31];
    (* ram_style = "distributed" *) reg [6:0] fhist [0:31];
    (* ram_style = "distributed" *) reg       phist [0:31];
    integer i;
    wire [8:0] qx4 = {3'b000,queue_pressure} << 2;
    wire [6:0] qscaled = (qx4 > 9'd100) ? 7'd100 : qx4[6:0];
    wire [6:0] fscaled = (fresh_per_ship > 16'd100) ? 7'd100 : fresh_per_ship[6:0];

    always @(posedge clk) begin
        if (rst) begin
            write_ptr <= 0;
            read_queue <= 0; read_fresh <= 0; read_policy <= 0;
            read_prev_queue <= 0; read_prev_fresh <= 0; read_prev_policy <= 0;
            for (i=0;i<32;i=i+1) begin
                qhist[i] <= 0;
                fhist[i] <= 0;
                phist[i] <= 0;
            end
        end else begin
            read_queue <= qhist[read_index];
            read_fresh <= fhist[read_index];
            read_policy <= phist[read_index];
            read_prev_queue <= qhist[read_prev_index];
            read_prev_fresh <= fhist[read_prev_index];
            read_prev_policy <= phist[read_prev_index];
            if (sample_tick) begin
                qhist[write_ptr] <= qscaled;
                fhist[write_ptr] <= fscaled;
                phist[write_ptr] <= policy_eff;
                write_ptr <= write_ptr + 1'b1;
            end
        end
    end
endmodule
