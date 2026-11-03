`timescale 1ns/1ps

module u32_div_u16(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [31:0] dividend,
    input  wire [15:0] divisor,
    output reg  [31:0] quotient,
    output reg         busy,
    output reg         done
);
    reg [31:0] dividend_shift;
    reg [31:0] quotient_work;
    reg [16:0] remainder;
    reg [15:0] divisor_r;
    reg [5:0]  count;

    reg [16:0] rem_shift;
    reg [16:0] rem_next;
    reg        qbit;
    reg [31:0] quot_next;

    always @* begin
        rem_shift = {remainder[15:0], dividend_shift[31]};
        if (rem_shift >= {1'b0, divisor_r}) begin
            rem_next = rem_shift - {1'b0, divisor_r};
            qbit = 1'b1;
        end else begin
            rem_next = rem_shift;
            qbit = 1'b0;
        end
        quot_next = {quotient_work[30:0], qbit};
    end

    always @(posedge clk) begin
        if (rst) begin
            quotient       <= 0;
            busy           <= 1'b0;
            done           <= 1'b0;
            dividend_shift <= 0;
            quotient_work  <= 0;
            remainder      <= 0;
            divisor_r      <= 0;
            count          <= 0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                if (divisor == 0) begin
                    quotient <= 0;
                    busy     <= 1'b0;
                    done     <= 1'b1;
                end else begin
                    dividend_shift <= dividend;
                    quotient_work  <= 0;
                    remainder      <= 0;
                    divisor_r      <= divisor;
                    count          <= 0;
                    busy           <= 1'b1;
                end
            end else if (busy) begin
                dividend_shift <= {dividend_shift[30:0], 1'b0};
                remainder      <= rem_next;
                quotient_work  <= quot_next;
                if (count == 6'd31) begin
                    quotient <= quot_next;
                    busy     <= 1'b0;
                    done     <= 1'b1;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end
endmodule
