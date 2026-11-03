`timescale 1ns/1ps

// Two-stage hydraulic model with one reusable saving basin.
// Levels use normalized units from 0 to 100.
module water_model_v5(
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_anim,
    input  wire        cmd_start,
    input  wire [3:0]  cmd,

    output reg         busy,
    output reg         done,
    output reg  [3:0]  active_cmd,
    output reg  [6:0]  ch1_water,
    output reg  [6:0]  ch2_water,
    output reg  [6:0]  pool_level,
    output reg  [31:0] fresh_total,
    output reg  [31:0] reused_total,
    output reg  [31:0] discarded_total,
    output reg  [2:0]  up_res_offset,
    output reg  [2:0]  dn_res_offset,
    output reg  [3:0]  flow_code
);
    localparam [6:0] HIGH = 7'd100;
    localparam [6:0] MID  = 7'd50;
    localparam [6:0] LOW  = 7'd0;

    localparam [3:0] CMD_NONE          = 4'd0;
    localparam [3:0] CMD_CH1_DOWN_SAVE = 4'd1;
    localparam [3:0] CMD_CH1_DOWN_FAST = 4'd2;
    localparam [3:0] CMD_CH2_UP_SAVE   = 4'd3;
    localparam [3:0] CMD_CH2_UP_FAST   = 4'd4;
    localparam [3:0] CMD_CH2_DOWN_SAVE = 4'd5;
    localparam [3:0] CMD_CH2_DOWN_FAST = 4'd6;
    localparam [3:0] CMD_CH1_UP_FRESH  = 4'd7;

    reg [2:0] step_div;
    reg [7:0] vis_decay;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
            active_cmd <= CMD_NONE;
            ch1_water <= HIGH;
            ch2_water <= LOW;
            pool_level <= 7'd50;
            fresh_total <= 0;
            reused_total <= 0;
            discarded_total <= 0;
            up_res_offset <= 0;
            dn_res_offset <= 0;
            flow_code <= 0;
            step_div <= 0;
            vis_decay <= 0;
        end else begin
            done <= 1'b0;

            if (cmd_start && !busy) begin
                busy <= 1'b1;
                active_cmd <= cmd;
                flow_code <= cmd;
                step_div <= 0;
            end

            if (tick_anim) begin
                // Small reservoir offsets are visual only and decay slowly.
                vis_decay <= vis_decay + 1'b1;
                if (vis_decay == 8'd199) begin
                    vis_decay <= 0;
                    if (up_res_offset != 0) up_res_offset <= up_res_offset - 1'b1;
                    if (dn_res_offset != 0) dn_res_offset <= dn_res_offset - 1'b1;
                end

                if (busy) begin
                    if (step_div == 3'd4) begin
                        step_div <= 0;
                        case (active_cmd)
                            CMD_CH1_DOWN_SAVE: begin
                                if (ch1_water > MID) begin
                                    ch1_water <= ch1_water - 1'b1;
                                    if (pool_level < 7'd100)
                                        pool_level <= pool_level + 1'b1;
                                    else begin
                                        discarded_total <= discarded_total + 1'b1;
                                        if (dn_res_offset < 3) dn_res_offset <= dn_res_offset + 1'b1;
                                    end
                                    if (ch1_water == MID + 1'b1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH1_DOWN_FAST: begin
                                if (ch1_water > MID) begin
                                    ch1_water <= ch1_water - 1'b1;
                                    discarded_total <= discarded_total + 1'b1;
                                    if (dn_res_offset < 3) dn_res_offset <= dn_res_offset + 1'b1;
                                    if (ch1_water == MID + 1'b1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH2_UP_SAVE: begin
                                if (ch2_water < MID) begin
                                    ch2_water <= ch2_water + 1'b1;
                                    if (pool_level != 0) begin
                                        pool_level <= pool_level - 1'b1;
                                        reused_total <= reused_total + 1'b1;
                                    end else begin
                                        fresh_total <= fresh_total + 1'b1;
                                        if (up_res_offset < 3) up_res_offset <= up_res_offset + 1'b1;
                                    end
                                    if (ch2_water == MID - 1'b1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH2_UP_FAST: begin
                                if (ch2_water < MID) begin
                                    ch2_water <= ch2_water + 1'b1;
                                    fresh_total <= fresh_total + 1'b1;
                                    if (up_res_offset < 3) up_res_offset <= up_res_offset + 1'b1;
                                    if (ch2_water == MID - 1'b1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH2_DOWN_SAVE: begin
                                if (ch2_water > LOW) begin
                                    ch2_water <= ch2_water - 1'b1;
                                    if (pool_level < 7'd100)
                                        pool_level <= pool_level + 1'b1;
                                    else begin
                                        discarded_total <= discarded_total + 1'b1;
                                        if (dn_res_offset < 3) dn_res_offset <= dn_res_offset + 1'b1;
                                    end
                                    if (ch2_water == 7'd1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH2_DOWN_FAST: begin
                                if (ch2_water > LOW) begin
                                    ch2_water <= ch2_water - 1'b1;
                                    discarded_total <= discarded_total + 1'b1;
                                    if (dn_res_offset < 3) dn_res_offset <= dn_res_offset + 1'b1;
                                    if (ch2_water == 7'd1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            CMD_CH1_UP_FRESH: begin
                                if (ch1_water < HIGH) begin
                                    ch1_water <= ch1_water + 1'b1;
                                    fresh_total <= fresh_total + 1'b1;
                                    if (up_res_offset < 3) up_res_offset <= up_res_offset + 1'b1;
                                    if (ch1_water == HIGH - 1'b1) begin
                                        busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                    end
                                end else begin
                                    busy <= 1'b0; done <= 1'b1; flow_code <= 0;
                                end
                            end

                            default: begin
                                busy <= 1'b0;
                                done <= 1'b1;
                                flow_code <= 0;
                            end
                        endcase
                    end else begin
                        step_div <= step_div + 1'b1;
                    end
                end
            end
        end
    end
endmodule
