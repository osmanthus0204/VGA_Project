`timescale 1ns / 1ps

module rgb2hsv (
    input  logic [11:0] rgb_in,
    output logic [ 8:0] hue_out,
    output logic [ 7:0] sat_out,
    output logic [ 7:0] val_out
);
    logic [3:0] r, g, b;
    logic [3:0] max_rgb, min_rgb;
    logic [4:0] delta;
    logic signed [15:0] hue_calc;
    logic [15:0] s_calc;

    parameter int SCALE = 960;

    assign r = rgb_in[11:8];
    assign g = rgb_in[7:4];
    assign b = rgb_in[3:0];

    always_comb begin
        max_rgb = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b);
        min_rgb = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b);
        delta = max_rgb - min_rgb;

        hue_calc = 0;
        s_calc = 0;

        if (delta == 0) hue_calc = 0;
        else if (max_rgb == r) hue_calc = (((SCALE * (g - b)) / delta) >> 4);
        else if (max_rgb == g)
            hue_calc = ((((SCALE * (b - r)) / delta) >> 4) + 120);
        else if (max_rgb == b)
            hue_calc = ((((SCALE * (r - g)) / delta) >> 4) + 240);

        if (hue_calc < 0) hue_calc = hue_calc + 360;
        hue_out = (hue_calc > 360) ? 360 : hue_calc;

        if (max_rgb == 0) s_calc = 0;
        else s_calc = (delta << 8) / max_rgb;

        sat_out = (s_calc > 255) ? 255 : s_calc;
        val_out = {max_rgb, 4'b0};
    end
endmodule

