`timescale 1ns/1ps
// Bidirectional scheduler. POLICY_MODE: 0=EFF, 1=SAVE, 2=AUTO.
module scheduler_v5p #(
    parameter [1:0] POLICY_MODE = 2'd2
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_sim,
    input  wire       busy,
    input  wire [1:0] sensitivity,
    input  wire [4:0] up_lane_count,
    input  wire [4:0] dn_lane_count,
    input  wire [5:0] up_lane_units,
    input  wire [5:0] dn_lane_units,
    input  wire [5:0] up_pressure_count,
    input  wire [5:0] dn_pressure_count,
    input  wire [6:0] pool_level,

    output reg        choose_pulse,
    output reg        choose_dir_up,
    output reg        policy_eff,
    output wire [1:0] mode_display,
    output reg [11:0] up_wait_age,
    output reg [11:0] dn_wait_age,
    output reg [2:0]  auto_reason
);
    reg prefer_up;
    reg auto_eff;

    wire [6:0] total_pressure = up_pressure_count + dn_pressure_count;
    wire [6:0] auto_hi =
        (sensitivity == 2'b00) ? 7'd5  :
        (sensitivity == 2'b01) ? 7'd8  :
        (sensitivity == 2'b10) ? 7'd11 : 7'd14;
    wire [6:0] auto_lo =
        (sensitivity == 2'b00) ? 7'd2 :
        (sensitivity == 2'b01) ? 7'd4 :
        (sensitivity == 2'b10) ? 7'd6 : 7'd8;

    wire effective_eff = (POLICY_MODE == 2'd0) ? 1'b1 :
                         (POLICY_MODE == 2'd1) ? 1'b0 : auto_eff;
    assign mode_display = POLICY_MODE;

    // SAVE waits for a fuller batch, with timeout guards to prevent starvation.
    wire up_ready_save = (up_lane_units >= 6'd4) || (up_wait_age >= 12'd50) ||
                         ((dn_pressure_count == 0) && (up_wait_age >= 12'd25));
    wire dn_ready_save = (dn_lane_units >= 6'd4) || (dn_wait_age >= 12'd50) ||
                         ((up_pressure_count == 0) && (dn_wait_age >= 12'd25));

    wire up_ready = (up_lane_count != 0) && (effective_eff || up_ready_save);
    wire dn_ready = (dn_lane_count != 0) && (effective_eff || dn_ready_save);

    always @(posedge clk) begin
        if (rst) begin
            choose_pulse <= 1'b0;
            choose_dir_up <= 1'b0;
            policy_eff <= (POLICY_MODE == 2'd0);
            up_wait_age <= 0;
            dn_wait_age <= 0;
            prefer_up <= 1'b0;
            auto_eff <= 1'b0;
            auto_reason <= 3'd3; // low load
        end else begin
            choose_pulse <= 1'b0;
            policy_eff <= effective_eff;

            if (tick_sim) begin
                if (up_pressure_count != 0) begin
                    if (up_wait_age != 12'hFFF) up_wait_age <= up_wait_age + 1'b1;
                end else up_wait_age <= 0;

                if (dn_pressure_count != 0) begin
                    if (dn_wait_age != 12'hFFF) dn_wait_age <= dn_wait_age + 1'b1;
                end else dn_wait_age <= 0;

                if (POLICY_MODE == 2'd2) begin
                    if (total_pressure >= auto_hi) begin
                        auto_eff <= 1'b1;
                        auto_reason <= 3'd1; // queue pressure
                    end else if ((up_wait_age >= 12'd40) || (dn_wait_age >= 12'd40)) begin
                        auto_eff <= 1'b1;
                        auto_reason <= 3'd2; // wait
                    end else if (total_pressure <= auto_lo) begin
                        auto_eff <= 1'b0;
                        auto_reason <= 3'd3; // low load
                    end else if ((pool_level < 7'd15) && !auto_eff) begin
                        auto_eff <= 1'b0;
                        auto_reason <= 3'd4; // build / conserve
                    end else begin
                        auto_reason <= 3'd0; // hysteresis balance
                    end
                end else if (POLICY_MODE == 2'd0) begin
                    auto_reason <= 3'd5;
                end else begin
                    auto_reason <= 3'd6;
                end

                if (!busy && (up_ready || dn_ready)) begin
                    choose_pulse <= 1'b1;
                    if (up_ready && !dn_ready) begin
                        choose_dir_up <= 1'b0;
                        prefer_up <= 1'b1;
                        up_wait_age <= 0;
                    end else if (dn_ready && !up_ready) begin
                        choose_dir_up <= 1'b1;
                        prefer_up <= 1'b0;
                        dn_wait_age <= 0;
                    end else if (up_wait_age > dn_wait_age + 12'd20) begin
                        choose_dir_up <= 1'b0;
                        prefer_up <= 1'b1;
                        up_wait_age <= 0;
                    end else if (dn_wait_age > up_wait_age + 12'd20) begin
                        choose_dir_up <= 1'b1;
                        prefer_up <= 1'b0;
                        dn_wait_age <= 0;
                    end else if (up_lane_units > dn_lane_units) begin
                        choose_dir_up <= 1'b0;
                        prefer_up <= 1'b1;
                        up_wait_age <= 0;
                    end else if (dn_lane_units > up_lane_units) begin
                        choose_dir_up <= 1'b1;
                        prefer_up <= 1'b0;
                        dn_wait_age <= 0;
                    end else begin
                        choose_dir_up <= prefer_up;
                        prefer_up <= ~prefer_up;
                        if (prefer_up) dn_wait_age <= 0;
                        else up_wait_age <= 0;
                    end
                end
            end
        end
    end
endmodule
