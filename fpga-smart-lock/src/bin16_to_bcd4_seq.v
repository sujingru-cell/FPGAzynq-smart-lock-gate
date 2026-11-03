`timescale 1ns/1ps

module bin16_to_bcd4_seq(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] binary,
    output reg  [15:0] bcd,
    output reg         busy,
    output reg         done
);
    reg [31:0] shift;
    reg [4:0] count;
    reg [31:0] adjusted;
    reg [31:0] shifted_next;

    always @* begin
        adjusted = shift;
        if (adjusted[19:16] >= 5) adjusted[19:16] = adjusted[19:16] + 3;
        if (adjusted[23:20] >= 5) adjusted[23:20] = adjusted[23:20] + 3;
        if (adjusted[27:24] >= 5) adjusted[27:24] = adjusted[27:24] + 3;
        if (adjusted[31:28] >= 5) adjusted[31:28] = adjusted[31:28] + 3;
        shifted_next = adjusted << 1;
    end

    always @(posedge clk) begin
        if (rst) begin
            shift <= 0;
            count <= 0;
            bcd   <= 0;
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                shift <= {16'b0, binary};
                count <= 0;
                busy  <= 1'b1;
            end else if (busy) begin
                shift <= shifted_next;
                if (count == 5'd15) begin
                    bcd  <= shifted_next[31:16];
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule
