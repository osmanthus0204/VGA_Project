`timescale 1ns / 1ps

module vga_controller (
    input  logic       clk,
    input  logic       reset,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       display_enable
);
    logic [9:0] h_counter, v_counter;
/*
    pixel_clk_gen U_Pxl_Clk_Gen (
        .clk  (clk),
        .reset(reset),
        .pclk (pclk),
        .xlk  (xlk)
    );
*/
    pixel_counter U_Pxl_Counter (
        .pclk     (clk),
        .reset    (reset),
        .h_counter(h_counter),
        .v_counter(v_counter)
    );

    vga_decoder U_VGA_Decoder (
        .h_counter     (h_counter),
        .v_counter     (v_counter),
        .h_sync        (h_sync),
        .v_sync        (v_sync),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable)
    );
endmodule

/*
module pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic pclk,
    output logic xlk
);
    logic [1:0] pxl_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            pxl_counter <= 0;
            pclk        <= 1'b0;
            xlk         <= 1'b0;
        end else begin
            if (pxl_counter == 3) begin
                pxl_counter <= 0;
                pclk <= 1'b1;
            end else if (pxl_counter%2 == 0) begin
                xlk  <= ~xlk;
                pclk <= 1'b0;
            end else begin
                pclk <= 1'b0;
            end
            pxl_counter <= pxl_counter + 1;
        end
    end
endmodule
*/
module pixel_counter (
    input  logic       pclk,
    input  logic       reset,
    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);
    localparam H_MAX = 800, V_MAX = 525;

    always_ff @(posedge pclk, posedge reset) begin : Horizontal_counter
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(posedge pclk, posedge reset) begin : Vertical_counter
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

endmodule

module vga_decoder (
    input  logic [9:0] h_counter,
    input  logic [9:0] v_counter,
    output logic       h_sync,
    output logic       v_sync,
    output logic [9:0] x_pixel,
    output logic [9:0] y_pixel,
    output logic       display_enable
);

    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;
    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_frame = 525;

    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter < (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter < (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign display_enable = (h_counter < H_Visible_area) && (v_counter < V_Visible_area);
    assign x_pixel = (h_counter < H_Visible_area) ? h_counter : 0;
    assign y_pixel = (v_counter < V_Visible_area) ? v_counter : 0;

endmodule
