`timescale 1ns/1ps
module top(
    input  wire       clk,
    input  wire       pb0,
    input  wire       pb1,
    input  wire [7:0] sw,
    output wire [3:0] led,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);
    // PB0 resets the experiment; PB1 changes the VGA page.
    reg [3:0] por_count = 4'd0;
    reg [7:0] sw_meta = 0, sw_sync = 0;
    reg pb0_meta = 1'b1, pb0_sync = 1'b1;
    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
        pb0_meta <= pb0;
        pb0_sync <= pb0_meta;
        if (!por_count[3]) por_count <= por_count + 1'b1;
    end
    wire rst = (~por_count[3]) | (~pb0_sync);

    wire tick_sim, tick_anim, tick_second;
    tick_gen #(.CLK_HZ(100_000_000),
        .TICK_HZ(10)) u_tick_sim(.clk(clk),
        .rst(rst),
        .tick(tick_sim));
    tick_gen #(.CLK_HZ(100_000_000),
        .TICK_HZ(50)) u_tick_anim(.clk(clk),
        .rst(rst),
        .tick(tick_anim));
    tick_gen #(.CLK_HZ(100_000_000),
        .TICK_HZ(1))  u_tick_sec (.clk(clk),
        .rst(rst),
        .tick(tick_second));

    wire [1:0] page;
    button_page_v5p u_page(.clk(clk),
        .rst(rst),
        .pb_n(pb1),
        .page(page));

    // Shared traffic input for all three policy cores.
    wire [15:0] rnd;
    lfsr16 u_rng(.clk(clk),
        .rst(rst),
        .rnd(rnd));
    // LOW can recover; HIGH and PEAK are intended to build queue pressure.
    wire [7:0] spawn_threshold =
        (sw_sync[1:0]==2'b00) ? 8'd1 :
        (sw_sync[1:0]==2'b01) ? 8'd2 :
        (sw_sync[1:0]==2'b10) ? 8'd4 : 8'd7;
    wire up_arrival_req = tick_sim && (rnd[7:0] < spawn_threshold);
    wire dn_arrival_req = tick_sim && (rnd[15:8] < spawn_threshold);
    wire up_arrival_large =
        (sw_sync[5:4]==2'b00) ? (rnd[3:0] < 4'd2) :
        (sw_sync[5:4]==2'b01) ? (rnd[3:0] < 4'd4) :
        (sw_sync[5:4]==2'b10) ? (rnd[3:0] < 4'd8) : (rnd[3:0] < 4'd12);
    wire dn_arrival_large =
        (sw_sync[5:4]==2'b00) ? (rnd[11:8] < 4'd2) :
        (sw_sync[5:4]==2'b01) ? (rnd[11:8] < 4'd4) :
        (sw_sync[5:4]==2'b10) ? (rnd[11:8] < 4'd8) : (rnd[11:8] < 4'd12);

    // EFF core
    wire [23:0] e_up_lane,e_dn_lane; wire [4:0] e_up_q,e_dn_q;
    wire [6:0] e_ch1,e_ch2,e_pool; wire [2:0] e_uoff,e_doff; wire [3:0] e_flow; wire [5:0] e_phase;
    wire [1:0] e_bloc; wire e_bdir; wire [2:0] e_bships; wire [7:0] e_btypes;
    wire e_abusy; wire [3:0] e_aevent; wire [9:0] e_ax; wire [2:0] e_aships; wire [7:0] e_atypes; wire e_adir;
    wire [5:0] e_g1,e_g2,e_g3; wire [1:0] e_mode; wire e_peff,e_busy; wire [7:0] e_event; wire [2:0] e_reason;
    wire [5:0] e_pressure; wire [15:0] e_pass,e_wait,e_fresh; wire [7:0] e_load; wire [6:0] e_save,e_cong; wire [15:0] e_locks;
    wire [31:0] e_fresh_total,e_reused,e_discard; wire [15:0] e_overflow;

    // SAVE core
    wire [23:0] s_up_lane,s_dn_lane; wire [4:0] s_up_q,s_dn_q;
    wire [6:0] s_ch1,s_ch2,s_pool; wire [2:0] s_uoff,s_doff; wire [3:0] s_flow; wire [5:0] s_phase;
    wire [1:0] s_bloc; wire s_bdir; wire [2:0] s_bships; wire [7:0] s_btypes;
    wire s_abusy; wire [3:0] s_aevent; wire [9:0] s_ax; wire [2:0] s_aships; wire [7:0] s_atypes; wire s_adir;
    wire [5:0] s_g1,s_g2,s_g3; wire [1:0] s_mode; wire s_peff,s_busy; wire [7:0] s_event; wire [2:0] s_reason;
    wire [5:0] s_pressure; wire [15:0] s_pass,s_wait,s_fresh; wire [7:0] s_load; wire [6:0] s_save,s_cong; wire [15:0] s_locks;
    wire [31:0] s_fresh_total,s_reused,s_discard; wire [15:0] s_overflow;

    // AUTO core
    wire [23:0] a_up_lane,a_dn_lane; wire [4:0] a_up_q,a_dn_q;
    wire [6:0] a_ch1,a_ch2,a_pool; wire [2:0] a_uoff,a_doff; wire [3:0] a_flow; wire [5:0] a_phase;
    wire [1:0] a_bloc; wire a_bdir; wire [2:0] a_bships; wire [7:0] a_btypes;
    wire a_abusy; wire [3:0] a_aevent; wire [9:0] a_ax; wire [2:0] a_aships; wire [7:0] a_atypes; wire a_adir;
    wire [5:0] a_g1,a_g2,a_g3; wire [1:0] a_mode; wire a_peff,a_busy; wire [7:0] a_event; wire [2:0] a_reason;
    wire [5:0] a_pressure; wire [15:0] a_pass,a_wait,a_fresh; wire [7:0] a_load; wire [6:0] a_save,a_cong; wire [15:0] a_locks;
    wire [31:0] a_fresh_total,a_reused,a_discard; wire [15:0] a_overflow;

    simulation_core_v5p #(.POLICY_MODE(2'd0)) u_eff(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .tick_anim(tick_anim),
        .arrival_up_req(up_arrival_req),
        .arrival_up_large(up_arrival_large),
        .arrival_dn_req(dn_arrival_req),
        .arrival_dn_large(dn_arrival_large),
        .sensitivity(sw_sync[7:6]),
        .up_lane(e_up_lane),
        .dn_lane(e_dn_lane),
        .up_q_display(e_up_q),
        .dn_q_display(e_dn_q),
        .ch1_water(e_ch1),
        .ch2_water(e_ch2),
        .pool_level(e_pool),
        .up_res_offset(e_uoff),
        .dn_res_offset(e_doff),
        .flow_code(e_flow),
        .flow_phase(e_phase),
        .batch_loc(e_bloc),
        .batch_dir_up(e_bdir),
        .batch_ships(e_bships),
        .batch_types(e_btypes),
        .anim_busy(e_abusy),
        .anim_event_active(e_aevent),
        .anim_batch_x(e_ax),
        .anim_ship_count(e_aships),
        .anim_ship_types(e_atypes),
        .anim_dir_up(e_adir),
        .gate1_lift(e_g1),
        .gate2_lift(e_g2),
        .gate3_lift(e_g3),
        .mode_display(e_mode),
        .policy_eff_display(e_peff),
        .core_busy(e_busy),
        .last_event(e_event),
        .auto_reason(e_reason),
        .pressure_count(e_pressure),
        .passed_total(e_pass),
        .avg_wait_s(e_wait),
        .fresh_per_ship(e_fresh),
        .avg_load_pct(e_load),
        .save_pct(e_save),
        .congestion_pct(e_cong),
        .lockages(e_locks),
        .fresh_total(e_fresh_total),
        .reused_total(e_reused),
        .discarded_total(e_discard),
        .input_overflow(e_overflow)
    );

    simulation_core_v5p #(.POLICY_MODE(2'd1)) u_save(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .tick_anim(tick_anim),
        .arrival_up_req(up_arrival_req),
        .arrival_up_large(up_arrival_large),
        .arrival_dn_req(dn_arrival_req),
        .arrival_dn_large(dn_arrival_large),
        .sensitivity(sw_sync[7:6]),
        .up_lane(s_up_lane),
        .dn_lane(s_dn_lane),
        .up_q_display(s_up_q),
        .dn_q_display(s_dn_q),
        .ch1_water(s_ch1),
        .ch2_water(s_ch2),
        .pool_level(s_pool),
        .up_res_offset(s_uoff),
        .dn_res_offset(s_doff),
        .flow_code(s_flow),
        .flow_phase(s_phase),
        .batch_loc(s_bloc),
        .batch_dir_up(s_bdir),
        .batch_ships(s_bships),
        .batch_types(s_btypes),
        .anim_busy(s_abusy),
        .anim_event_active(s_aevent),
        .anim_batch_x(s_ax),
        .anim_ship_count(s_aships),
        .anim_ship_types(s_atypes),
        .anim_dir_up(s_adir),
        .gate1_lift(s_g1),
        .gate2_lift(s_g2),
        .gate3_lift(s_g3),
        .mode_display(s_mode),
        .policy_eff_display(s_peff),
        .core_busy(s_busy),
        .last_event(s_event),
        .auto_reason(s_reason),
        .pressure_count(s_pressure),
        .passed_total(s_pass),
        .avg_wait_s(s_wait),
        .fresh_per_ship(s_fresh),
        .avg_load_pct(s_load),
        .save_pct(s_save),
        .congestion_pct(s_cong),
        .lockages(s_locks),
        .fresh_total(s_fresh_total),
        .reused_total(s_reused),
        .discarded_total(s_discard),
        .input_overflow(s_overflow)
    );

    simulation_core_v5p #(.POLICY_MODE(2'd2)) u_auto(
        .clk(clk),
        .rst(rst),
        .tick_sim(tick_sim),
        .tick_anim(tick_anim),
        .arrival_up_req(up_arrival_req),
        .arrival_up_large(up_arrival_large),
        .arrival_dn_req(dn_arrival_req),
        .arrival_dn_large(dn_arrival_large),
        .sensitivity(sw_sync[7:6]),
        .up_lane(a_up_lane),
        .dn_lane(a_dn_lane),
        .up_q_display(a_up_q),
        .dn_q_display(a_dn_q),
        .ch1_water(a_ch1),
        .ch2_water(a_ch2),
        .pool_level(a_pool),
        .up_res_offset(a_uoff),
        .dn_res_offset(a_doff),
        .flow_code(a_flow),
        .flow_phase(a_phase),
        .batch_loc(a_bloc),
        .batch_dir_up(a_bdir),
        .batch_ships(a_bships),
        .batch_types(a_btypes),
        .anim_busy(a_abusy),
        .anim_event_active(a_aevent),
        .anim_batch_x(a_ax),
        .anim_ship_count(a_aships),
        .anim_ship_types(a_atypes),
        .anim_dir_up(a_adir),
        .gate1_lift(a_g1),
        .gate2_lift(a_g2),
        .gate3_lift(a_g3),
        .mode_display(a_mode),
        .policy_eff_display(a_peff),
        .core_busy(a_busy),
        .last_event(a_event),
        .auto_reason(a_reason),
        .pressure_count(a_pressure),
        .passed_total(a_pass),
        .avg_wait_s(a_wait),
        .fresh_per_ship(a_fresh),
        .avg_load_pct(a_load),
        .save_pct(a_save),
        .congestion_pct(a_cong),
        .lockages(a_locks),
        .fresh_total(a_fresh_total),
        .reused_total(a_reused),
        .discarded_total(a_discard),
        .input_overflow(a_overflow)
    );

    // Display values
    wire [15:0] e_pass_bcd,e_wait_bcd,e_fresh_bcd,e_load_bcd,e_cong_bcd,e_save_bcd,e_pool_bcd;
    wire [15:0] s_pass_bcd,s_wait_bcd,s_fresh_bcd,s_load_bcd,s_cong_bcd,s_save_bcd,s_pool_bcd;
    wire [15:0] a_pass_bcd,a_wait_bcd,a_fresh_bcd,a_load_bcd,a_cong_bcd,a_save_bcd,a_pool_bcd;
    core_bcd_v5p be(.clk(clk),
        .rst(rst),
        .refresh(tick_sim),
        .passed_total(e_pass),
        .avg_wait_s(e_wait),
        .fresh_per_ship(e_fresh),
        .avg_load_pct(e_load),
        .congestion_pct(e_cong),
        .save_pct(e_save),
        .pool_level(e_pool),
        .pass_bcd(e_pass_bcd),
        .avg_bcd(e_wait_bcd),
        .fresh_bcd(e_fresh_bcd),
        .load_bcd(e_load_bcd),
        .cong_bcd(e_cong_bcd),
        .save_bcd(e_save_bcd),
        .pool_bcd(e_pool_bcd));
    core_bcd_v5p bs(.clk(clk),
        .rst(rst),
        .refresh(tick_sim),
        .passed_total(s_pass),
        .avg_wait_s(s_wait),
        .fresh_per_ship(s_fresh),
        .avg_load_pct(s_load),
        .congestion_pct(s_cong),
        .save_pct(s_save),
        .pool_level(s_pool),
        .pass_bcd(s_pass_bcd),
        .avg_bcd(s_wait_bcd),
        .fresh_bcd(s_fresh_bcd),
        .load_bcd(s_load_bcd),
        .cong_bcd(s_cong_bcd),
        .save_bcd(s_save_bcd),
        .pool_bcd(s_pool_bcd));
    core_bcd_v5p ba(.clk(clk),
        .rst(rst),
        .refresh(tick_sim),
        .passed_total(a_pass),
        .avg_wait_s(a_wait),
        .fresh_per_ship(a_fresh),
        .avg_load_pct(a_load),
        .congestion_pct(a_cong),
        .save_pct(a_save),
        .pool_level(a_pool),
        .pass_bcd(a_pass_bcd),
        .avg_bcd(a_wait_bcd),
        .fresh_bcd(a_fresh_bcd),
        .load_bcd(a_load_bcd),
        .cong_bcd(a_cong_bcd),
        .save_bcd(a_save_bcd),
        .pool_bcd(a_pool_bcd));

    // MAIN page source. The unselected cores continue to run.
    reg [23:0] m_up_lane,m_dn_lane; reg [4:0] m_up_q,m_dn_q;
    reg [6:0] m_ch1,m_ch2,m_pool; reg [2:0] m_uoff,m_doff; reg [3:0] m_flow; reg [5:0] m_phase;
    reg [1:0] m_bloc,m_mode; reg m_bdir,m_abusy,m_adir,m_peff,m_busy; reg [2:0] m_bships,m_aships;
    reg [7:0] m_btypes,m_atypes,m_event; reg [3:0] m_aevent; reg [9:0] m_ax; reg [5:0] m_g1,m_g2,m_g3;
    reg [15:0] m_pass_bcd,m_wait_bcd,m_fresh_bcd,m_save_bcd,m_pool_bcd,m_cong_bcd;

    always @(posedge clk) begin
        if (rst) begin
            m_up_lane<=0;m_dn_lane<=0;m_up_q<=0;m_dn_q<=0;m_ch1<=100;m_ch2<=0;m_pool<=50;m_uoff<=0;m_doff<=0;m_flow<=0;m_phase<=0;
            m_bloc<=0;m_mode<=2;m_bdir<=0;m_bships<=0;m_btypes<=0;m_abusy<=0;m_aevent<=0;m_ax<=0;m_aships<=0;m_atypes<=0;m_adir<=0;
            m_g1<=0;m_g2<=0;m_g3<=0;m_peff<=0;m_busy<=0;m_event<=0;m_pass_bcd<=0;m_wait_bcd<=0;m_fresh_bcd<=0;m_save_bcd<=0;m_pool_bcd<=0;m_cong_bcd<=0;
        end else if (sw_sync[3:2]==2'b00) begin
            m_up_lane<=e_up_lane;m_dn_lane<=e_dn_lane;m_up_q<=e_up_q;m_dn_q<=e_dn_q;m_ch1<=e_ch1;m_ch2<=e_ch2;m_pool<=e_pool;m_uoff<=e_uoff;m_doff<=e_doff;m_flow<=e_flow;m_phase<=e_phase;
            m_bloc<=e_bloc;m_mode<=e_mode;m_bdir<=e_bdir;m_bships<=e_bships;m_btypes<=e_btypes;m_abusy<=e_abusy;m_aevent<=e_aevent;m_ax<=e_ax;m_aships<=e_aships;m_atypes<=e_atypes;m_adir<=e_adir;
            m_g1<=e_g1;m_g2<=e_g2;m_g3<=e_g3;m_peff<=e_peff;m_busy<=e_busy;m_event<=e_event;m_pass_bcd<=e_pass_bcd;m_wait_bcd<=e_wait_bcd;m_fresh_bcd<=e_fresh_bcd;m_save_bcd<=e_save_bcd;m_pool_bcd<=e_pool_bcd;m_cong_bcd<=e_cong_bcd;
        end else if (sw_sync[3:2]==2'b01) begin
            m_up_lane<=s_up_lane;m_dn_lane<=s_dn_lane;m_up_q<=s_up_q;m_dn_q<=s_dn_q;m_ch1<=s_ch1;m_ch2<=s_ch2;m_pool<=s_pool;m_uoff<=s_uoff;m_doff<=s_doff;m_flow<=s_flow;m_phase<=s_phase;
            m_bloc<=s_bloc;m_mode<=s_mode;m_bdir<=s_bdir;m_bships<=s_bships;m_btypes<=s_btypes;m_abusy<=s_abusy;m_aevent<=s_aevent;m_ax<=s_ax;m_aships<=s_aships;m_atypes<=s_atypes;m_adir<=s_adir;
            m_g1<=s_g1;m_g2<=s_g2;m_g3<=s_g3;m_peff<=s_peff;m_busy<=s_busy;m_event<=s_event;m_pass_bcd<=s_pass_bcd;m_wait_bcd<=s_wait_bcd;m_fresh_bcd<=s_fresh_bcd;m_save_bcd<=s_save_bcd;m_pool_bcd<=s_pool_bcd;m_cong_bcd<=s_cong_bcd;
        end else begin
            m_up_lane<=a_up_lane;m_dn_lane<=a_dn_lane;m_up_q<=a_up_q;m_dn_q<=a_dn_q;m_ch1<=a_ch1;m_ch2<=a_ch2;m_pool<=a_pool;m_uoff<=a_uoff;m_doff<=a_doff;m_flow<=a_flow;m_phase<=a_phase;
            m_bloc<=a_bloc;m_mode<=a_mode;m_bdir<=a_bdir;m_bships<=a_bships;m_btypes<=a_btypes;m_abusy<=a_abusy;m_aevent<=a_aevent;m_ax<=a_ax;m_aships<=a_aships;m_atypes<=a_atypes;m_adir<=a_adir;
            m_g1<=a_g1;m_g2<=a_g2;m_g3<=a_g3;m_peff<=a_peff;m_busy<=a_busy;m_event<=a_event;m_pass_bcd<=a_pass_bcd;m_wait_bcd<=a_wait_bcd;m_fresh_bcd<=a_fresh_bcd;m_save_bcd<=a_save_bcd;m_pool_bcd<=a_pool_bcd;m_cong_bcd<=a_cong_bcd;
        end
    end

    // 32-second AUTO history used by the TREND page.
    wire [9:0] px,py; wire active; wire pixel_ce;
    vga_timing u_vga(.clk(clk),
        .rst(rst),
        .x(px),
        .y(py),
        .active(active),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .pixel_ce(pixel_ce));
    wire [4:0] hist_write_ptr;
    wire [4:0] hist_bin = (px>=10'd96 && px<10'd608) ? ((px-10'd96)>>4) : 5'd0;
    wire [4:0] hist_read_index = hist_write_ptr + hist_bin;
    wire [4:0] hist_prev_index = hist_read_index - 1'b1;
    wire [6:0] hist_queue,hist_fresh,hist_prev_queue,hist_prev_fresh; wire hist_policy,hist_prev_policy;
    trend_history_v5p u_hist(.clk(clk),
        .rst(rst),
        .sample_tick(tick_second),
        .queue_pressure(a_pressure),
        .fresh_per_ship(a_fresh),
        .policy_eff(a_peff),
        .read_index(hist_read_index),
        .read_prev_index(hist_prev_index),
        .write_ptr(hist_write_ptr),
        .read_queue(hist_queue),
        .read_fresh(hist_fresh),
        .read_policy(hist_policy),
        .read_prev_queue(hist_prev_queue),
        .read_prev_fresh(hist_prev_fresh),
        .read_prev_policy(hist_prev_policy));

    // MAIN page
    wire [3:0] main_r,main_g,main_b;
    vga_scene_v5 u_main_scene(
        .x(px),
        .y(py),
        .active(active),
        .up_lane(m_up_lane),
        .dn_lane(m_dn_lane),
        .up_q_count(m_up_q),
        .dn_q_count(m_dn_q),
        .ch1_water(m_ch1),
        .ch2_water(m_ch2),
        .pool_level(m_pool),
        .up_res_offset(m_uoff),
        .dn_res_offset(m_doff),
        .flow_code(m_flow),
        .flow_phase(m_phase),
        .batch_loc(m_bloc),
        .batch_dir_up(m_bdir),
        .batch_ships(m_bships),
        .batch_types(m_btypes),
        .anim_busy(m_abusy),
        .anim_event(m_aevent),
        .anim_batch_x(m_ax),
        .anim_ships(m_aships),
        .anim_types(m_atypes),
        .anim_dir_up(m_adir),
        .gate1_lift(m_g1),
        .gate2_lift(m_g2),
        .gate3_lift(m_g3),
        .mode_display(m_mode),
        .policy_eff(m_peff),
        .core_busy(m_busy),
        .last_event(m_event),
        .pass_bcd(m_pass_bcd),
        .avg_bcd(m_wait_bcd),
        .fresh_bcd(m_fresh_bcd),
        .save_bcd(m_save_bcd),
        .pool_bcd(m_pool_bcd),
        .cong_bcd(m_cong_bcd),
        .r(main_r),
        .g(main_g),
        .b(main_b));

    wire [3:0] aux_r,aux_g,aux_b;
    vga_aux_pages_v5p u_aux(
        .x(px),
        .y(py),
        .active(active),
        .page(page),
        .e_pass_bcd(e_pass_bcd),
        .e_wait_bcd(e_wait_bcd),
        .e_fresh_bcd(e_fresh_bcd),
        .e_load_bcd(e_load_bcd),
        .e_cong_bcd(e_cong_bcd),
        .s_pass_bcd(s_pass_bcd),
        .s_wait_bcd(s_wait_bcd),
        .s_fresh_bcd(s_fresh_bcd),
        .s_load_bcd(s_load_bcd),
        .s_cong_bcd(s_cong_bcd),
        .a_pass_bcd(a_pass_bcd),
        .a_wait_bcd(a_wait_bcd),
        .a_fresh_bcd(a_fresh_bcd),
        .a_load_bcd(a_load_bcd),
        .a_cong_bcd(a_cong_bcd),
        .e_wait_raw(e_wait),
        .s_wait_raw(s_wait),
        .a_wait_raw(a_wait),
        .e_fresh_raw(e_fresh),
        .s_fresh_raw(s_fresh),
        .a_fresh_raw(a_fresh),
        .a_policy_eff(a_peff),
        .hist_queue(hist_queue),
        .hist_fresh(hist_fresh),
        .hist_policy(hist_policy),
        .hist_prev_queue(hist_prev_queue),
        .hist_prev_fresh(hist_prev_fresh),
        .hist_prev_policy(hist_prev_policy),
        .r(aux_r),
        .g(aux_g),
        .b(aux_b));

    assign vga_r = (page==2'd0) ? main_r : aux_r;
    assign vga_g = (page==2'd0) ? main_g : aux_g;
    assign vga_b = (page==2'd0) ? main_b : aux_b;

    reg heartbeat;
    always @(posedge clk) begin
        if (rst) heartbeat <= 1'b0;
        else if (tick_second) heartbeat <= ~heartbeat;
    end
    assign led[0] = heartbeat;
    assign led[1] = a_peff;
    assign led[2] = (page==2'd1);
    assign led[3] = (e_overflow!=0)||(s_overflow!=0)||(a_overflow!=0);
endmodule
