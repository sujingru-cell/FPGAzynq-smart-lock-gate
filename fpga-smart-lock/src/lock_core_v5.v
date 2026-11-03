`timescale 1ns/1ps

// Two-stage lock controller. One batch is processed at a time.
module lock_core_v5(
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_sim,

    input  wire        choose_pulse,
    input  wire        choose_dir_up,
    input  wire        policy_eff,

    input  wire [2:0]  up_sel_ships,
    input  wire [7:0]  up_sel_types,
    input  wire [2:0]  dn_sel_ships,
    input  wire [7:0]  dn_sel_types,
    input  wire [5:0]  up_q_count,
    input  wire [5:0]  dn_q_count,

    input  wire        water_busy,
    input  wire        water_done,
    input  wire        anim_busy,
    input  wire        anim_done,

    output reg         pop_up_lane,
    output reg         pop_dn_lane,
    output reg         water_start,
    output reg  [3:0]  water_cmd,
    output reg         anim_start,
    output reg  [3:0]  anim_event,

    output reg         busy,
    output reg         batch_dir_up,
    output reg  [2:0]  batch_ships,
    output reg  [7:0]  batch_types,
    output reg  [1:0]  batch_loc,
    output reg         cycle_save,
    output reg  [7:0]  last_event,
    output reg  [4:0]  state_code,
    output reg  [15:0] passed_total,
    output reg  [31:0] wait_accum_seconds
);
    // Water commands shared with water_model_v5.
    localparam [3:0] CMD_NONE          = 4'd0;
    localparam [3:0] CMD_CH1_DOWN_SAVE = 4'd1;
    localparam [3:0] CMD_CH1_DOWN_FAST = 4'd2;
    localparam [3:0] CMD_CH2_UP_SAVE   = 4'd3;
    localparam [3:0] CMD_CH2_UP_FAST   = 4'd4;
    localparam [3:0] CMD_CH2_DOWN_SAVE = 4'd5;
    localparam [3:0] CMD_CH2_DOWN_FAST = 4'd6;
    localparam [3:0] CMD_CH1_UP_FRESH  = 4'd7;

    // Animation events shared with animation_v5.
    localparam [3:0] AN_NONE        = 4'd0;
    localparam [3:0] AN_LOAD_CH1_DN = 4'd1;
    localparam [3:0] AN_CH1_CH2_DN  = 4'd2;
    localparam [3:0] AN_EXIT_DN     = 4'd3;
    localparam [3:0] AN_LOAD_CH2_UP = 4'd4;
    localparam [3:0] AN_CH2_CH1_UP  = 4'd5;
    localparam [3:0] AN_EXIT_UP     = 4'd6;

    // Events shown on the MAIN page.
    localparam [7:0] EV_IDLE          = 8'd0;
    localparam [7:0] EV_LOAD_CH1      = 8'd1;
    localparam [7:0] EV_CH1_POOL      = 8'd2;
    localparam [7:0] EV_DRAIN_CH1     = 8'd3;
    localparam [7:0] EV_POOL_CH2      = 8'd4;
    localparam [7:0] EV_FILL_CH2      = 8'd5;
    localparam [7:0] EV_CH1_CH2       = 8'd6;
    localparam [7:0] EV_CH2_POOL      = 8'd7;
    localparam [7:0] EV_DRAIN_CH2     = 8'd8;
    localparam [7:0] EV_DOWN_EXIT     = 8'd9;
    localparam [7:0] EV_FRESH_CH1     = 8'd10;
    localparam [7:0] EV_LOAD_CH2      = 8'd11;
    localparam [7:0] EV_CH2_CH1       = 8'd12;
    localparam [7:0] EV_UP_EXIT       = 8'd13;

    localparam [4:0] ST_IDLE               = 5'd0;
    localparam [4:0] ST_DN_LOAD_WAIT       = 5'd1;
    localparam [4:0] ST_DN_CH1_DOWN_WAIT   = 5'd2;
    localparam [4:0] ST_DN_CH2_UP_WAIT     = 5'd3;
    localparam [4:0] ST_DN_XFER_WAIT       = 5'd4;
    localparam [4:0] ST_DN_CH2_DOWN_WAIT   = 5'd5;
    localparam [4:0] ST_DN_EXIT_WAIT       = 5'd6;
    localparam [4:0] ST_DN_RESTORE_WAIT    = 5'd7;
    localparam [4:0] ST_UP_LOAD_WAIT       = 5'd8;
    localparam [4:0] ST_UP_CH2_UP_WAIT     = 5'd9;
    localparam [4:0] ST_UP_CH1_DOWN_WAIT   = 5'd10;
    localparam [4:0] ST_UP_XFER_WAIT       = 5'd11;
    localparam [4:0] ST_UP_CH1_UP_WAIT     = 5'd12;
    localparam [4:0] ST_UP_EXIT_WAIT       = 5'd13;
    localparam [4:0] ST_UP_RESTORE_WAIT    = 5'd14;

    reg [3:0] one_sec_div;

    always @(posedge clk) begin
        if (rst) begin
            pop_up_lane <= 1'b0;
            pop_dn_lane <= 1'b0;
            water_start <= 1'b0;
            water_cmd <= CMD_NONE;
            anim_start <= 1'b0;
            anim_event <= AN_NONE;
            busy <= 1'b0;
            batch_dir_up <= 1'b0;
            batch_ships <= 0;
            batch_types <= 0;
            batch_loc <= 0;
            cycle_save <= 1'b1;
            last_event <= EV_IDLE;
            state_code <= ST_IDLE;
            passed_total <= 0;
            wait_accum_seconds <= 0;
            one_sec_div <= 0;
        end else begin
            pop_up_lane <= 1'b0;
            pop_dn_lane <= 1'b0;
            water_start <= 1'b0;
            anim_start <= 1'b0;

            // Queue-length integral used as the displayed wait proxy.
            if (tick_sim) begin
                if (one_sec_div == 4'd9) begin
                    one_sec_div <= 0;
                    wait_accum_seconds <= wait_accum_seconds + up_q_count + dn_q_count;
                end else begin
                    one_sec_div <= one_sec_div + 1'b1;
                end
            end

            case (state_code)
                ST_IDLE: begin
                    busy <= 1'b0;
                    batch_loc <= 0;
                    if (choose_pulse) begin
                        busy <= 1'b1;
                        batch_dir_up <= choose_dir_up;
                        cycle_save <= ~policy_eff;

                        if (!choose_dir_up) begin
                            batch_ships <= up_sel_ships;
                            batch_types <= up_sel_types;
                            pop_up_lane <= 1'b1;
                            anim_event <= AN_LOAD_CH1_DN;
                            anim_start <= 1'b1;
                            last_event <= EV_LOAD_CH1;
                            state_code <= ST_DN_LOAD_WAIT;
                        end else begin
                            batch_ships <= dn_sel_ships;
                            batch_types <= dn_sel_types;
                            pop_dn_lane <= 1'b1;
                            anim_event <= AN_LOAD_CH2_UP;
                            anim_start <= 1'b1;
                            last_event <= EV_LOAD_CH2;
                            state_code <= ST_UP_LOAD_WAIT;
                        end
                    end
                end

                ST_DN_LOAD_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 2'd1;
                        water_cmd <= cycle_save ? CMD_CH1_DOWN_SAVE : CMD_CH1_DOWN_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_CH1_POOL : EV_DRAIN_CH1;
                        state_code <= ST_DN_CH1_DOWN_WAIT;
                    end
                end

                ST_DN_CH1_DOWN_WAIT: begin
                    if (water_done) begin
                        water_cmd <= cycle_save ? CMD_CH2_UP_SAVE : CMD_CH2_UP_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_POOL_CH2 : EV_FILL_CH2;
                        state_code <= ST_DN_CH2_UP_WAIT;
                    end
                end

                ST_DN_CH2_UP_WAIT: begin
                    if (water_done) begin
                        anim_event <= AN_CH1_CH2_DN;
                        anim_start <= 1'b1;
                        last_event <= EV_CH1_CH2;
                        state_code <= ST_DN_XFER_WAIT;
                    end
                end

                ST_DN_XFER_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 2'd2;
                        water_cmd <= cycle_save ? CMD_CH2_DOWN_SAVE : CMD_CH2_DOWN_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_CH2_POOL : EV_DRAIN_CH2;
                        state_code <= ST_DN_CH2_DOWN_WAIT;
                    end
                end

                ST_DN_CH2_DOWN_WAIT: begin
                    if (water_done) begin
                        anim_event <= AN_EXIT_DN;
                        anim_start <= 1'b1;
                        last_event <= EV_DOWN_EXIT;
                        state_code <= ST_DN_EXIT_WAIT;
                    end
                end

                ST_DN_EXIT_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 0;
                        passed_total <= passed_total + batch_ships;
                        water_cmd <= CMD_CH1_UP_FRESH;
                        water_start <= 1'b1;
                        last_event <= EV_FRESH_CH1;
                        state_code <= ST_DN_RESTORE_WAIT;
                    end
                end

                ST_DN_RESTORE_WAIT: begin
                    if (water_done) begin
                        busy <= 1'b0;
                        last_event <= EV_IDLE;
                        state_code <= ST_IDLE;
                    end
                end

                ST_UP_LOAD_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 2'd2;
                        water_cmd <= cycle_save ? CMD_CH2_UP_SAVE : CMD_CH2_UP_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_POOL_CH2 : EV_FILL_CH2;
                        state_code <= ST_UP_CH2_UP_WAIT;
                    end
                end

                ST_UP_CH2_UP_WAIT: begin
                    if (water_done) begin
                        water_cmd <= cycle_save ? CMD_CH1_DOWN_SAVE : CMD_CH1_DOWN_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_CH1_POOL : EV_DRAIN_CH1;
                        state_code <= ST_UP_CH1_DOWN_WAIT;
                    end
                end

                ST_UP_CH1_DOWN_WAIT: begin
                    if (water_done) begin
                        anim_event <= AN_CH2_CH1_UP;
                        anim_start <= 1'b1;
                        last_event <= EV_CH2_CH1;
                        state_code <= ST_UP_XFER_WAIT;
                    end
                end

                ST_UP_XFER_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 2'd1;
                        water_cmd <= CMD_CH1_UP_FRESH;
                        water_start <= 1'b1;
                        last_event <= EV_FRESH_CH1;
                        state_code <= ST_UP_CH1_UP_WAIT;
                    end
                end

                ST_UP_CH1_UP_WAIT: begin
                    if (water_done) begin
                        anim_event <= AN_EXIT_UP;
                        anim_start <= 1'b1;
                        last_event <= EV_UP_EXIT;
                        state_code <= ST_UP_EXIT_WAIT;
                    end
                end

                ST_UP_EXIT_WAIT: begin
                    if (anim_done) begin
                        batch_loc <= 0;
                        passed_total <= passed_total + batch_ships;
                        water_cmd <= cycle_save ? CMD_CH2_DOWN_SAVE : CMD_CH2_DOWN_FAST;
                        water_start <= 1'b1;
                        last_event <= cycle_save ? EV_CH2_POOL : EV_DRAIN_CH2;
                        state_code <= ST_UP_RESTORE_WAIT;
                    end
                end

                ST_UP_RESTORE_WAIT: begin
                    if (water_done) begin
                        busy <= 1'b0;
                        last_event <= EV_IDLE;
                        state_code <= ST_IDLE;
                    end
                end

                default: begin
                    busy <= 1'b0;
                    batch_loc <= 0;
                    state_code <= ST_IDLE;
                end
            endcase
        end
    end
endmodule
