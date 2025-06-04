`timescale 1ns / 1ps
/*
module only_red (
    input  logic [11:0] image_data,
    input  logic [ 8:0] hue_value,
    input  logic [ 7:0] sat_value,
    output logic [11:0] rgb_out
);

    logic [11:0] rgb_gray;
    grayscale gray_module (
        .image_data(image_data),
        .rgb_gray  (rgb_gray)
    );

    always_comb begin

        if (((hue_value >= 350) || (hue_value <= 10)) && (sat_value >= 64)) begin
            rgb_out = image_data;
        end else begin
            rgb_out = rgb_gray;
        end
    end
endmodule
*/
