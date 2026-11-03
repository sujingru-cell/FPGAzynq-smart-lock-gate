`timescale 1ns/1ps
// Auxiliary VGA pages: policy comparison and AUTO trend history.
module vga_aux_pages_v5p(
    input wire [9:0] x,
    input wire [9:0] y,
    input wire active,
    input wire [1:0] page,

    input wire [15:0] e_pass_bcd, e_wait_bcd, e_fresh_bcd, e_load_bcd, e_cong_bcd,
    input wire [15:0] s_pass_bcd, s_wait_bcd, s_fresh_bcd, s_load_bcd, s_cong_bcd,
    input wire [15:0] a_pass_bcd, a_wait_bcd, a_fresh_bcd, a_load_bcd, a_cong_bcd,
    input wire [15:0] e_wait_raw, s_wait_raw, a_wait_raw,
    input wire [15:0] e_fresh_raw, s_fresh_raw, a_fresh_raw,
    input wire a_policy_eff,

    input wire [6:0] hist_queue,
    input wire [6:0] hist_fresh,
    input wire hist_policy,
    input wire [6:0] hist_prev_queue,
    input wire [6:0] hist_prev_fresh,
    input wire hist_prev_policy,

    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b
);
    function [7:0] digit_char;
        input [3:0] d;
        begin digit_char = 8'h30 + d; end
    endfunction

    function [7:0] bcd3_char;
        input [15:0] bcd;
        input [1:0] p;
        begin
            case(p)
                0: bcd3_char = digit_char(bcd[11:8]);
                1: bcd3_char = digit_char(bcd[7:4]);
                default: bcd3_char = digit_char(bcd[3:0]);
            endcase
        end
    endfunction

    // Metric text used in each strategy card.
    function [7:0] metric_char;
        input [3:0] col;
        input [2:0] metric;
        input [15:0] bcd;
        begin
            metric_char = " ";
            case(metric)
                0: case(col) 0:metric_char="P";1:metric_char="A";2:metric_char="S";3:metric_char="S";4:metric_char=":";
                              6:metric_char=bcd3_char(bcd,0);7:metric_char=bcd3_char(bcd,1);8:metric_char=bcd3_char(bcd,2); default:metric_char=" "; endcase
                1: case(col) 0:metric_char="W";1:metric_char="A";2:metric_char="I";3:metric_char="T";4:metric_char=":";
                              6:metric_char=bcd3_char(bcd,0);7:metric_char=bcd3_char(bcd,1);8:metric_char=bcd3_char(bcd,2); default:metric_char=" "; endcase
                2: case(col) 0:metric_char="L";1:metric_char="O";2:metric_char="A";3:metric_char="D";4:metric_char=":";
                              6:metric_char=bcd3_char(bcd,0);7:metric_char=bcd3_char(bcd,1);8:metric_char=bcd3_char(bcd,2);9:metric_char="%"; default:metric_char=" "; endcase
                3: case(col) 0:metric_char="F";1:metric_char="R";2:metric_char="E";3:metric_char="S";4:metric_char="H";5:metric_char=":";
                              6:metric_char=bcd3_char(bcd,0);7:metric_char=bcd3_char(bcd,1);8:metric_char=bcd3_char(bcd,2); default:metric_char=" "; endcase
                default: case(col) 0:metric_char="C";1:metric_char="O";2:metric_char="N";3:metric_char="G";4:metric_char=":";
                              6:metric_char=bcd3_char(bcd,0);7:metric_char=bcd3_char(bcd,1);8:metric_char=bcd3_char(bcd,2);9:metric_char="%"; default:metric_char=" "; endcase
            endcase
        end
    endfunction

    function [7:0] text_char_at;
        input [4:0] tr;
        input [5:0] tc;
        reg [3:0] lc;
        reg [2:0] mr;
        begin
            text_char_at = " ";
            if (page == 2'd1) begin
                case(tr)
                    0: case(tc)
                        3:text_char_at="P";4:text_char_at="A";5:text_char_at="R";6:text_char_at="A";7:text_char_at="L";8:text_char_at="L";9:text_char_at="E";10:text_char_at="L";
                        12:text_char_at="S";13:text_char_at="T";14:text_char_at="R";15:text_char_at="A";16:text_char_at="T";17:text_char_at="E";18:text_char_at="G";19:text_char_at="Y";
                        21:text_char_at="C";22:text_char_at="O";23:text_char_at="M";24:text_char_at="P";25:text_char_at="A";26:text_char_at="R";27:text_char_at="I";28:text_char_at="S";29:text_char_at="O";30:text_char_at="N";
                        default:text_char_at=" "; endcase
                    1: case(tc)
                        11:text_char_at="S";12:text_char_at="A";13:text_char_at="M";14:text_char_at="E";16:text_char_at="I";17:text_char_at="N";18:text_char_at="P";19:text_char_at="U";20:text_char_at="T";
                        22:text_char_at="S";23:text_char_at="T";24:text_char_at="R";25:text_char_at="E";26:text_char_at="A";27:text_char_at="M";
                        default:text_char_at=" "; endcase
                    3: begin
                        if (tc>=4 && tc<=6) case(tc)4:text_char_at="E";5:text_char_at="F";6:text_char_at="F";endcase
                        else if (tc>=17 && tc<=20) case(tc)17:text_char_at="S";18:text_char_at="A";19:text_char_at="V";20:text_char_at="E";endcase
                        else if (tc>=30 && tc<=33) case(tc)30:text_char_at="A";31:text_char_at="U";32:text_char_at="T";33:text_char_at="O";endcase
                    end
                    5,6,7,8,9: begin
                        mr = tr-5;
                        if (tc>=1 && tc<=10) begin
                            lc=tc-1;
                            case(mr)0:text_char_at=metric_char(lc,mr,e_pass_bcd);1:text_char_at=metric_char(lc,mr,e_wait_bcd);2:text_char_at=metric_char(lc,mr,e_load_bcd);3:text_char_at=metric_char(lc,mr,e_fresh_bcd);default:text_char_at=metric_char(lc,mr,e_cong_bcd);endcase
                        end else if (tc>=14 && tc<=23) begin
                            lc=tc-14;
                            case(mr)0:text_char_at=metric_char(lc,mr,s_pass_bcd);1:text_char_at=metric_char(lc,mr,s_wait_bcd);2:text_char_at=metric_char(lc,mr,s_load_bcd);3:text_char_at=metric_char(lc,mr,s_fresh_bcd);default:text_char_at=metric_char(lc,mr,s_cong_bcd);endcase
                        end else if (tc>=27 && tc<=36) begin
                            lc=tc-27;
                            case(mr)0:text_char_at=metric_char(lc,mr,a_pass_bcd);1:text_char_at=metric_char(lc,mr,a_wait_bcd);2:text_char_at=metric_char(lc,mr,a_load_bcd);3:text_char_at=metric_char(lc,mr,a_fresh_bcd);default:text_char_at=metric_char(lc,mr,a_cong_bcd);endcase
                        end
                    end
                    16: case(tc) 1:text_char_at="A";2:text_char_at="V";3:text_char_at="G";5:text_char_at="W";6:text_char_at="A";7:text_char_at="I";8:text_char_at="T";
                                      10:text_char_at="-";12:text_char_at="L";13:text_char_at="O";14:text_char_at="W";15:text_char_at="E";16:text_char_at="R";
                                      18:text_char_at="I";19:text_char_at="S";21:text_char_at="B";22:text_char_at="E";23:text_char_at="T";24:text_char_at="T";25:text_char_at="E";26:text_char_at="R"; default:text_char_at=" "; endcase
                    17: case(tc)1:text_char_at="E";2:text_char_at="F";3:text_char_at="F";default:text_char_at=" ";endcase
                    19: case(tc)1:text_char_at="S";2:text_char_at="A";3:text_char_at="V";4:text_char_at="E";default:text_char_at=" ";endcase
                    21: case(tc)1:text_char_at="A";2:text_char_at="U";3:text_char_at="T";4:text_char_at="O";default:text_char_at=" ";endcase
                    23: case(tc)1:text_char_at="F";2:text_char_at="R";3:text_char_at="E";4:text_char_at="S";5:text_char_at="H";7:text_char_at="/";9:text_char_at="S";10:text_char_at="H";11:text_char_at="I";12:text_char_at="P";
                                      14:text_char_at="-";16:text_char_at="L";17:text_char_at="O";18:text_char_at="W";19:text_char_at="E";20:text_char_at="R";
                                      22:text_char_at="I";23:text_char_at="S";25:text_char_at="B";26:text_char_at="E";27:text_char_at="T";28:text_char_at="T";29:text_char_at="E";30:text_char_at="R"; default:text_char_at=" "; endcase
                    24: case(tc)1:text_char_at="E";2:text_char_at="F";3:text_char_at="F";default:text_char_at=" ";endcase
                    26: case(tc)1:text_char_at="S";2:text_char_at="A";3:text_char_at="V";4:text_char_at="E";default:text_char_at=" ";endcase
                    28: case(tc)1:text_char_at="A";2:text_char_at="U";3:text_char_at="T";4:text_char_at="O";default:text_char_at=" ";endcase
                    default: text_char_at=" ";
                endcase
            end else if (page == 2'd2) begin
                case(tr)
                    0: case(tc)
                        4:text_char_at="A";5:text_char_at="U";6:text_char_at="T";7:text_char_at="O";
                        9:text_char_at="A";10:text_char_at="D";11:text_char_at="A";12:text_char_at="P";13:text_char_at="T";14:text_char_at="I";15:text_char_at="V";16:text_char_at="E";
                        18:text_char_at="T";19:text_char_at="R";20:text_char_at="E";21:text_char_at="N";22:text_char_at="D";
                        24:text_char_at="-";26:text_char_at="3";27:text_char_at="2";29:text_char_at="S";30:text_char_at="E";31:text_char_at="C";
                        default:text_char_at=" "; endcase
                    2: case(tc) 6:text_char_at="Q";7:text_char_at="U";8:text_char_at="E";9:text_char_at="U";10:text_char_at="E";12:text_char_at="P";13:text_char_at="R";14:text_char_at="E";15:text_char_at="S";16:text_char_at="S";17:text_char_at="U";18:text_char_at="R";19:text_char_at="E"; default:text_char_at=" "; endcase
                    14: case(tc) 6:text_char_at="F";7:text_char_at="R";8:text_char_at="E";9:text_char_at="S";10:text_char_at="H";12:text_char_at="W";13:text_char_at="A";14:text_char_at="T";15:text_char_at="E";16:text_char_at="R";18:text_char_at="/";20:text_char_at="S";21:text_char_at="H";22:text_char_at="I";23:text_char_at="P"; default:text_char_at=" "; endcase
                    25: case(tc) 6:text_char_at="A";7:text_char_at="U";8:text_char_at="T";9:text_char_at="O";11:text_char_at="P";12:text_char_at="O";13:text_char_at="L";14:text_char_at="I";15:text_char_at="C";16:text_char_at="Y";
                                      19:text_char_at="C";20:text_char_at="Y";21:text_char_at="A";22:text_char_at="N";23:text_char_at="=";24:text_char_at="S";25:text_char_at="A";26:text_char_at="V";27:text_char_at="E";
                                      30:text_char_at="O";31:text_char_at="R";32:text_char_at="A";33:text_char_at="N";34:text_char_at="G";35:text_char_at="E";36:text_char_at="=";37:text_char_at="E";38:text_char_at="F";39:text_char_at="F"; default:text_char_at=" "; endcase
                    28: begin
                        case(tc) 10:text_char_at="C";11:text_char_at="U";12:text_char_at="R";13:text_char_at="R";14:text_char_at="E";15:text_char_at="N";16:text_char_at="T";17:text_char_at=":";
                            19:text_char_at=a_policy_eff?"E":"S";20:text_char_at=a_policy_eff?"F":"A";21:text_char_at=a_policy_eff?"F":"V";22:text_char_at=a_policy_eff?" ":"E"; default:text_char_at=" "; endcase
                    end
                    default:text_char_at=" ";
                endcase
            end
        end
    endfunction

    wire [4:0] text_row = y[8:4];
    wire [5:0] text_col = x[9:4];
    wire [2:0] glyph_x = x[3:1];
    wire [2:0] glyph_y = y[3:1];
    wire [7:0] text_char = text_char_at(text_row,text_col);
    wire [4:0] font_bits;
    font5x7 u_font(.ch(text_char),
        .row(glyph_y),
        .bits(font_bits));
    wire text_on = (glyph_x < 5) && (glyph_y < 7) && font_bits[4-glyph_x];

    function integer bar_width;
        input [15:0] v;
        begin
            if (v >= 80) bar_width = 320;
            else bar_width = v << 2;
        end
    endfunction

    integer ew,sw,aw,ef,sf,af;
    integer qy,qpy,fy,fpy;
    reg between_q, between_f;

    always @* begin
        r=0; g=0; b=0;
        ew=bar_width(e_wait_raw); sw=bar_width(s_wait_raw); aw=bar_width(a_wait_raw);
        ef=bar_width(e_fresh_raw); sf=bar_width(s_fresh_raw); af=bar_width(a_fresh_raw);
        qy = 190 - hist_queue;
        qpy = 190 - hist_prev_queue;
        fy = 360 - hist_fresh;
        fpy = 360 - hist_prev_fresh;
        between_q = ((y>=qy)&&(y<=qpy)) || ((y>=qpy)&&(y<=qy));
        between_f = ((y>=fy)&&(y<=fpy)) || ((y>=fpy)&&(y<=fy));

        if (active) begin
            r=0; g=0; b=0;
            if (page == 2'd1) begin
                // Three strategy cards.
                if (((x>=16)&&(x<=208)&&(y>=48)&&(y<=232)) ||
                    ((x>=224)&&(x<=416)&&(y>=48)&&(y<=232)) ||
                    ((x>=432)&&(x<=624)&&(y>=48)&&(y<=232))) begin
                    if ((x==16)||(x==208)||(x==224)||(x==416)||(x==432)||(x==624)||(y==48)||(y==232)) begin r=0;g=10;b=12; end
                end
                // WAIT bars: EFF yellow, SAVE cyan, AUTO green.
                if ((y>=288)&&(y<298)&&(x>=144)&&(x<144+ew)) begin r=15;g=11;b=0; end
                if ((y>=320)&&(y<330)&&(x>=144)&&(x<144+sw)) begin r=0;g=15;b=15; end
                if ((y>=352)&&(y<362)&&(x>=144)&&(x<144+aw)) begin r=0;g=15;b=6; end
                // FRESH/SHIP bars.
                if ((y>=400)&&(y<410)&&(x>=144)&&(x<144+ef)) begin r=15;g=11;b=0; end
                if ((y>=432)&&(y<442)&&(x>=144)&&(x<144+sf)) begin r=0;g=15;b=15; end
                if ((y>=464)&&(y<474)&&(x>=144)&&(x<144+af)) begin r=0;g=15;b=6; end
            end else if (page == 2'd2) begin
                // Trend graph frames.
                if (((x==96)||(x==608)||(y==70)||(y==200)) && (x>=96)&&(x<=608)&&(y>=70)&&(y<=200)) begin r=6;g=8;b=9; end
                if (((x==96)||(x==608)||(y==240)||(y==370)) && (x>=96)&&(x<=608)&&(y>=240)&&(y<=370)) begin r=6;g=8;b=9; end

                // Queue step plot.
                if ((x>=96)&&(x<608)&&(y>=70)&&(y<=200)) begin
                    if ((y>=qy-1)&&(y<=qy+1)) begin r=0;g=15;b=15; end
                    if (((x-96)&10'h00F)<2 && between_q) begin r=0;g=15;b=15; end
                end
                // Fresh-water/ship step plot.
                if ((x>=96)&&(x<608)&&(y>=240)&&(y<=370)) begin
                    if ((y>=fy-1)&&(y<=fy+1)) begin r=15;g=12;b=0; end
                    if (((x-96)&10'h00F)<2 && between_f) begin r=15;g=12;b=0; end
                end
                // Policy timeline: cyan=SAVE, orange=EFF.
                if ((x>=96)&&(x<608)&&(y>=410)&&(y<442)) begin
                    if (hist_policy) begin r=15;g=7;b=0; end
                    else begin r=0;g=13;b=13; end
                end
                if ((x>=96)&&(x<=608) && ((y==409)||(y==442))) begin r=6;g=8;b=9; end
            end

            if (text_on) begin
                if (page==2'd1 && text_row==0) begin r=0;g=15;b=15; end
                else if (page==2'd2 && text_row==0) begin r=0;g=15;b=15; end
                else begin r=15;g=15;b=15; end
            end
        end
    end
endmodule
