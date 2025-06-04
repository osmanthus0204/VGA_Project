`timescale 1ns / 1ps


module mux_monitor (
    input        [ 1:0] sel,
    input  logic [11:0] data_160x120,
    input  logic [11:0] data_320x240,
    input  logic [11:0] data_640x480,
    output logic [11:0] camera_data
);

    always_comb begin : upscale_select
        case (sel)
            2'b00:   camera_data = data_160x120;
            2'b01:   camera_data = data_320x240;
            2'b11:   camera_data = data_640x480;
            default: camera_data = 0;
        endcase
    end

endmodule
