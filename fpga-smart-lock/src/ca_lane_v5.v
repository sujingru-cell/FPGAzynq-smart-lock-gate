`timescale 1ns/1ps

// Cellular-automaton approach lane. Index 0 is nearest the lock gate.
// Small ships use one cell; large ships use a head/tail pair.
module ca_lane_v5 #(
    parameter integer LANE_CELLS = 12
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_sim,
    input  wire        spawn_req,
    input  wire        spawn_large,
    input  wire        pop_req,

    output wire [23:0] lane_packed,
    output reg  [4:0]  q_count,
    output reg  [5:0]  q_units,
    output reg  [2:0]  sel_ships,
    output reg  [2:0]  sel_units,
    output reg  [7:0]  sel_types
);
    localparam [1:0] CELL_EMPTY = 2'b00;
    localparam [1:0] CELL_SMALL = 2'b01;
    localparam [1:0] CELL_LHEAD = 2'b10;
    localparam [1:0] CELL_LTAIL = 2'b11;

    localparam [1:0] SHIP_NONE  = 2'b00;
    localparam [1:0] SHIP_SMALL = 2'b01;
    localparam [1:0] SHIP_LARGE = 2'b10;

    reg [1:0] lane [0:LANE_CELLS-1];
    reg [LANE_CELLS-1:0] sel_mask;

    // Registered selector for the next chamber batch.
    reg        scan_active;
    reg [4:0]  scan_idx;
    reg [2:0]  scan_cap;
    reg [2:0]  scan_ships;
    reg [2:0]  scan_units;
    reg [7:0]  scan_types;
    reg [LANE_CELLS-1:0] scan_mask;

    reg move_phase;

    genvar gi;
    generate
        for (gi = 0; gi < LANE_CELLS; gi = gi + 1) begin : PACK
            assign lane_packed[gi*2 +: 2] = lane[gi];
        end
    endgenerate

    wire spawn_space_small =
        (lane[LANE_CELLS-1] == CELL_EMPTY) &&
        (lane[LANE_CELLS-2] == CELL_EMPTY);

    wire spawn_space_large =
        (lane[LANE_CELLS-1] == CELL_EMPTY) &&
        (lane[LANE_CELLS-2] == CELL_EMPTY) &&
        (lane[LANE_CELLS-3] == CELL_EMPTY);

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LANE_CELLS; i = i + 1)
                lane[i] <= CELL_EMPTY;
            q_count <= 0;
            q_units <= 0;
            move_phase <= 1'b0;
        end else begin
            // Admission pop has priority over movement/spawn.
            if (pop_req) begin
                for (i = 0; i < LANE_CELLS; i = i + 1)
                    if (sel_mask[i]) lane[i] <= CELL_EMPTY;
                q_count <= q_count - sel_ships;
                q_units <= q_units - sel_units;
            end else if (tick_sim) begin
                move_phase <= ~move_phase;

                // 5 Hz visible CA motion. All decisions use pre-edge state, so
                // each vessel moves by at most one cell per update.
                if (move_phase) begin
                    for (i = 1; i < LANE_CELLS; i = i + 1) begin
                        if ((lane[i] == CELL_SMALL) &&
                            (lane[i-1] == CELL_EMPTY) &&
                            ((i == 1) || (lane[i-2] == CELL_EMPTY))) begin
                            lane[i-1] <= CELL_SMALL;
                            lane[i]   <= CELL_EMPTY;
                        end

                        if (i < LANE_CELLS-1) begin
                            if ((lane[i] == CELL_LHEAD) &&
                                (lane[i+1] == CELL_LTAIL) &&
                                (lane[i-1] == CELL_EMPTY) &&
                                ((i == 1) || (lane[i-2] == CELL_EMPTY))) begin
                                lane[i-1] <= CELL_LHEAD;
                                lane[i]   <= CELL_LTAIL;
                                lane[i+1] <= CELL_EMPTY;
                            end
                        end
                    end

                    // Keep one empty separator cell at the lane entrance.
                    if (spawn_req) begin
                        if (spawn_large && spawn_space_large) begin
                            lane[LANE_CELLS-2] <= CELL_LHEAD;
                            lane[LANE_CELLS-1] <= CELL_LTAIL;
                            q_count <= q_count + 1'b1;
                            q_units <= q_units + 2;
                        end else if (!spawn_large && spawn_space_small) begin
                            lane[LANE_CELLS-1] <= CELL_SMALL;
                            q_count <= q_count + 1'b1;
                            q_units <= q_units + 1'b1;
                        end
                    end
                end
            end
        end
    end

    // Select up to four capacity units from the gate end.
    always @(posedge clk) begin
        if (rst) begin
            sel_ships <= 0;
            sel_units <= 0;
            sel_types <= 0;
            sel_mask <= {LANE_CELLS{1'b0}};
            scan_active <= 1'b0;
            scan_idx <= 0;
            scan_cap <= 4;
            scan_ships <= 0;
            scan_units <= 0;
            scan_types <= 0;
            scan_mask <= {LANE_CELLS{1'b0}};
        end else begin
            if (tick_sim || pop_req) begin
                scan_active <= 1'b1;
                scan_idx <= 0;
                scan_cap <= 4;
                scan_ships <= 0;
                scan_units <= 0;
                scan_types <= 0;
                scan_mask <= {LANE_CELLS{1'b0}};
            end else if (scan_active) begin
                if (scan_idx < LANE_CELLS) begin
                    if ((lane[scan_idx] == CELL_SMALL) && (scan_cap >= 1)) begin
                        scan_mask[scan_idx] <= 1'b1;
                        case (scan_ships)
                            0: scan_types[1:0] <= SHIP_SMALL;
                            1: scan_types[3:2] <= SHIP_SMALL;
                            2: scan_types[5:4] <= SHIP_SMALL;
                            default: scan_types[7:6] <= SHIP_SMALL;
                        endcase
                        scan_ships <= scan_ships + 1'b1;
                        scan_units <= scan_units + 1'b1;
                        scan_cap <= scan_cap - 1'b1;
                    end else if ((lane[scan_idx] == CELL_LHEAD) &&
                                 (scan_idx < LANE_CELLS-1) &&
                                 (lane[scan_idx+1] == CELL_LTAIL) &&
                                 (scan_cap >= 2)) begin
                        scan_mask[scan_idx] <= 1'b1;
                        scan_mask[scan_idx+1] <= 1'b1;
                        case (scan_ships)
                            0: scan_types[1:0] <= SHIP_LARGE;
                            1: scan_types[3:2] <= SHIP_LARGE;
                            2: scan_types[5:4] <= SHIP_LARGE;
                            default: scan_types[7:6] <= SHIP_LARGE;
                        endcase
                        scan_ships <= scan_ships + 1'b1;
                        scan_units <= scan_units + 2;
                        scan_cap <= scan_cap - 2;
                    end
                    scan_idx <= scan_idx + 1'b1;
                end else begin
                    sel_ships <= scan_ships;
                    sel_units <= scan_units;
                    sel_types <= scan_types;
                    sel_mask <= scan_mask;
                    scan_active <= 1'b0;
                end
            end
        end
    end
endmodule
