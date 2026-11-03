`timescale 1ns/1ps

module font5x7(
    input  wire [7:0] ch,
    input  wire [2:0] row,
    output reg  [4:0] bits
);
    always @* begin
        bits = 5'b00000;
        case (ch)
            8'h20: bits = 5'b00000; // space
            8'h2D: begin case(row) 3:bits=5'b11111; default:bits=0; endcase end // -
            8'h2F: begin case(row) 0:bits=5'b00001;1:bits=5'b00010;2:bits=5'b00100;3:bits=5'b01000;4:bits=5'b10000;default:bits=0;endcase end // /
            8'h3A: begin case(row) 1:bits=5'b00100;5:bits=5'b00100;default:bits=0;endcase end // :
            8'h25: begin case(row) 0:bits=5'b11001;1:bits=5'b11010;2:bits=5'b00100;3:bits=5'b01000;4:bits=5'b10110;5:bits=5'b00110;default:bits=0;endcase end // %
            8'h30: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10011;3:bits=5'b10101;4:bits=5'b11001;5:bits=5'b10001;6:bits=5'b01110;endcase end
            8'h31: begin case(row)0:bits=5'b00100;1:bits=5'b01100;2:bits=5'b00100;3:bits=5'b00100;4:bits=5'b00100;5:bits=5'b00100;6:bits=5'b01110;endcase end
            8'h32: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b00001;3:bits=5'b00010;4:bits=5'b00100;5:bits=5'b01000;6:bits=5'b11111;endcase end
            8'h33: begin case(row)0:bits=5'b11110;1:bits=5'b00001;2:bits=5'b00001;3:bits=5'b01110;4:bits=5'b00001;5:bits=5'b00001;6:bits=5'b11110;endcase end
            8'h34: begin case(row)0:bits=5'b00010;1:bits=5'b00110;2:bits=5'b01010;3:bits=5'b10010;4:bits=5'b11111;5:bits=5'b00010;6:bits=5'b00010;endcase end
            8'h35: begin case(row)0:bits=5'b11111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b00001;5:bits=5'b00001;6:bits=5'b11110;endcase end
            8'h36: begin case(row)0:bits=5'b01110;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;endcase end
            8'h37: begin case(row)0:bits=5'b11111;1:bits=5'b00001;2:bits=5'b00010;3:bits=5'b00100;4:bits=5'b01000;5:bits=5'b01000;6:bits=5'b01000;endcase end
            8'h38: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b01110;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;endcase end
            8'h39: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b01111;4:bits=5'b00001;5:bits=5'b00001;6:bits=5'b01110;endcase end
            8'h41: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11111;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;endcase end // A
            8'h42: begin case(row)0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11110;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b11110;endcase end
            8'h43: begin case(row)0:bits=5'b01111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b10000;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b01111;endcase end
            8'h44: begin case(row)0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b11110;endcase end
            8'h45: begin case(row)0:bits=5'b11111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b11111;endcase end
            8'h46: begin case(row)0:bits=5'b11111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b11110;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b10000;endcase end
            8'h47: begin case(row)0:bits=5'b01111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b10111;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01111;endcase end
            8'h48: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11111;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;endcase end
            8'h49: begin case(row)0:bits=5'b01110;1:bits=5'b00100;2:bits=5'b00100;3:bits=5'b00100;4:bits=5'b00100;5:bits=5'b00100;6:bits=5'b01110;endcase end
            8'h4A: begin case(row)0:bits=5'b00111;1:bits=5'b00010;2:bits=5'b00010;3:bits=5'b00010;4:bits=5'b10010;5:bits=5'b10010;6:bits=5'b01100;endcase end
            8'h4B: begin case(row)0:bits=5'b10001;1:bits=5'b10010;2:bits=5'b10100;3:bits=5'b11000;4:bits=5'b10100;5:bits=5'b10010;6:bits=5'b10001;endcase end
            8'h4C: begin case(row)0:bits=5'b10000;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b10000;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b11111;endcase end
            8'h4D: begin case(row)0:bits=5'b10001;1:bits=5'b11011;2:bits=5'b10101;3:bits=5'b10101;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;endcase end
            8'h4E: begin case(row)0:bits=5'b10001;1:bits=5'b11001;2:bits=5'b10101;3:bits=5'b10011;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b10001;endcase end
            8'h4F: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;endcase end
            8'h50: begin case(row)0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11110;4:bits=5'b10000;5:bits=5'b10000;6:bits=5'b10000;endcase end
            8'h51: begin case(row)0:bits=5'b01110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10101;5:bits=5'b10010;6:bits=5'b01101;endcase end
            8'h52: begin case(row)0:bits=5'b11110;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b11110;4:bits=5'b10100;5:bits=5'b10010;6:bits=5'b10001;endcase end
            8'h53: begin case(row)0:bits=5'b01111;1:bits=5'b10000;2:bits=5'b10000;3:bits=5'b01110;4:bits=5'b00001;5:bits=5'b00001;6:bits=5'b11110;endcase end
            8'h54: begin case(row)0:bits=5'b11111;1:bits=5'b00100;2:bits=5'b00100;3:bits=5'b00100;4:bits=5'b00100;5:bits=5'b00100;6:bits=5'b00100;endcase end
            8'h55: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b10001;6:bits=5'b01110;endcase end
            8'h56: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10001;4:bits=5'b10001;5:bits=5'b01010;6:bits=5'b00100;endcase end
            8'h57: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b10001;3:bits=5'b10101;4:bits=5'b10101;5:bits=5'b11011;6:bits=5'b10001;endcase end
            8'h58: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b01010;3:bits=5'b00100;4:bits=5'b01010;5:bits=5'b10001;6:bits=5'b10001;endcase end
            8'h59: begin case(row)0:bits=5'b10001;1:bits=5'b10001;2:bits=5'b01010;3:bits=5'b00100;4:bits=5'b00100;5:bits=5'b00100;6:bits=5'b00100;endcase end
            8'h5A: begin case(row)0:bits=5'b11111;1:bits=5'b00001;2:bits=5'b00010;3:bits=5'b00100;4:bits=5'b01000;5:bits=5'b10000;6:bits=5'b11111;endcase end
            default: bits = 5'b00000;
        endcase
    end
endmodule
