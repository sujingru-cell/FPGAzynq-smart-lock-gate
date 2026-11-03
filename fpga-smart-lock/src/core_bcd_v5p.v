`timescale 1ns/1ps
module core_bcd_v5p(
    input  wire clk,
    input  wire rst,
    input  wire refresh,
    input  wire [15:0] passed_total,
    input  wire [15:0] avg_wait_s,
    input  wire [15:0] fresh_per_ship,
    input  wire [7:0]  avg_load_pct,
    input  wire [6:0]  congestion_pct,
    input  wire [6:0]  save_pct,
    input  wire [6:0]  pool_level,
    output wire [15:0] pass_bcd,
    output wire [15:0] avg_bcd,
    output wire [15:0] fresh_bcd,
    output wire [15:0] load_bcd,
    output wire [15:0] cong_bcd,
    output wire [15:0] save_bcd,
    output wire [15:0] pool_bcd
);
    wire [15:0] pass_fmt  = (passed_total   > 16'd9999) ? 16'd9999 : passed_total;
    wire [15:0] avg_fmt   = (avg_wait_s     > 16'd9999) ? 16'd9999 : avg_wait_s;
    wire [15:0] fresh_fmt = (fresh_per_ship > 16'd9999) ? 16'd9999 : fresh_per_ship;
    bin16_to_bcd4_seq c0(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary(pass_fmt),
        .bcd(pass_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c1(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary(avg_fmt),
        .bcd(avg_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c2(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary(fresh_fmt),
        .bcd(fresh_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c3(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary({8'd0,avg_load_pct}),
        .bcd(load_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c4(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary({9'd0,congestion_pct}),
        .bcd(cong_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c5(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary({9'd0,save_pct}),
        .bcd(save_bcd),
        .busy(),
        .done());
    bin16_to_bcd4_seq c6(.clk(clk),
        .rst(rst),
        .start(refresh),
        .binary({9'd0,pool_level}),
        .bcd(pool_bcd),
        .busy(),
        .done());
endmodule
