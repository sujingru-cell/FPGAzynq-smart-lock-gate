`timescale 1ns/1ps

// Gate and vessel animation for the selected batch.
module animation_v5(
    input  wire        clk,
    input  wire        rst,
    input  wire        tick_anim,
    input  wire        start,
    input  wire [3:0]  event_code,
    input  wire [2:0]  ship_count_in,
    input  wire [7:0]  ship_types_in,
    input  wire        dir_up_in,

    output reg         busy,
    output reg         done,
    output reg  [3:0]  event_active,
    output reg  [2:0]  ship_count,
    output reg  [7:0]  ship_types,
    output reg         dir_up,
    output reg  [9:0]  batch_x,
    output reg  [5:0]  gate1_lift,
    output reg  [5:0]  gate2_lift,
    output reg  [5:0]  gate3_lift,
    output reg  [1:0]  phase
);
    localparam [3:0] EV_NONE        = 4'd0;
    localparam [3:0] EV_LOAD_CH1_DN = 4'd1;
    localparam [3:0] EV_CH1_CH2_DN  = 4'd2;
    localparam [3:0] EV_EXIT_DN     = 4'd3;
    localparam [3:0] EV_LOAD_CH2_UP = 4'd4;
    localparam [3:0] EV_CH2_CH1_UP  = 4'd5;
    localparam [3:0] EV_EXIT_UP     = 4'd6;

    localparam [1:0] PH_OPEN  = 2'd0;
    localparam [1:0] PH_MOVE  = 2'd1;
    localparam [1:0] PH_CLOSE = 2'd2;

    reg [9:0] target_x;
    reg       move_right;
    reg [2:0] step_px;
    reg [1:0] gate_id;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
            event_active <= EV_NONE;
            ship_count <= 0;
            ship_types <= 0;
            dir_up <= 1'b0;
            batch_x <= 0;
            target_x <= 0;
            gate1_lift <= 0;
            gate2_lift <= 0;
            gate3_lift <= 0;
            phase <= PH_OPEN;
            move_right <= 1'b1;
            step_px <= 2;
            gate_id <= 0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy <= 1'b1;
                event_active <= event_code;
                ship_count <= ship_count_in;
                ship_types <= ship_types_in;
                dir_up <= dir_up_in;
                phase <= PH_OPEN;
                gate1_lift <= 0;
                gate2_lift <= 0;
                gate3_lift <= 0;

                case (event_code)
                    EV_LOAD_CH1_DN: begin batch_x <= 10'd86;  target_x <= 10'd190; move_right <= 1'b1; step_px <= 3'd2; gate_id <= 1; end
                    EV_CH1_CH2_DN:  begin batch_x <= 10'd190; target_x <= 10'd350; move_right <= 1'b1; step_px <= 3'd2; gate_id <= 2; end
                    EV_EXIT_DN:     begin batch_x <= 10'd350; target_x <= 10'd520; move_right <= 1'b1; step_px <= 3'd2; gate_id <= 3; end
                    EV_LOAD_CH2_UP: begin batch_x <= 10'd520; target_x <= 10'd350; move_right <= 1'b0; step_px <= 3'd2; gate_id <= 3; end
                    EV_CH2_CH1_UP:  begin batch_x <= 10'd350; target_x <= 10'd190; move_right <= 1'b0; step_px <= 3'd2; gate_id <= 2; end
                    EV_EXIT_UP:     begin batch_x <= 10'd190; target_x <= 10'd86;  move_right <= 1'b0; step_px <= 3'd2; gate_id <= 1; end
                    default:        begin batch_x <= 10'd190; target_x <= 10'd190; move_right <= 1'b1; step_px <= 3'd2; gate_id <= 0; end
                endcase
            end

            if (busy && tick_anim) begin
                case (phase)
                    PH_OPEN: begin
                        case (gate_id)
                            1: begin
                                if (gate1_lift < 6'd50) gate1_lift <= gate1_lift + 1'b1;
                                else phase <= PH_MOVE;
                            end
                            2: begin
                                if (gate2_lift < 6'd50) gate2_lift <= gate2_lift + 1'b1;
                                else phase <= PH_MOVE;
                            end
                            3: begin
                                if (gate3_lift < 6'd50) gate3_lift <= gate3_lift + 1'b1;
                                else phase <= PH_MOVE;
                            end
                            default: phase <= PH_MOVE;
                        endcase
                    end

                    PH_MOVE: begin
                        if (move_right) begin
                            if (batch_x + step_px >= target_x) begin
                                batch_x <= target_x;
                                phase <= PH_CLOSE;
                            end else begin
                                batch_x <= batch_x + step_px;
                            end
                        end else begin
                            if (batch_x <= target_x + step_px) begin
                                batch_x <= target_x;
                                phase <= PH_CLOSE;
                            end else begin
                                batch_x <= batch_x - step_px;
                            end
                        end
                    end

                    PH_CLOSE: begin
                        case (gate_id)
                            1: begin
                                if (gate1_lift != 0) gate1_lift <= gate1_lift - 1'b1;
                                else begin busy <= 1'b0; done <= 1'b1; event_active <= EV_NONE; end
                            end
                            2: begin
                                if (gate2_lift != 0) gate2_lift <= gate2_lift - 1'b1;
                                else begin busy <= 1'b0; done <= 1'b1; event_active <= EV_NONE; end
                            end
                            3: begin
                                if (gate3_lift != 0) gate3_lift <= gate3_lift - 1'b1;
                                else begin busy <= 1'b0; done <= 1'b1; event_active <= EV_NONE; end
                            end
                            default: begin busy <= 1'b0; done <= 1'b1; event_active <= EV_NONE; end
                        endcase
                    end
                    default: phase <= PH_OPEN;
                endcase
            end
        end
    end
endmodule
