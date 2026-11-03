`timescale 1ns/1ps
// One complete policy simulation: queues, scheduler, lock, water model and metrics.
module simulation_core_v5p #(
    parameter [1:0] POLICY_MODE = 2'd2
)(
    input  wire clk,
    input  wire rst,
    input  wire tick_sim,
    input  wire tick_anim,
    input  wire arrival_up_req,
    input  wire arrival_up_large,
    input  wire arrival_dn_req,
    input  wire arrival_dn_large,
    input  wire [1:0] sensitivity,

    output wire [23:0] up_lane,
    output wire [23:0] dn_lane,
    output wire [4:0] up_q_display,
    output wire [4:0] dn_q_display,
    output wire [6:0] ch1_water,
    output wire [6:0] ch2_water,
    output wire [6:0] pool_level,
    output wire [2:0] up_res_offset,
    output wire [2:0] dn_res_offset,
    output wire [3:0] flow_code,
    output reg  [5:0] flow_phase,
    output wire [1:0] batch_loc,
    output wire       batch_dir_up,
    output wire [2:0] batch_ships,
    output wire [7:0] batch_types,
    output wire       anim_busy,
    output wire [3:0] anim_event_active,
    output wire [9:0] anim_batch_x,
    output wire [2:0] anim_ship_count,
    output wire [7:0] anim_ship_types,
    output wire       anim_dir_up,
    output wire [5:0] gate1_lift,
    output wire [5:0] gate2_lift,
    output wire [5:0] gate3_lift,
    output wire [1:0] mode_display,
    output wire       policy_eff_display,
    output wire       core_busy,
    output wire [7:0] last_event,
    output wire [2:0] auto_reason,

    output wire [5:0] pressure_count,
    output wire [15:0] passed_total,
    output reg  [15:0] avg_wait_s,
    output reg  [15:0] fresh_per_ship,
    output reg  [7:0]  avg_load_pct,
    output reg  [6:0]  save_pct,
    output wire [6:0]  congestion_pct,
    output reg  [15:0] lockages,
    output wire [31:0] fresh_total,
    output wire [31:0] reused_total,
    output wire [31:0] discarded_total,
    output wire [15:0] input_overflow
);
    // Buffer arrivals before they enter the approach lanes.
    wire up_pending_valid, dn_pending_valid;
    wire up_pending_large, dn_pending_large;
    wire [6:0] up_pending_count, dn_pending_count;
    wire [15:0] up_overflow, dn_overflow;
    wire up_fifo_pop, dn_fifo_pop;

    arrival_fifo_v5p u_up_fifo(
        .clk(clk),
        .rst(rst),
        .push(arrival_up_req),
        .push_large(arrival_up_large),
        .pop(up_fifo_pop),
        .valid(up_pending_valid),
        .head_large(up_pending_large),
        .count(up_pending_count),
        .overflow_count(up_overflow));
    arrival_fifo_v5p u_dn_fifo(
        .clk(clk),
        .rst(rst),
        .push(arrival_dn_req),
        .push_large(arrival_dn_large),
        .pop(dn_fifo_pop),
        .valid(dn_pending_valid),
        .head_large(dn_pending_large),
        .count(dn_pending_count),
        .overflow_count(dn_overflow));
    assign input_overflow = up_overflow + dn_overflow;

    wire [4:0] up_lane_count, dn_lane_count;
    wire [5:0] up_lane_units, dn_lane_units;
    wire [2:0] up_sel_ships, dn_sel_ships;
    wire [2:0] up_sel_units, dn_sel_units;
    wire [7:0] up_sel_types, dn_sel_types;
    wire pop_up_lane, pop_dn_lane;

    // Keep FIFO admission aligned with the lane update phase.
    reg ca_phase;
    always @(posedge clk) begin
        if (rst) ca_phase <= 1'b0;
        else if (tick_sim) ca_phase <= ~ca_phase;
    end

    wire up_space_small = (up_lane[23:22] == 2'b00) && (up_lane[21:20] == 2'b00);
    wire up_space_large = up_space_small && (up_lane[19:18] == 2'b00);
    wire dn_space_small = (dn_lane[23:22] == 2'b00) && (dn_lane[21:20] == 2'b00);
    wire dn_space_large = dn_space_small && (dn_lane[19:18] == 2'b00);
    wire up_head_space = up_pending_large ? up_space_large : up_space_small;
    wire dn_head_space = dn_pending_large ? dn_space_large : dn_space_small;

    assign up_fifo_pop = tick_sim && ca_phase && up_pending_valid && up_head_space && !pop_up_lane;
    assign dn_fifo_pop = tick_sim && ca_phase && dn_pending_valid && dn_head_space && !pop_dn_lane;

    ca_lane_v5 u_up_lane(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .spawn_req(up_pending_valid),
        .spawn_large(up_pending_large),
        .pop_req(pop_up_lane),
        .lane_packed(up_lane),
        .q_count(up_lane_count),
        .q_units(up_lane_units),
        .sel_ships(up_sel_ships),
        .sel_units(up_sel_units),
        .sel_types(up_sel_types));
    ca_lane_v5 u_dn_lane(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .spawn_req(dn_pending_valid),
        .spawn_large(dn_pending_large),
        .pop_req(pop_dn_lane),
        .lane_packed(dn_lane),
        .q_count(dn_lane_count),
        .q_units(dn_lane_units),
        .sel_ships(dn_sel_ships),
        .sel_units(dn_sel_units),
        .sel_types(dn_sel_types));

    wire [6:0] up_pressure_raw = {2'b00,up_lane_count} + up_pending_count;
    wire [6:0] dn_pressure_raw = {2'b00,dn_lane_count} + dn_pending_count;
    wire [5:0] up_pressure = (up_pressure_raw > 7'd63) ? 6'd63 : up_pressure_raw[5:0];
    wire [5:0] dn_pressure = (dn_pressure_raw > 7'd63) ? 6'd63 : dn_pressure_raw[5:0];
    wire [6:0] pressure_sum_raw = {1'b0,up_pressure} + {1'b0,dn_pressure};
    assign pressure_count = (pressure_sum_raw > 7'd63) ? 6'd63 : pressure_sum_raw[5:0];
    assign up_q_display = (up_pressure > 6'd31) ? 5'd31 : up_pressure[4:0];
    assign dn_q_display = (dn_pressure > 6'd31) ? 5'd31 : dn_pressure[4:0];

    // Scheduler and physical model
    wire choose_pulse, choose_dir_up, policy_eff;
    wire [11:0] up_wait_age, dn_wait_age;
    scheduler_v5p #(.POLICY_MODE(POLICY_MODE)) u_scheduler(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .busy(core_busy),
        .sensitivity(sensitivity),
        .up_lane_count(up_lane_count),
        .dn_lane_count(dn_lane_count),
        .up_lane_units(up_lane_units),
        .dn_lane_units(dn_lane_units),
        .up_pressure_count(up_pressure),
        .dn_pressure_count(dn_pressure),
        .pool_level(pool_level),
        .choose_pulse(choose_pulse),
        .choose_dir_up(choose_dir_up),
        .policy_eff(policy_eff),
        .mode_display(mode_display),
        .up_wait_age(up_wait_age),
        .dn_wait_age(dn_wait_age),
        .auto_reason(auto_reason));

    wire water_start, water_busy, water_done;
    wire [3:0] water_cmd, water_active_cmd;
    water_model_v5 u_water(
        .clk(clk),
        .rst(rst),
        .tick_anim(tick_anim),
        .cmd_start(water_start),
        .cmd(water_cmd),
        .busy(water_busy),
        .done(water_done),
        .active_cmd(water_active_cmd),
        .ch1_water(ch1_water),
        .ch2_water(ch2_water),
        .pool_level(pool_level),
        .fresh_total(fresh_total),
        .reused_total(reused_total),
        .discarded_total(discarded_total),
        .up_res_offset(up_res_offset),
        .dn_res_offset(dn_res_offset),
        .flow_code(flow_code));

    wire anim_start, anim_done;
    wire [3:0] anim_event_cmd;
    animation_v5 u_animation(
        .clk(clk),
        .rst(rst),
        .tick_anim(tick_anim),
        .start(anim_start),
        .event_code(anim_event_cmd),
        .ship_count_in(batch_ships),
        .ship_types_in(batch_types),
        .dir_up_in(batch_dir_up),
        .busy(anim_busy),
        .done(anim_done),
        .event_active(anim_event_active),
        .ship_count(anim_ship_count),
        .ship_types(anim_ship_types),
        .dir_up(anim_dir_up),
        .batch_x(anim_batch_x),
        .gate1_lift(gate1_lift),
        .gate2_lift(gate2_lift),
        .gate3_lift(gate3_lift),
        .phase());

    wire cycle_save;
    wire [4:0] state_code;
    wire [31:0] wait_accum_seconds;
    lock_core_v5 u_lock(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .choose_pulse(choose_pulse),
        .choose_dir_up(choose_dir_up),
        .policy_eff(policy_eff),
        .up_sel_ships(up_sel_ships),
        .up_sel_types(up_sel_types),
        .dn_sel_ships(dn_sel_ships),
        .dn_sel_types(dn_sel_types),
        .up_q_count(up_pressure),
        .dn_q_count(dn_pressure),
        .water_busy(water_busy),
        .water_done(water_done),
        .anim_busy(anim_busy),
        .anim_done(anim_done),
        .pop_up_lane(pop_up_lane),
        .pop_dn_lane(pop_dn_lane),
        .water_start(water_start),
        .water_cmd(water_cmd),
        .anim_start(anim_start),
        .anim_event(anim_event_cmd),
        .busy(core_busy),
        .batch_dir_up(batch_dir_up),
        .batch_ships(batch_ships),
        .batch_types(batch_types),
        .batch_loc(batch_loc),
        .cycle_save(cycle_save),
        .last_event(last_event),
        .state_code(state_code),
        .passed_total(passed_total),
        .wait_accum_seconds(wait_accum_seconds));

    assign policy_eff_display = core_busy ? ~cycle_save : policy_eff;

    always @(posedge clk) begin
        if (rst) flow_phase <= 0;
        else if (tick_anim) flow_phase <= flow_phase + 1'b1;
    end

    // Metrics are updated outside the VGA pixel path.
    reg [31:0] load_units_accum;
    always @(posedge clk) begin
        if (rst) begin
            lockages <= 0;
            load_units_accum <= 0;
        end else if (choose_pulse) begin
            if (lockages != 16'hFFFF) lockages <= lockages + 1'b1;
            load_units_accum <= load_units_accum + (choose_dir_up ? dn_sel_units : up_sel_units);
        end
    end

    reg metric_start;
    reg [31:0] avg_dividend, fresh_dividend, save_dividend, load_dividend;
    reg [15:0] pass_divisor, water_divisor, lock_divisor;
    wire [31:0] total_used_water = fresh_total + reused_total;
    wire [31:0] reused_x100 = (reused_total << 6) + (reused_total << 5) + (reused_total << 2);
    wire [31:0] load_x25 = (load_units_accum << 4) + (load_units_accum << 3) + load_units_accum;

    always @(posedge clk) begin
        if (rst) begin
            metric_start <= 0;
            avg_dividend <= 0; fresh_dividend <= 0; save_dividend <= 0; load_dividend <= 0;
            pass_divisor <= 0; water_divisor <= 0; lock_divisor <= 0;
        end else begin
            metric_start <= tick_sim;
            if (tick_sim) begin
                avg_dividend <= wait_accum_seconds;
                fresh_dividend <= fresh_total;
                save_dividend <= reused_x100;
                load_dividend <= load_x25;
                pass_divisor <= passed_total;
                water_divisor <= (total_used_water[31:16] != 0) ? 16'hFFFF : total_used_water[15:0];
                lock_divisor <= lockages;
            end
        end
    end

    wire [31:0] avg_q, fresh_q, save_q, load_q;
    wire avg_done, fresh_done, save_done, load_done;
    u32_div_u16 d0(.clk(clk),
        .rst(rst),
        .start(metric_start),
        .dividend(avg_dividend),
        .divisor(pass_divisor),
        .quotient(avg_q),
        .busy(),
        .done(avg_done));
    u32_div_u16 d1(.clk(clk),
        .rst(rst),
        .start(metric_start),
        .dividend(fresh_dividend),
        .divisor(pass_divisor),
        .quotient(fresh_q),
        .busy(),
        .done(fresh_done));
    u32_div_u16 d2(.clk(clk),
        .rst(rst),
        .start(metric_start),
        .dividend(save_dividend),
        .divisor(water_divisor),
        .quotient(save_q),
        .busy(),
        .done(save_done));
    u32_div_u16 d3(.clk(clk),
        .rst(rst),
        .start(metric_start),
        .dividend(load_dividend),
        .divisor(lock_divisor),
        .quotient(load_q),
        .busy(),
        .done(load_done));

    always @(posedge clk) begin
        if (rst) begin
            avg_wait_s <= 0;
            fresh_per_ship <= 0;
            save_pct <= 0;
            avg_load_pct <= 0;
        end else begin
            if (avg_done) avg_wait_s <= (avg_q[31:16] != 0) ? 16'hFFFF : avg_q[15:0];
            if (fresh_done) fresh_per_ship <= (fresh_q[31:16] != 0) ? 16'hFFFF : fresh_q[15:0];
            if (save_done) save_pct <= (save_q > 100) ? 7'd100 : save_q[6:0];
            if (load_done) avg_load_pct <= (load_q > 100) ? 8'd100 : load_q[7:0];
        end
    end

    // 40 queued/pending ships maps to 100% congestion.
    wire [8:0] cong_scaled = ({3'b000,pressure_count} << 1)
                           + ({3'b000,pressure_count} >> 1);
    assign congestion_pct = (cong_scaled >= 9'd100) ? 7'd100 : cong_scaled[6:0];
endmodule
