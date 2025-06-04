`timescale 1ns / 1ps


module grayscale (
    input  logic [11:0] image_data,
    output logic [11:0] rgb_gray
);
    logic [11:0] red_gray, green_gray, blue_gray;
    logic [11:0] sum_gray;

    assign red_gray = image_data[11:8] * 77;  // red
    assign green_gray  = image_data[7:4] * 150;  // green
    assign blue_gray  = image_data[3:0] * 29;  // blue

    assign sum_gray = red_gray + green_gray + blue_gray;

    assign rgb_gray = {sum_gray[11:8], sum_gray[11:8], sum_gray[11:8]};

endmodule


