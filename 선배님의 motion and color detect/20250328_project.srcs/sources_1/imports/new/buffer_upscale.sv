`timescale 1ns / 1ps

module buffer_upscale (
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        display_enable,
    output logic [16:0] rAddr0,
    output logic [16:0] rAddr1,
    output logic [16:0] rAddr2,
    output logic [16:0] rAddr3,
    input  logic [11:0] rData0,
    input  logic [11:0] rData1,
    input  logic [11:0] rData2,
    input  logic [11:0] rData3,
    output logic        oe,
    output logic [11:0] data_160x120,
    output logic [11:0] data_320x240,
    output logic [11:0] data_640x480
);

    logic [11:0] rData0_reg, rData1_reg, rData2_reg, rData3_reg;
    logic [9:0]
        temp_red_h25, temp_green_h25, temp_blue_h25;
    logic [9:0] temp_red_h50, temp_green_h50, temp_blue_h50;
    logic [9:0] temp_red_v50, temp_green_v50, temp_blue_v50;
    logic [9:0] temp_red_h50_v50, temp_green_h50_v50, temp_blue_h50_v50;
    logic [9:0]
        temp_red_h75, temp_green_h75, temp_blue_h75;
    logic [9:0]
        temp_red_v25, temp_green_v25, temp_blue_v25;
    logic [9:0]
        temp_red_v75, temp_green_v75, temp_blue_v75;


    logic [9:0] temp_red_h25_v25, temp_green_h25_v25, temp_blue_h25_v25;
    logic [9:0] temp_red_h25_v50, temp_green_h25_v50, temp_blue_h25_v50;
    logic [9:0] temp_red_h25_v75, temp_green_h25_v75, temp_blue_h25_v75;
    logic [9:0] temp_red_h50_v25, temp_green_h50_v25, temp_blue_h50_v25;
    logic [9:0] temp_red_h50_v75, temp_green_h50_v75, temp_blue_h50_v75;
    logic [9:0] temp_red_h75_v25, temp_green_h75_v25, temp_blue_h75_v25;
    logic [9:0] temp_red_h75_v50, temp_green_h75_v50, temp_blue_h75_v50;
    logic [9:0] temp_red_h75_v75, temp_green_h75_v75, temp_blue_h75_v75;

    always_comb begin
        if (display_enable && x_pixel < 640 && y_pixel < 480) begin
            oe = 1'b1;
            rAddr0 = ((y_pixel >> 2) * 160) + (x_pixel >> 2);
            rAddr1 = (x_pixel >> 2 < 159) ? rAddr0 + 1 : rAddr0;
            rAddr2 = (y_pixel >> 2 < 119) ? (((y_pixel >> 2) + 1) * 160) + (x_pixel >> 2) : rAddr0;
            rAddr3 = (x_pixel >> 2 < 159 && y_pixel >> 2 < 119) ? rAddr2 + 1 : rAddr2;

            rData0_reg = rData0;
            rData1_reg = rData1;
            rData2_reg = rData2;
            rData3_reg = rData3;

            // h50 v50
            temp_red_h50_v50 = ((4)* rData0_reg[11:8] + (4)* rData1_reg[11:8] + (4)* rData2_reg[11:8] + (4)* rData3_reg[11:8]) >> 4;
            temp_green_h50_v50 = ((4)* rData0_reg[7:4] + (4)* rData1_reg[7:4] + (4)* rData2_reg[7:4] + (4)* rData3_reg[7:4]) >> 4;
            temp_blue_h50_v50 = ((4)* rData0_reg[3:0] + (4)* rData1_reg[3:0] + (4)* rData2_reg[3:0] + (4)* rData3_reg[3:0]) >> 4;

            
            // h25
            temp_red_h25 = ((12) * rData0_reg[11:8] + (4) * rData1_reg[11:8]) >> 4;
            temp_green_h25 = ((12) * rData0_reg[7:4] + (4) * rData1_reg[7:4]) >> 4;
            temp_blue_h25 = ((12) * rData0_reg[3:0] + (4) * rData1_reg[3:0]) >> 4;

            // h50
            temp_red_h50 = ((8)* rData0_reg[11:8] + (8)* rData1_reg[11:8]) >> 4;
            temp_green_h50 = ((8)* rData0_reg[7:4] + (8)* rData1_reg[7:4]) >> 4;
            temp_blue_h50 = ((8)* rData0_reg[3:0] + (8)* rData1_reg[3:0]) >> 4;

            // h75
            temp_red_h75 = ((4)* rData0_reg[11:8] + (12)* rData1_reg[11:8]) >> 4;
            temp_green_h75 = ((4)* rData0_reg[7:4] + (12)* rData1_reg[7:4]) >> 4;
            temp_blue_h75 = ((4)* rData0_reg[3:0] + (12)* rData1_reg[3:0]) >> 4;

            // v25
            temp_red_v25 = ((12)* rData0_reg[11:8] + (4)* rData2_reg[11:8]) >> 4;
            temp_green_v25 = ((12)* rData0_reg[7:4] + (4)* rData2_reg[7:4]) >> 4;
            temp_blue_v25 = ((12)* rData0_reg[3:0] + (4)* rData2_reg[3:0]) >> 4;

            // h25 v25
            temp_red_h25_v25 = ((9)* rData0_reg[11:8] + (3)* rData1_reg[11:8] + (3)* rData2_reg[11:8] + (1)* rData3_reg[11:8]) >> 4;
            temp_green_h25_v25 = ((9)* rData0_reg[7:4] + (3)* rData1_reg[7:4] + (3)* rData2_reg[7:4] + (1)* rData3_reg[7:4]) >> 4;
            temp_blue_h25_v25 = ((9)* rData0_reg[3:0] + (3)* rData1_reg[3:0] + (3)* rData2_reg [3:0]+ (1)* rData3_reg[3:0]) >> 4;

            // h50 v25
            temp_red_h50_v25 = ((6)* rData0_reg[11:8] + (6)* rData1_reg[11:8] + (2)* rData2_reg[11:8] + (2)* rData3_reg[11:8]) >> 4;
            temp_green_h50_v25 = ((6)* rData0_reg[7:4] + (6)* rData1_reg[7:4] + (2)* rData2_reg[7:4] + (2)* rData3_reg[7:4]) >> 4;
            temp_blue_h50_v25 = ((6)* rData0_reg[3:0] + (6)* rData1_reg[3:0] + (2)* rData2_reg[3:0] + (2)* rData3_reg[3:0]) >> 4;

            // h75 v25
            temp_red_h75_v25 = ((3)* rData0_reg[11:8] + (9)* rData1_reg[11:8] + (1)* rData2_reg[11:8] + (3)* rData3_reg[11:8]) >> 4;
            temp_green_h75_v25 = ((3)* rData0_reg[7:4] + (9)* rData1_reg[7:4] + (1)* rData2_reg[7:4] + (3)* rData3_reg[7:4]) >> 4;
            temp_blue_h75_v25 = ((3)* rData0_reg[3:0] + (9)* rData1_reg[3:0] + (1)* rData2_reg[3:0] + (3)* rData3_reg[3:0]) >> 4;


            // v50
            temp_red_v50 = ((8)* rData0_reg[11:8] + (8)* rData2_reg[11:8]) >> 4;
            temp_green_v50 = ((8)* rData0_reg[7:4] + (8)* rData2_reg[7:4]) >> 4;
            temp_blue_v50 = ((8)* rData0_reg[3:0] + (8)* rData2_reg[3:0]) >> 4;

            // h25 v50
            temp_red_h25_v50 = ((6)* rData0_reg[11:8] + (2)* rData1_reg[11:8] + (6)* rData2_reg[11:8] + (2)* rData3_reg[11:8]) >> 4;
            temp_green_h25_v50 = ((6)* rData0_reg[7:4] + (2)* rData1_reg[7:4] + (6)* rData2_reg[7:4] + (2)* rData3_reg[7:4]) >> 4;
            temp_blue_h25_v50 = ((6)* rData0_reg[3:0] + (2)* rData1_reg[3:0] + (6)* rData2_reg[3:0] + (2)* rData3_reg[3:0]) >> 4;


            // h75 v50
            temp_red_h75_v50 = ((2)* rData0_reg[11:8] + (6)* rData1_reg[11:8] + (2)* rData2_reg[11:8] + (6)* rData3_reg[11:8]) >> 4;
            temp_green_h75_v50 = ((2)* rData0_reg[7:4] + (6)* rData1_reg[7:4] + (2)* rData2_reg[7:4] + (6)* rData3_reg[7:4]) >> 4;
            temp_blue_h75_v50 = ((2)* rData0_reg[3:0] + (6)* rData1_reg[3:0] + (2)* rData2_reg[3:0] + (6)* rData3_reg[3:0]) >> 4;

            // v75
            temp_red_v75 = ((4)* rData0_reg[11:8] + (12)* rData2_reg[11:8]) >> 4;
            temp_green_v75 = ((4)* rData0_reg[7:4] + (12)* rData2_reg[7:4]) >> 4;
            temp_blue_v75 = ((4)* rData0_reg[3:0] + (12)* rData2_reg[3:0]) >> 4;

            // h25 v75
            temp_red_h25_v75 = ((3)* rData0_reg[11:8] + (1)* rData1_reg[11:8] + (9)* rData2_reg[11:8] + (3)* rData3_reg[11:8]) >> 4;
            temp_green_h25_v75 = ((3)* rData0_reg[7:4] + (1)* rData1_reg[7:4] + (9)* rData2_reg[7:4] + (3)* rData3_reg[7:4]) >> 4;
            temp_blue_h25_v75 = ((3)* rData0_reg[3:0] + (1)* rData1_reg[3:0] + (9)* rData2_reg[3:0] + (3)* rData3_reg[3:0]) >> 4;

            // h50 v75
            temp_red_h50_v75 = ((2)* rData0_reg[11:8] + (2)* rData1_reg[11:8] + (6)* rData2_reg[11:8] + (6)* rData3_reg[11:8]) >> 4;
            temp_green_h50_v75 = ((2)* rData0_reg[7:4] + (2)* rData1_reg[7:4] + (6)* rData2_reg[7:4] + (6)* rData3_reg[7:4]) >> 4;
            temp_blue_h50_v75 = ((2)* rData0_reg[3:0] + (2)* rData1_reg[3:0] + (6)* rData2_reg[3:0] + (6)* rData3_reg[3:0]) >> 4;

            // h75 v75
            temp_red_h75_v75 = ((1)* rData0_reg[11:8] + (3)* rData1_reg[11:8] + (3)* rData2_reg[11:8] + (9)* rData3_reg[11:8]) >> 4;
            temp_green_h75_v75 = ((1)* rData0_reg[7:4] + (3)* rData1_reg[7:4] + (3)* rData2_reg[7:4] + (9)* rData3_reg[7:4]) >> 4;
            temp_blue_h75_v75 = ((1)* rData0_reg[3:0] + (3)* rData1_reg[3:0]+ (3)* rData2_reg[3:0] + (9)* rData3_reg[3:0]) >> 4;
            

            data_160x120 = rData0_reg;

            case ({
                y_pixel[0], x_pixel[0]
            })
                2'b00: data_320x240 = rData0_reg;
                2'b01: data_320x240 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                2'b10: data_320x240 = rData0_reg;
                2'b11: data_320x240 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                default: data_320x240 = rData0_reg;
            endcase

            case ({
                y_pixel[1:0], x_pixel[1:0]
            })
                4'b00_00: data_640x480 = rData0_reg;
                4'b00_01: data_640x480 = {temp_red_h25[3:0], temp_green_h25[3:0], temp_blue_h25[3:0]};
                4'b00_10: data_640x480 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                4'b00_11: data_640x480 = {temp_red_h75[3:0], temp_green_h75[3:0], temp_blue_h75[3:0]};

                4'b01_00: data_640x480 = rData0_reg;
                4'b01_01: data_640x480 = {temp_red_h25[3:0], temp_green_h25[3:0], temp_blue_h25[3:0]};
                4'b01_10: data_640x480 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                4'b01_11: data_640x480 = {temp_red_h75[3:0], temp_green_h75[3:0], temp_blue_h75[3:0]};

                4'b10_00: data_640x480 = rData0_reg;
                4'b10_01: data_640x480 = {temp_red_h25[3:0], temp_green_h25[3:0], temp_blue_h25[3:0]};
                4'b10_10: data_640x480 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                4'b10_11: data_640x480 = {temp_red_h75[3:0], temp_green_h75[3:0], temp_blue_h75[3:0]};

                4'b11_00: data_640x480 = rData0_reg;
                4'b11_01: data_640x480 = {temp_red_h25[3:0], temp_green_h25[3:0], temp_blue_h25[3:0]};
                4'b11_10: data_640x480 = {temp_red_h50[3:0], temp_green_h50[3:0], temp_blue_h50[3:0]};
                4'b11_11: data_640x480 = {temp_red_h75[3:0], temp_green_h75[3:0], temp_blue_h75[3:0]};

/*
                4'b01_00:
                data_640x480 = {
                    temp_red_v25[3:0], temp_green_v25[3:0], temp_blue_v25[3:0]
                };
                4'b01_01:
                data_640x480 = {
                    temp_red_h25_v25[3:0],
                    temp_green_h25_v25[3:0],
                    temp_blue_h25_v25[3:0]
                };
                4'b01_10:
                data_640x480 = {
                    temp_red_h50_v25[3:0],
                    temp_green_h50_v25[3:0],
                    temp_blue_h50_v25[3:0]
                };
                4'b01_11:
                data_640x480 = {
                    temp_red_h75_v25[3:0],
                    temp_green_h75_v25[3:0],
                    temp_blue_h75_v25[3:0]
                };

                4'b10_00:
                data_640x480 = {
                    temp_red_v50[3:0], temp_green_v50[3:0], temp_blue_v50[3:0]
                };
                4'b10_01:
                data_640x480 = {
                    temp_red_h25_v50[3:0],
                    temp_green_h25_v50[3:0],
                    temp_blue_h25_v50[3:0]
                };
                4'b10_10:
                data_640x480 = {
                    temp_red_h50_v50[3:0],
                    temp_green_h50_v50[3:0],
                    temp_blue_h50_v50[3:0]
                };
                4'b10_11:
                data_640x480 = {
                    temp_red_h75_v50[3:0],
                    temp_green_h75_v50[3:0],
                    temp_blue_h75_v50[3:0]
                };

                4'b11_00:
                data_640x480 = {
                    temp_red_v75[3:0], temp_green_v75[3:0], temp_blue_v75[3:0]
                };
                4'b11_01:
                data_640x480 = {
                    temp_red_h25_v75[3:0],
                    temp_green_h25_v75[3:0],
                    temp_blue_h25_v75[3:0]
                };
                4'b11_10:
                data_640x480 = {
                    temp_red_h50_v75[3:0],
                    temp_green_h50_v75[3:0],
                    temp_blue_h50_v75[3:0]
                };
                4'b11_11:
                data_640x480 = {
                    temp_red_h75_v75[3:0],
                    temp_green_h75_v75[3:0],
                    temp_blue_h75_v75[3:0]
                };
*/
                default: data_640x480 = rData0_reg;
            endcase

        end else begin
            data_160x120 = 0;
            data_320x240 = 0;
            data_640x480 = 0;
            oe = 1'b0;
            rData0_reg = 0;
            rData1_reg = 0;
            rData2_reg = 0;
            rData3_reg = 0;
            rAddr0 = 17'bz;
            rAddr1 = 17'bz;
            rAddr2 = 17'bz;
            rAddr3 = 17'bz;

            temp_red_h50 = 0;
            temp_red_v50 = 0;
            temp_red_h50_v50 = 0;
            temp_red_v75 = 0;
            temp_red_h25 = 0;
            temp_red_h75 = 0;
            temp_red_v25 = 0;
            temp_red_h25_v25 = 0;
            temp_red_h25_v50 = 0;
            temp_red_h25_v75 = 0;
            temp_red_h25_v50 = 0;
            temp_red_h75_v50 = 0;
            temp_red_h25_v75 = 0;
            temp_red_h50_v75 = 0;
            temp_red_h75_v75 = 0;

            temp_green_h50 = 0;
            temp_green_v50 = 0;
            temp_green_h50_v50 = 0;
            temp_green_h75 = 0;
            temp_green_v25 = 0;
            temp_green_h25 = 0;
            temp_green_h25_v25 = 0;
            temp_green_h25_v50 = 0;
            temp_green_h25_v75 = 0;
            temp_green_h25_v50 = 0;
            temp_green_h75_v50 = 0;
            temp_green_v75 = 0;
            temp_green_h25_v75 = 0;
            temp_green_h50_v75 = 0;
            temp_green_h75_v75 = 0;

            temp_blue_h50 = 0;
            temp_blue_v50 = 0;
            temp_blue_h50_v50 = 0;
            temp_blue_h25 = 0;
            temp_blue_h75 = 0;
            temp_blue_v25 = 0;
            temp_blue_h25_v25 = 0;
            temp_blue_h25_v50 = 0;
            temp_blue_h25_v75 = 0;
            temp_blue_h25_v50 = 0;
            temp_blue_h75_v50 = 0;
            temp_blue_v75 = 0;
            temp_blue_h25_v75 = 0;
            temp_blue_h50_v75 = 0;
            temp_blue_h75_v75 = 0;
        end
    end

endmodule

