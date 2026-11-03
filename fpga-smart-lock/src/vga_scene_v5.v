`timescale 1ns/1ps

module vga_scene_v5(
    input  wire [9:0]  x,
    input  wire [9:0]  y,
    input  wire        active,
    input  wire [23:0] up_lane,
    input  wire [23:0] dn_lane,
    input  wire [4:0]  up_q_count,
    input  wire [4:0]  dn_q_count,
    input  wire [6:0]  ch1_water,
    input  wire [6:0]  ch2_water,
    input  wire [6:0]  pool_level,
    input  wire [2:0]  up_res_offset,
    input  wire [2:0]  dn_res_offset,
    input  wire [3:0]  flow_code,
    input  wire [5:0]  flow_phase,
    input  wire [1:0]  batch_loc,
    input  wire        batch_dir_up,
    input  wire [2:0]  batch_ships,
    input  wire [7:0]  batch_types,
    input  wire        anim_busy,
    input  wire [3:0]  anim_event,
    input  wire [9:0]  anim_batch_x,
    input  wire [2:0]  anim_ships,
    input  wire [7:0]  anim_types,
    input  wire        anim_dir_up,
    input  wire [5:0]  gate1_lift,
    input  wire [5:0]  gate2_lift,
    input  wire [5:0]  gate3_lift,
    input  wire [1:0]  mode_display,
    input  wire        policy_eff,
    input  wire        core_busy,
    input  wire [7:0]  last_event,
    input  wire [15:0] pass_bcd,
    input  wire [15:0] avg_bcd,
    input  wire [15:0] fresh_bcd,
    input  wire [15:0] save_bcd,
    input  wire [15:0] pool_bcd,
    input  wire [15:0] cong_bcd,
    output reg  [3:0]  r,
    output reg  [3:0]  g,
    output reg  [3:0]  b
);
    localparam [1:0] CELL_EMPTY = 2'b00;
    localparam [1:0] CELL_SMALL = 2'b01;
    localparam [1:0] CELL_LHEAD = 2'b10;

    localparam [1:0] SHIP_SMALL = 2'b01;
    localparam [1:0] SHIP_LARGE = 2'b10;

    localparam [3:0] AN_LOAD_CH1_DN = 4'd1;
    localparam [3:0] AN_CH1_CH2_DN  = 4'd2;
    localparam [3:0] AN_EXIT_DN     = 4'd3;
    localparam [3:0] AN_LOAD_CH2_UP = 4'd4;
    localparam [3:0] AN_CH2_CH1_UP  = 4'd5;
    localparam [3:0] AN_EXIT_UP     = 4'd6;

    localparam integer X_G1 = 160;
    localparam integer X_G2 = 320;
    localparam integer X_G3 = 480;
    localparam integer FLOOR_UP = 305;
    localparam integer FLOOR_C1 = 305;
    localparam integer FLOOR_C2 = 345;
    localparam integer FLOOR_DN = 345;

    function integer water_y;
        input [6:0] level;
        begin
            // 100 -> 160, 50 -> 235, 0 -> 310
            water_y = 310 - level - (level >> 1);
        end
    endfunction

    function integer ship_width;
        input [1:0] kind;
        begin
            ship_width = (kind == SHIP_LARGE) ? 22 : 10;
        end
    endfunction

    function ship_pixel;
        input integer px;
        input integer py;
        input integer bx;
        input integer by;
        input integer bw;
        input integer dir_up_f;
        begin
            ship_pixel = 1'b0;
            if ((px >= bx) && (px < bx+bw) && (py >= by) && (py < by+5))
                ship_pixel = 1'b1;
            else if (!dir_up_f) begin
                if ((px >= bx+2) && (px < bx+7) && (py >= by-3) && (py < by))
                    ship_pixel = 1'b1;
            end else begin
                if ((px >= bx+bw-7) && (px < bx+bw-2) && (py >= by-3) && (py < by))
                    ship_pixel = 1'b1;
            end
        end
    endfunction

    function [7:0] digit_char;
        input [3:0] d;
        begin digit_char = 8'h30 + d; end
    endfunction

    function [7:0] mode_char;
        input [1:0] m;
        input [2:0] p;
        begin
            mode_char = " ";
            case (m)
                2'd0: case(p) 0:mode_char="E";1:mode_char="F";2:mode_char="F";default:mode_char=" "; endcase
                2'd1: case(p) 0:mode_char="S";1:mode_char="A";2:mode_char="V";3:mode_char="E";default:mode_char=" "; endcase
                2'd2: case(p) 0:mode_char="A";1:mode_char="U";2:mode_char="T";3:mode_char="O";default:mode_char=" "; endcase
                default: case(p) 0:mode_char="D";1:mode_char="E";2:mode_char="M";3:mode_char="O";default:mode_char=" "; endcase
            endcase
        end
    endfunction

    function [7:0] event_char;
        input [7:0] ev;
        input [4:0] p;
        begin
            event_char = " ";
            case (ev)
                8'd0:  case(p)0:event_char="I";1:event_char="D";2:event_char="L";3:event_char="E";default:event_char=" ";endcase
                8'd1:  case(p)0:event_char="L";1:event_char="O";2:event_char="A";3:event_char="D";5:event_char="C";6:event_char="H";7:event_char="1";default:event_char=" ";endcase
                8'd2:  case(p)0:event_char="C";1:event_char="H";2:event_char="1";4:event_char="T";5:event_char="O";7:event_char="P";8:event_char="O";9:event_char="O";10:event_char="L";default:event_char=" ";endcase
                8'd3:  case(p)0:event_char="D";1:event_char="R";2:event_char="A";3:event_char="I";4:event_char="N";6:event_char="C";7:event_char="H";8:event_char="1";default:event_char=" ";endcase
                8'd4:  case(p)0:event_char="P";1:event_char="O";2:event_char="O";3:event_char="L";5:event_char="T";6:event_char="O";8:event_char="C";9:event_char="H";10:event_char="2";default:event_char=" ";endcase
                8'd5:  case(p)0:event_char="F";1:event_char="I";2:event_char="L";3:event_char="L";5:event_char="C";6:event_char="H";7:event_char="2";default:event_char=" ";endcase
                8'd6:  case(p)0:event_char="C";1:event_char="H";2:event_char="1";4:event_char="T";5:event_char="O";7:event_char="C";8:event_char="H";9:event_char="2";default:event_char=" ";endcase
                8'd7:  case(p)0:event_char="C";1:event_char="H";2:event_char="2";4:event_char="T";5:event_char="O";7:event_char="P";8:event_char="O";9:event_char="O";10:event_char="L";default:event_char=" ";endcase
                8'd8:  case(p)0:event_char="D";1:event_char="R";2:event_char="A";3:event_char="I";4:event_char="N";6:event_char="C";7:event_char="H";8:event_char="2";default:event_char=" ";endcase
                8'd9:  case(p)0:event_char="D";1:event_char="O";2:event_char="W";3:event_char="N";5:event_char="E";6:event_char="X";7:event_char="I";8:event_char="T";default:event_char=" ";endcase
                8'd10: case(p)0:event_char="F";1:event_char="R";2:event_char="E";3:event_char="S";4:event_char="H";6:event_char="T";7:event_char="O";9:event_char="C";10:event_char="H";11:event_char="1";default:event_char=" ";endcase
                8'd11: case(p)0:event_char="L";1:event_char="O";2:event_char="A";3:event_char="D";5:event_char="C";6:event_char="H";7:event_char="2";default:event_char=" ";endcase
                8'd12: case(p)0:event_char="C";1:event_char="H";2:event_char="2";4:event_char="T";5:event_char="O";7:event_char="C";8:event_char="H";9:event_char="1";default:event_char=" ";endcase
                8'd13: case(p)0:event_char="U";1:event_char="P";3:event_char="E";4:event_char="X";5:event_char="I";6:event_char="T";default:event_char=" ";endcase
                default: case(p)0:event_char="R";1:event_char="U";2:event_char="N";default:event_char=" ";endcase
            endcase
        end
    endfunction

    function [7:0] char_at;
        input [4:0] tr;
        input [5:0] tc;
        begin
            char_at = " ";
            case (tr)
                5'd0: begin
                    case (tc)
                        0:char_at="S";1:char_at="M";2:char_at="A";3:char_at="R";4:char_at="T";
                        6:char_at="L";7:char_at="O";8:char_at="C";9:char_at="K";
                        11:char_at="P";12:char_at="A";13:char_at="R";
                        15:char_at="2";16:char_at="-";17:char_at="S";18:char_at="T";19:char_at="A";20:char_at="G";21:char_at="E";
                        23:char_at="W";24:char_at="A";25:char_at="T";26:char_at="E";27:char_at="R";
                        29:char_at="R";30:char_at="E";31:char_at="U";32:char_at="S";33:char_at="E";
                    endcase
                end
                5'd1: begin
                    case(tc)
                        0:char_at="M";1:char_at="O";2:char_at="D";3:char_at="E";4:char_at=":";
                        5:char_at=mode_char(mode_display,0);6:char_at=mode_char(mode_display,1);7:char_at=mode_char(mode_display,2);8:char_at=mode_char(mode_display,3);
                        11:char_at="P";12:char_at="O";13:char_at="L";14:char_at="I";15:char_at="C";16:char_at="Y";17:char_at=":";
                        18:char_at=policy_eff?"E":"S";19:char_at=policy_eff?"F":"A";20:char_at=policy_eff?"F":"V";21:char_at=policy_eff?" ":"E";
                        24:char_at="D";25:char_at="I";26:char_at="R";27:char_at=":";
                        28:char_at=core_busy?(batch_dir_up?"U":"D"):"-";
                        29:char_at=core_busy?(batch_dir_up?"P":"N"):"-";
                    endcase
                end
                5'd2: begin
                    case(tc)
                        0:char_at="E";1:char_at="V";2:char_at="E";3:char_at="N";4:char_at="T";5:char_at=":";
                        default: if ((tc >= 7) && (tc < 22)) char_at=event_char(last_event,tc-7);
                    endcase
                end
                5'd5: begin
                    case(tc)
                        0:char_at="U";1:char_at="P";2:char_at="S";3:char_at="T";4:char_at="R";5:char_at="E";6:char_at="A";7:char_at="M";
                        11:char_at="C";12:char_at="H";13:char_at="1";
                        21:char_at="C";22:char_at="H";23:char_at="2";
                        31:char_at="D";32:char_at="O";33:char_at="W";34:char_at="N";35:char_at="S";36:char_at="T";
                    endcase
                end
                5'd20: begin
                    case(tc)
                        16:char_at="S";17:char_at="A";18:char_at="V";19:char_at="E";
                        21:char_at="P";22:char_at="O";23:char_at="O";24:char_at="L";
                    endcase
                end
                5'd26: begin
                    case(tc)
                        0:char_at="U";1:char_at="P";2:char_at="Q";3:char_at=":";4:char_at=digit_char({3'b0,up_q_count>=10});
                        5:begin if(up_q_count>=20) char_at=digit_char(up_q_count-20); else if(up_q_count>=10) char_at=digit_char(up_q_count-10); else char_at=digit_char(up_q_count[3:0]); end
                        8:char_at="D";9:char_at="N";10:char_at="Q";11:char_at=":";12:char_at=digit_char({3'b0,dn_q_count>=10});
                        13:begin if(dn_q_count>=20) char_at=digit_char(dn_q_count-20); else if(dn_q_count>=10) char_at=digit_char(dn_q_count-10); else char_at=digit_char(dn_q_count[3:0]); end
                        16:char_at="P";17:char_at="A";18:char_at="S";19:char_at="S";20:char_at=":";
                        21:char_at=digit_char(pass_bcd[15:12]);22:char_at=digit_char(pass_bcd[11:8]);23:char_at=digit_char(pass_bcd[7:4]);24:char_at=digit_char(pass_bcd[3:0]);
                    endcase
                end
                5'd27: begin
                    case(tc)
                        0:char_at="A";1:char_at="V";2:char_at="G";3:char_at=":";
                        4:char_at=digit_char(avg_bcd[15:12]);5:char_at=digit_char(avg_bcd[11:8]);6:char_at=digit_char(avg_bcd[7:4]);7:char_at=digit_char(avg_bcd[3:0]);8:char_at="S";
                        11:char_at="C";12:char_at="O";13:char_at="N";14:char_at="G";15:char_at=":";
                        16:char_at=digit_char(cong_bcd[11:8]);17:char_at=digit_char(cong_bcd[7:4]);18:char_at=digit_char(cong_bcd[3:0]);19:char_at="%";
                        22:char_at="P";23:char_at="O";24:char_at="O";25:char_at="L";26:char_at=":";
                        27:char_at=digit_char(pool_bcd[11:8]);28:char_at=digit_char(pool_bcd[7:4]);29:char_at=digit_char(pool_bcd[3:0]);30:char_at="%";
                    endcase
                end
                5'd28: begin
                    case(tc)
                        0:char_at="F";1:char_at="R";2:char_at="E";3:char_at="S";4:char_at="H";5:char_at="/";6:char_at="S";7:char_at="H";8:char_at="I";9:char_at="P";10:char_at=":";
                        11:char_at=digit_char(fresh_bcd[15:12]);12:char_at=digit_char(fresh_bcd[11:8]);13:char_at=digit_char(fresh_bcd[7:4]);14:char_at=digit_char(fresh_bcd[3:0]);
                        18:char_at="S";19:char_at="A";20:char_at="V";21:char_at="E";22:char_at=":";
                        23:char_at=digit_char(save_bcd[11:8]);24:char_at=digit_char(save_bcd[7:4]);25:char_at=digit_char(save_bcd[3:0]);26:char_at="%";
                    endcase
                end
            endcase
        end
    endfunction

    wire [4:0] text_row = y[8:4];
    wire [5:0] text_col = x[9:4];
    wire [2:0] glyph_x = x[3:1];
    wire [2:0] glyph_y = y[3:1];
    wire [7:0] text_char = char_at(text_row,text_col);
    wire [4:0] font_bits;
    font5x7 u_font(.ch(text_char),
        .row(glyph_y),
        .bits(font_bits));
    wire text_on = (glyph_x < 5) && (glyph_y < 7) && font_bits[4-glyph_x];

    integer surf_up, surf_dn, surf1, surf2, pool_surf;
    integer j;
    integer sx, sy, swid;
    integer batch_off;
    integer anim_surface;
    integer pipe_dot_y;
    integer pool_scaled;
    reg [1:0] kind;
    reg up_ship_hit, dn_ship_hit, static_ship_hit, moving_ship_hit;

    always @* begin
        r = 0; g = 0; b = 0;
        surf_up = 160 + up_res_offset;
        surf_dn = 310 - dn_res_offset;
        surf1 = water_y(ch1_water);
        surf2 = water_y(ch2_water);
        pool_scaled = ({3'b000,pool_level} << 2) +
                      ({3'b000,pool_level} << 1) +
                       {3'b000,pool_level};
        pool_surf = 404 - (pool_scaled >> 4);
        up_ship_hit = 1'b0;
        dn_ship_hit = 1'b0;
        static_ship_hit = 1'b0;
        moving_ship_hit = 1'b0;

        // Approach lanes.
        for (j=0; j<12; j=j+1) begin
            kind = up_lane[j*2 +: 2];
            if (kind == CELL_SMALL) begin
                sx = 145 - j*11 - 7;
                if (ship_pixel(x,y,sx,surf_up-8,7,0)) up_ship_hit = 1'b1;
            end else if (kind == CELL_LHEAD) begin
                sx = 145 - j*11 - 18;
                if (ship_pixel(x,y,sx,surf_up-8,18,0)) up_ship_hit = 1'b1;
            end

            kind = dn_lane[j*2 +: 2];
            if (kind == CELL_SMALL) begin
                sx = 490 + j*11;
                if (ship_pixel(x,y,sx,surf_dn-8,7,1)) dn_ship_hit = 1'b1;
            end else if (kind == CELL_LHEAD) begin
                sx = 490 + j*11;
                if (ship_pixel(x,y,sx,surf_dn-8,18,1)) dn_ship_hit = 1'b1;
            end
        end

        // Batch parked inside a chamber.
        if (!anim_busy && (batch_loc != 0)) begin
            batch_off = 0;
            for (j=0; j<4; j=j+1) begin
                if (j < batch_ships) begin
                    kind = batch_types[j*2 +: 2];
                    swid = ship_width(kind);
                    sx = ((batch_loc == 1) ? 190 : 350) + batch_off;
                    sy = ((batch_loc == 1) ? surf1 : surf2) - 8;
                    if (ship_pixel(x,y,sx,sy,swid,batch_dir_up)) static_ship_hit = 1'b1;
                    batch_off = batch_off + swid + 6;
                end
            end
        end

        // Moving batch follows the current water surface.
        if (anim_busy) begin
            case (anim_event)
                AN_LOAD_CH1_DN: anim_surface = surf_up;
                AN_CH1_CH2_DN:  anim_surface = surf1;
                AN_EXIT_DN:     anim_surface = surf_dn;
                AN_LOAD_CH2_UP: anim_surface = surf_dn;
                AN_CH2_CH1_UP:  anim_surface = surf2;
                AN_EXIT_UP:     anim_surface = surf_up;
                default:        anim_surface = surf1;
            endcase
            batch_off = 0;
            for (j=0; j<4; j=j+1) begin
                if (j < anim_ships) begin
                    kind = anim_types[j*2 +: 2];
                    swid = ship_width(kind);
                    sx = anim_batch_x + batch_off;
                    sy = anim_surface - 8;
                    if (ship_pixel(x,y,sx,sy,swid,anim_dir_up)) moving_ship_hit = 1'b1;
                    batch_off = batch_off + swid + 6;
                end
            end
        end

        if (active) begin
            // Unused pixels stay at RGB 0.
            r = 4'h0; g = 4'h0; b = 4'h0;

            // Water bodies.
            if ((x < X_G1) && (y >= surf_up) && (y < FLOOR_UP)) begin r=0;g=8;b=15; end
            if ((x > X_G1) && (x < X_G2) && (y >= surf1) && (y < FLOOR_C1)) begin r=0;g=8;b=15; end
            if ((x > X_G2) && (x < X_G3) && (y >= surf2) && (y < FLOOR_C2)) begin r=0;g=10;b=14; end
            if ((x > X_G3) && (y >= surf_dn) && (y < FLOOR_DN)) begin r=0;g=9;b=14; end

            // Cyan water-surface lines.
            if ((x < X_G1) && (y >= surf_up) && (y < surf_up+2)) begin r=0;g=15;b=15; end
            if ((x > X_G1) && (x < X_G2) && (y >= surf1) && (y < surf1+2)) begin r=0;g=15;b=15; end
            if ((x > X_G2) && (x < X_G3) && (y >= surf2) && (y < surf2+2)) begin r=0;g=15;b=15; end
            if ((x > X_G3) && (y >= surf_dn) && (y < surf_dn+2)) begin r=0;g=15;b=15; end

            // Solid chamber walls/floors.
            if (((x >= X_G1-2)&&(x <= X_G1+2)&&(y>=95)&&(y<=FLOOR_C1)) ||
                ((x >= X_G2-2)&&(x <= X_G2+2)&&(y>=95)&&(y<=FLOOR_C2)) ||
                ((x >= X_G3-2)&&(x <= X_G3+2)&&(y>=95)&&(y<=FLOOR_DN))) begin r=8;g=8;b=9; end
            if (((y>=FLOOR_C1)&&(y<FLOOR_C1+3)&&(x>=X_G1)&&(x<=X_G2)) ||
                ((y>=FLOOR_C2)&&(y<FLOOR_C2+3)&&(x>=X_G2)&&(x<=X_G3))) begin r=7;g=7;b=8; end

            // Gates: orange segments lift upward smoothly.
            if ((x >= X_G1-5)&&(x <= X_G1+5)&&(y>=100)&&(y <= FLOOR_C1-{gate1_lift,2'b00})) begin r=15;g=8;b=0; end
            if ((x >= X_G2-5)&&(x <= X_G2+5)&&(y>=100)&&(y <= FLOOR_C2-{gate2_lift,2'b00})) begin r=15;g=8;b=0; end
            if ((x >= X_G3-5)&&(x <= X_G3+5)&&(y>=100)&&(y <= FLOOR_DN-{gate3_lift,2'b00})) begin r=15;g=8;b=0; end

            // Saving basin.
            if (((x>=225)&&(x<=435)&&(y>=350)&&(y<=352)) ||
                ((x>=225)&&(x<=435)&&(y>=404)&&(y<=406)) ||
                ((x>=225)&&(x<=227)&&(y>=350)&&(y<=406)) ||
                ((x>=433)&&(x<=435)&&(y>=350)&&(y<=406))) begin r=0;g=12;b=12; end
            if ((x>227)&&(x<433)&&(y>=pool_surf)&&(y<404)) begin r=0;g=7;b=11; end
            if ((x>227)&&(x<433)&&(y>=pool_surf)&&(y<pool_surf+2)) begin r=0;g=15;b=15; end

            // Pipework to the saving basin.
            if (((x>=246)&&(x<=249)&&(y>=FLOOR_C1)&&(y<=350)) ||
                ((x>=395)&&(x<=398)&&(y>=FLOOR_C2)&&(y<=350)) ||
                ((y>=348)&&(y<=351)&&(x>=246)&&(x<=398))) begin r=5;g=7;b=8; end

            // Water-transfer markers.
            pipe_dot_y = 305 + ((flow_phase & 6'h1F) << 1);
            if ((flow_code==4'd1) && (x>=244)&&(x<=251)&&(y>=pipe_dot_y)&&(y<pipe_dot_y+5)) begin r=0;g=15;b=15; end
            if ((flow_code==4'd5) && (x>=393)&&(x<=400)&&(y>=335+((flow_phase&6'h07)<<1))&&(y<340+((flow_phase&6'h07)<<1))) begin r=0;g=15;b=15; end
            if ((flow_code==4'd3) && (x>=393)&&(x<=400)&&(y>=350-((flow_phase&6'h07)<<1))&&(y<355-((flow_phase&6'h07)<<1))) begin r=0;g=15;b=15; end

            // DOWN-bound ships are yellow; UP-bound ships are green/cyan.
            if (up_ship_hit) begin r=15;g=13;b=0; end
            if (dn_ship_hit) begin r=0;g=15;b=8; end
            if (static_ship_hit) begin
                if (batch_dir_up) begin r=0;g=15;b=8; end
                else begin r=15;g=13;b=0; end
            end
            if (moving_ship_hit) begin
                if (anim_dir_up) begin r=0;g=15;b=8; end
                else begin r=15;g=13;b=0; end
            end

            // Text is drawn last.
            if (text_on) begin
                if (text_row == 5'd2) begin r=15;g=12;b=0; end
                else begin r=15;g=15;b=15; end
            end
        end
    end
endmodule
