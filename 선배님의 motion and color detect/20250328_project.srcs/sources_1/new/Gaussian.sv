`timescale 1ns / 1ps


module Gaussian (
    input  logic        clk,
    input  logic        reset,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        display_enable,
    input  logic [11:0] camera_data,
    output logic [11:0] gaussian
);
    logic [11:0] rgb_gray_640x480;

    logic [3:0] line0[0:639];
    logic [3:0] line1[0:639];

    logic [7:0] pixel00, pixel01, pixel02;
    logic [7:0] pixel10, pixel11, pixel12;
    logic [7:0] pixel20, pixel21, pixel22;

    logic [2:0] valid_pipeline;
    logic [9:0] x_pipeline[0:2];
    logic [9:0] y_pipeline[0:2];

    logic [15:0] mag_gaussian_640x480;

    assign gaussian = {
        mag_gaussian_640x480[3:0], mag_gaussian_640x480[3:0], mag_gaussian_640x480[3:0]
    };

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 640; i++) begin
                line0[i] <= 0;
                line1[i] <= 0;
            end
        end else if (display_enable) begin
            line1[x_pixel] <= line0[x_pixel];
            line0[x_pixel] <= rgb_gray_640x480[11:8];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            {pixel00, pixel01, pixel02} <= 0;
            {pixel10, pixel11, pixel12} <= 0;
            {pixel20, pixel21, pixel22} <= 0;
            valid_pipeline <= 0;
        end else if (display_enable) begin
            pixel02 <= line1[x_pixel];
            pixel01 <= pixel02;
            pixel00 <= pixel01;

            pixel12 <= line0[x_pixel];
            pixel11 <= pixel12;
            pixel10 <= pixel11;

            pixel22 <= rgb_gray_640x480[11:8];
            pixel21 <= pixel22;
            pixel20 <= pixel21;

            x_pipeline[0] <= x_pixel;
            y_pipeline[0] <= y_pixel;
            for (int i = 1; i < 3; i++) begin
                x_pipeline[i] <= x_pipeline[i-1];
                y_pipeline[i] <= y_pipeline[i-1];
            end

            valid_pipeline <= {
                valid_pipeline[1:0], (x_pixel >= 2 && y_pixel >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin 
            mag_gaussian_640x480 <= 0;
        end
        else if (valid_pipeline[1]) begin
            mag_gaussian_640x480 <= (
                pixel00    +(pixel01<<1)  +pixel02+
               (pixel10<<1)+(pixel11<<2)  +(pixel12<<1)+
                pixel20    +(pixel21<<1)  +pixel22
            )>>4;
        end else begin
            mag_gaussian_640x480 <= rgb_gray_640x480;
        end
    end

    grayscale U_grayScale_640x480 (
        .image_data(camera_data),
        .rgb_gray  (rgb_gray_640x480)
    );

endmodule




