`timescale 1ns / 1ps

module Camera_OV7670 (
    input  logic       clk,
    input  logic       reset,
    input  logic [5:0] sw,
    input  logic [1:0] monitor_sel,
    input  logic       pclk,
    output logic       xclk,
    input  logic [7:0] cam_data,
    input  logic       cam_href,
    input  logic       cam_v_sync,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] grn_port,
    output logic [3:0] blu_port,
    output logic       scl,
    output logic       sda,
    input  logic       start
);

    logic display_enable;
    logic [9:0] x_pixel, y_pixel;
    logic [11:0] rgb_data, wData;
    logic [16:0] wAddr;
    logic [11:0] histed;

    logic clk_25MHz;
    logic oe, we;

    logic [8:0] hue_value;
    logic [7:0] sat_value, val_out;
    logic [7:0] rom_data, rom_addr;
    logic w_start;
    logic clk_100MHz;
    logic [16:0] rAddr0, rAddr1, rAddr2, rAddr3, wAddr0, wAddr1;
    logic [11:0] rData0, rData1, rData2, rData3, wData0, wData1;
    logic [11:0] upsize_320x240, Upscale_data;
    logic [11:0]
        data_160x120,
        data_320x120,
        data_640x120,
        data_160x240,
        data_320x240,
        data_640x480;
    logic [11:0] gaussian_data, gaussian_motion_1, gaussian_motion_2;
    logic frame_select;


    logic [11:0]
        camera_data,
        rgb_gray,
        color_pop_out,
        sobel_data,
        log_data,
        binary_noise_out,
        rgb_gray_on;

    logic is_box_pixel;
    logic dense_pixel;

    assign red_port = (display_enable && x_pixel < 640 && y_pixel < 480) ? 
                      (is_box_pixel ? 4'hF : rgb_data[11:8]) : 4'b0;
    assign grn_port = (display_enable && x_pixel < 640 && y_pixel < 480) ? 
                      (is_box_pixel ? 4'h0 : rgb_data[7:4])  : 4'b0;
    assign blu_port = (display_enable && x_pixel < 640 && y_pixel < 480) ? 
                      (is_box_pixel ? 4'h0 : rgb_data[3:0])  : 4'b0;

    assign rgb_gray_on = motion ? {4'h0, 8'hf0} : camera_data;

    assign xclk = clk_25MHz;

    clk_wiz_0 U_clk_25MHz (
        .clk_in1   (clk),
        .reset     (reset),
        .clk_25MHz (clk_25MHz),
        .clk_100MHz(clk_100MHz)
    );

    button_debounce U_up_btn (
        .clk  (clk_100MHz),
        .reset(reset),
        .i_btn(start),
        .o_btn(w_start)
    );

    TOP_SCCB U_TOP_SCCB (
        .clk  (clk_100MHz),
        .reset(reset),
        .btn  (w_start),
        .scl  (scl),
        .sda  (sda)
    );

    vga_controller U_vga_controller (
        .clk           (clk_25MHz),
        .reset         (reset),
        .h_sync        (h_sync),
        .v_sync        (v_sync),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable)
    );

    OV7670_controller_160x120 U_ov7670controller (
        .pclk       (pclk),
        .reset      (reset),
        .href       (cam_href),
        .v_sync     (cam_v_sync),
        .ov7670_data(cam_data),
        .we         (we),
        .wAddr      (wAddr),
        .wData      (wData),
        .select     (frame_select)
    );

    logic we0, we1;
    logic [11:0] rData00, rData01, rData02, rData03;
    logic [11:0] rData10, rData11, rData12, rData13;

    always_comb begin
        if (frame_select == 0) begin
            we0 = we;
            we1 = 1'b0;
            wAddr0 = wAddr;
            wData0 = wData;

            rData0 = rData00;
            rData1 = rData01;
            //rData2 = rData02;
            //rData3 = rData03;
        end else begin
            we0 = 1'b0;
            we1 = we;
            wAddr1 = wAddr;
            wData1 = wData;

            rData0 = rData10;
            rData1 = rData11;
            //rData2 = rData12;
            //rData3 = rData13;
        end
    end

    frameBuffer U_frameBuffer0 (
        .wclk  (pclk),
        .we    (we0),
        .wAddr (wAddr0),
        .wData (wData0),
        .rclk  (clk_25MHz),
        .oe    (oe),
        .rAddr0(rAddr0),
        .rAddr1(rAddr1),
        .rAddr2(),
        .rAddr3(),
        .rData0(rData00),
        .rData1(rData01),
        .rData2(),
        .rData3()
    );

    frameBuffer U_frameBuffer1 (
        .wclk  (pclk),
        .we    (we1),
        .wAddr (wAddr1),
        .wData (wData1),
        .rclk  (clk_25MHz),
        .oe    (oe),
        .rAddr0(rAddr0),
        .rAddr1(rAddr1),
        .rAddr2(),
        .rAddr3(),
        .rData0(rData10),
        .rData1(rData11),
        .rData2(),
        .rData3()
    );

    motion_detector U_motion_detector (
        .clk(clk_25MHz),
        .pixel1(gaussian_motion_1),
        .pixel2(gaussian_motion_2),
        .motion(motion)
    );

    buffer_upscale U_Buffer_Upscale (
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(display_enable),
        .rAddr0        (rAddr0),
        .rAddr1        (rAddr1),
        .rAddr2        (),
        .rAddr3        (),
        .rData0        (rData0),
        .rData1        (rData1),
        .rData2        (),
        .rData3        (),
        .oe            (oe),
        .data_160x120  (data_160x120),
        .data_320x240  (data_320x240),
        .data_640x480  (data_640x480)
    );

    grayscale U_grayScale (
        .image_data(camera_data),
        .rgb_gray  (rgb_gray)
    );

    /*
    rgb2hsv U_hsv_inst (
        .rgb_in (camera_data),
        .hue_out(hue_value),
        .sat_out(sat_value),
        .val_out()
    );
*/
    /*
    only_red color_highlight (
        .image_data(data_640x480),
        .hue_value (hue_value),
        .rgb_out   (color_pop_out),
        .sat_value (sat_value)
    );
    */

    Gaussian U_Gaussian_motion1 (
        .clk           (clk_25MHz),
        .reset         (reset),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(oe),
        .camera_data   (rData00),
        .gaussian      (gaussian_motion_1)
    );

    Gaussian U_Gaussian_motion2 (
        .clk           (clk_25MHz),
        .reset         (reset),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(oe),
        .camera_data   (rData10),
        .gaussian      (gaussian_motion_2)
    );


    Gaussian U_Gaussian_scale (
        .clk           (clk_25MHz),
        .reset         (reset),
        .x_pixel       (x_pixel),
        .y_pixel       (y_pixel),
        .display_enable(oe),
        .camera_data   (camera_data),
        .gaussian      (gaussian_data)
    );

    //----------------------창현-----------------------------


    image_processor U_image_proc (
        .clk             (clk_25MHz),
        .reset           (reset),
        .oe              (oe),
        .camera_data     (camera_data),       // camera_data
        .rgb_gray        (rgb_gray),
        .color_pop_out   (color_pop_out),
        .sobel_data      (sobel_data),
        .log_data        (log_data),
        .binary_noise_out(binary_noise_out),
        .binary_filtered (),
        .dense_pixel     (dense_pixel)
    );

    multi_red_tracker_box #(
        .BLOCK_SIZE(5),
        .IMG_WIDTH(160),
        .IMG_HEIGHT(120),
        .RED_THRESHOLD(10),
        .BOX_SIZE(10)
    ) U_tracker (
        .clk         (clk_25MHz),
        .reset       (reset),
        .v_sync      (v_sync),
        .oe          (oe),
        .x_pixel     (x_pixel),
        .y_pixel     (y_pixel),
        .dense_pixel (dense_pixel),
        .is_box_pixel(is_box_pixel)
    );


    mux_monitor U_Mux_monitor (
        .sel         (monitor_sel),
        .data_160x120(data_160x120),  // 2'b00
        .data_320x240(data_320x240),  // 2'b01
        .data_640x480(data_640x480),  // 2'b10
        .camera_data (camera_data)
    );

    mux U_MUX (
        .sel    (sw),
        .inData0(camera_data),       // 6'b000000
        .inData1(gaussian_data),     // 6'b000001, upscale gaussian
        .inData2(color_pop_out),     // 6'b000011
        .inData3(sobel_data),        // 6'b000111
        .inData4(log_data),          // 6'b001111
        .inData5(binary_noise_out),  // 6'b011111
        .inData6(rgb_gray_on),       // 6'b111111
        .outData(rgb_data)
    );

endmodule


// mux U_2x1_Mux (
//     .inData1(camera_data),
//     .inData2(rgb_gray),
//     .inData3(color_pop_out),
//     .inData4(sobel_data),
//     .inData5(binary_noise_out),
//     .inData6(log_data),
//     .inData7(),
//     .sel    (sw),
//     .outData(rgb_data)
// );
/////////////////

module multi_red_tracker_box #(
    parameter BLOCK_SIZE    = 16,
    parameter IMG_WIDTH     = 160,
    parameter IMG_HEIGHT    = 120,
    parameter RED_THRESHOLD = 7,
    parameter BOX_SIZE      = 10
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       v_sync,
    input  logic       oe,
    input  logic [9:0] x_pixel,
    input  logic [9:0] y_pixel,
    input  logic       dense_pixel,
    output logic       is_box_pixel
);

    parameter BLOCK_COLS = IMG_WIDTH / BLOCK_SIZE;
    parameter BLOCK_ROWS = IMG_HEIGHT / BLOCK_SIZE;
    parameter BLOCK_COUNT = BLOCK_COLS * BLOCK_ROWS;


    logic [5:0] block_count[0:BLOCK_COUNT-1];
    logic [BLOCK_COUNT-1:0] block_valid;

    logic v_sync_prev, frame_done;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) v_sync_prev <= 0;
        else v_sync_prev <= v_sync;
    end

    
    assign frame_done = (v_sync_prev && !v_sync);



    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < BLOCK_COUNT; i++) begin
                block_count[i] <= 0;
                block_valid[i] <= 0;
            end
        end else if (frame_done) begin
            for (i = 0; i < BLOCK_COUNT; i++) begin
                block_valid[i] <= (block_count[i] >= RED_THRESHOLD);
                block_count[i] <= 0;
            end
        end else if (oe && dense_pixel) begin
            automatic int bx = (x_pixel >> 2) / BLOCK_SIZE;
            automatic int by = (y_pixel >> 2) / BLOCK_SIZE;
            automatic int idx = by * BLOCK_COLS + bx;
            if (idx < BLOCK_COUNT) block_count[idx] <= block_count[idx] + 1;
        end
    end

    // VGA 좌표
    logic [9:0] vga_x, vga_y;
    assign vga_x = x_pixel;
    assign vga_y = y_pixel;

    // 박스 경계 출력
    logic hit;
    always_comb begin
        hit = 0;
        for (i = 0; i < BLOCK_COUNT; i++) begin
            if (block_valid[i]) begin
                automatic int bx = i % BLOCK_COLS;
                automatic int by = i / BLOCK_COLS;
                automatic int cx = (bx * BLOCK_SIZE + BLOCK_SIZE / 2) << 2;
                automatic int cy = (by * BLOCK_SIZE + BLOCK_SIZE / 2) << 2;

                automatic int x_min = (cx > BOX_SIZE) ? cx - BOX_SIZE : 0;
                automatic int x_max = (cx < 619) ? cx + BOX_SIZE : 639;
                automatic int y_min = (cy > BOX_SIZE) ? cy - BOX_SIZE : 0;
                automatic int y_max = (cy < 459) ? cy + BOX_SIZE : 479;

                if (
                    ((vga_x >= x_min && vga_x < x_min + 3) && (vga_y >= y_min && vga_y <= y_max)) ||
                    ((vga_x <= x_max && vga_x > x_max - 3) && (vga_y >= y_min && vga_y <= y_max)) ||
                    ((vga_y >= y_min && vga_y < y_min + 3) && (vga_x >= x_min && vga_x <= x_max)) ||
                    ((vga_y <= y_max && vga_y > y_max - 3) && (vga_x >= x_min && vga_x <= x_max))
                )
                    hit = 1;
            end
        end
        is_box_pixel = hit;
    end
endmodule




module image_processor (
    input  logic        clk,
    input  logic        reset,
    input  logic        oe,
    input  logic [11:0] camera_data,
    output logic [11:0] rgb_gray,
    output logic [11:0] color_pop_out,
    output logic [11:0] sobel_data,
    output logic [11:0] log_data,
    output logic [11:0] binary_noise_out,
    output logic        binary_filtered,
    output logic        dense_pixel
);

    logic [8:0] hue_value;
    logic [7:0] sat_value, val_out;
    logic        binary_raw;

    logic [11:0] window_gray            [0:2][0:2];
    logic        window_raw             [0:2][0:2];
    logic        window_filtered        [0:2][0:2];

    logic [ 8:0] binary_window_raw;
    logic [ 8:0] binary_window_filtered;
    logic [ 3:0] sum_filtered;

    // Shift registers
    shift_reg_3x3 #(
        .WIDTH(12)
    ) shift_gray (
        .clk(clk),
        .reset(reset),
        .enable(oe),
        .data_in(camera_data),
        .window(window_gray)
    );

    shift_reg_3x3 #(
        .WIDTH(1)
    ) shift_raw (
        .clk(clk),
        .reset(reset),
        .enable(oe),
        .data_in(binary_raw),
        .window(window_raw)
    );

    shift_reg_3x3 #(
        .WIDTH(1)
    ) shift_filtered (
        .clk(clk),
        .reset(reset),
        .enable(oe),
        .data_in(binary_filtered),
        .window(window_filtered)
    );

    // Binary window flattening
    always_comb begin
        /*
        binary_window_raw = {
            window_raw[0][2],
            window_raw[0][1],
            window_raw[0][0],
            window_raw[1][2],
            window_raw[1][1],
            window_raw[1][0],
            window_raw[2][2],
            window_raw[2][1],
            window_raw[2][0]
        };
        */

        binary_window_filtered = {
            window_filtered[0][2],
            window_filtered[0][1],
            window_filtered[0][0],
            window_filtered[1][2],
            window_filtered[1][1],
            window_filtered[1][0],
            window_filtered[2][2],
            window_filtered[2][1],
            window_filtered[2][0]
        };

        sum_filtered = binary_window_filtered[0] + binary_window_filtered[1] + binary_window_filtered[2] +
                       binary_window_filtered[3] + binary_window_filtered[4] + binary_window_filtered[5] +
                       binary_window_filtered[6] + binary_window_filtered[7] + binary_window_filtered[8];

        dense_pixel = (sum_filtered >= 6);
    end


    // Grayscale conversion
    grayscale U_grayScale1 (
        .image_data(camera_data),
        .rgb_gray  (rgb_gray)
    );

    // HSV conversion
    rgb_to_hsv hsv_inst (
        .rgb_in (camera_data),
        .hue_out(hue_value),
        .sat_out(sat_value),
        .val_out(val_out)
    );

    // Red detection
    only_red color_highlight (
        .image_data  (camera_data),
        .hue_value   (hue_value),
        .sat_value   (sat_value),
        .val_value   (val_out),
        .rgb_out     (color_pop_out),
        .is_red_pixel(binary_raw)
    );

    // Noise reduction
    morph_opening #(
        .ERO_THRESHOLD(8)
    ) U_morph_opening (
        .clk       (clk),
        .reset     (reset),
        .enable    (oe),
        .binary_in (binary_raw),
        .binary_out(binary_filtered)
    );

    // Sobel filter
    sobel_filter U_sobel (
        .clk(clk),
        .reset(reset),
        .p0(window_gray[0][0]),
        .p1(window_gray[0][1]),
        .p2(window_gray[0][2]),
        .p3(window_gray[1][0]),
        .p5(window_gray[1][2]),
        .p6(window_gray[2][0]),
        .p7(window_gray[2][1]),
        .p8(window_gray[2][2]),
        .sobel_out(sobel_data)
    );


    // Binary visualization output
    assign binary_noise_out = binary_filtered ? 12'hFFF : camera_data;

endmodule





/////////////////////////////////////////////////////////////////

module erosion_filter_param #(
    parameter integer THRESHOLD = 9
)(
    input  logic [8:0] binary_window,
    output logic       binary_out
);
    logic [3:0] sum;

    always_comb begin
        sum = binary_window[0] + binary_window[1] + binary_window[2] +
              binary_window[3] + binary_window[4] + binary_window[5] +
              binary_window[6] + binary_window[7] + binary_window[8];

        binary_out = (sum >= THRESHOLD);
    end
endmodule



module dilation_filter (
    input  logic [8:0] binary_window,
    output logic       binary_out
);
    always_comb begin
        binary_out = |binary_window;
    end
endmodule


module morph_opening #(
    parameter integer ERO_THRESHOLD = 9
)(
    input  logic clk,
    input  logic reset,
    input  logic enable,
    input  logic binary_in,
    output logic binary_out
);

    // erosion stage
    logic [0:0] window_ero_2d [0:2][0:2]; 
    logic [8:0] window_ero_flat;
    logic       erosion_out;

    shift_reg_3x3 #(.WIDTH(1)) erosion_sr (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .data_in(binary_in),
        .window (window_ero_2d)
    );

    always_comb begin
        window_ero_flat = {
            window_ero_2d[0][2], window_ero_2d[0][1], window_ero_2d[0][0],
            window_ero_2d[1][2], window_ero_2d[1][1], window_ero_2d[1][0],
            window_ero_2d[2][2], window_ero_2d[2][1], window_ero_2d[2][0]
        };
    end

    erosion_filter_param #(.THRESHOLD(ERO_THRESHOLD)) erosion (
        .binary_window(window_ero_flat),
        .binary_out   (erosion_out)
    );

    // dilation stage
    logic [0:0] window_dil_2d [0:2][0:2];  
    logic [8:0] window_dil_flat;

    shift_reg_3x3 #(.WIDTH(1)) dilation_sr (
        .clk    (clk),
        .reset  (reset),
        .enable (enable),
        .data_in(erosion_out),
        .window (window_dil_2d)
    );

    always_comb begin
        window_dil_flat = {
            window_dil_2d[0][2], window_dil_2d[0][1], window_dil_2d[0][0],
            window_dil_2d[1][2], window_dil_2d[1][1], window_dil_2d[1][0],
            window_dil_2d[2][2], window_dil_2d[2][1], window_dil_2d[2][0]
        };
    end

    dilation_filter dilation (
        .binary_window(window_dil_flat),
        .binary_out   (binary_out)
    );
endmodule














////////////////////////////////////////////////////////////////////////


/*
module shift_reg_3x3 #(
    parameter WIDTH = 1
) (
    input  logic             clk,
    input  logic             reset,
    input  logic             enable,
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] window [0:2][0:2]
);
    logic [WIDTH-1:0] shift[0:2][0:2];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 3; i++)
                for (int j = 0; j < 3; j++) shift[i][j] <= '0;
        end else if (enable) begin
            shift[2]    <= shift[1];
            shift[1]    <= shift[0];
            shift[0][2] <= shift[0][1];
            shift[0][1] <= shift[0][0];
            shift[0][0] <= data_in;
        end
    end

    assign window = shift;
endmodule
*/
module rgb_to_hsv (
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

        if (delta == 0) begin
            hue_calc = 0;
        end else if (max_rgb == r) begin
            hue_calc = (((SCALE * (g - b)) / delta) >> 4);
        end else if (max_rgb == g) begin
            hue_calc = ((((SCALE * (b - r)) / delta) >> 4) + 120);
        end else begin
            hue_calc = ((((SCALE * (r - g)) / delta) >> 4) + 240);
        end

        if (hue_calc < 0) hue_calc = hue_calc + 360;
        hue_calc = hue_calc % 360;
        hue_out  = hue_calc[8:0];

        if (max_rgb == 0) begin
            s_calc = 0;
        end else begin
            s_calc = (delta << 8) / max_rgb;
        end
        sat_out = (s_calc > 255) ? 255 : s_calc;

        val_out = {max_rgb, 4'b0};
    end
endmodule




//-----------------------------------------------------

module only_red (
    input  logic [11:0] image_data,
    input  logic [ 8:0] hue_value,
    input  logic [ 7:0] sat_value,
    input  logic [ 7:0] val_value,
    output logic [11:0] rgb_out,
    output logic        is_red_pixel  // 추가: 빨간 픽셀 여부 출력
);

    logic [11:0] rgb_gray;

    grayscale gray_module (
        .image_data(image_data),
        .rgb_gray  (rgb_gray)
    );

    always_comb begin
        if (((hue_value >= 355) || (hue_value <= 10)) && (sat_value >= 100) && (val_value >= 70)) begin
            rgb_out = image_data;
            is_red_pixel = 1'b1;
        end else begin
            rgb_out = rgb_gray;
            is_red_pixel = 1'b0;
        end
    end
endmodule

module noise_reduction (
    input  logic [8:0] binary_window,  // 3x3 이진화 윈도우
    output logic       binary_out      // 노이즈 제거된 출력
);
    logic [3:0] sum;

    always_comb begin
        sum = binary_window[0] + binary_window[1] + binary_window[2] +
              binary_window[3] + binary_window[4] + binary_window[5] +
              binary_window[6] + binary_window[7] + binary_window[8];

        binary_out = (sum >= 6) ? binary_window[4] : 1'b0;  // 중심 픽셀 기준
    end
endmodule

//-----------------------------------------------------



//-----------------------------------------------------

/*
module sobel_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] p0,
    p1,
    p2,
    input  logic [11:0] p3,
    p5,
    input  logic [11:0] p6,
    p7,
    p8,
    output logic [11:0] sobel_out
);

    // Stage 1: gx, gy 계산
    logic signed [13:0] gx_stage1, gy_stage1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            gx_stage1 <= 14'd0;
            gy_stage1 <= 14'd0;
        end else begin
            gx_stage1 <= ((p2[11:8] - p0[11:8]) + 2*(p5[11:8] - p3[11:8]) + (p8[11:8] - p6[11:8])) + 
                         ((p2[7:4]  - p0[7:4])  + 2*(p5[7:4]  - p3[7:4])  + (p8[7:4]  - p6[7:4])) + 
                         ((p2[3:0]  - p0[3:0])  + 2*(p5[3:0]  - p3[3:0])  + (p8[3:0]  - p6[3:0]));

            gy_stage1 <= ((p0[11:8] - p6[11:8]) + 2*(p1[11:8] - p7[11:8]) + (p2[11:8] - p8[11:8])) + 
                         ((p0[7:4]  - p6[7:4])  + 2*(p1[7:4]  - p7[7:4])  + (p2[7:4]  - p8[7:4])) + 
                         ((p0[3:0]  - p6[3:0])  + 2*(p1[3:0]  - p7[3:0])  + (p2[3:0]  - p8[3:0]));
        end
    end

    // Stage 2: abs(gx), abs(gy), sum
    logic [13:0] abs_gx, abs_gy, sum_stage2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            abs_gx     <= 14'd0;
            abs_gy     <= 14'd0;
            sum_stage2 <= 14'd0;
        end else begin
            abs_gx     <= (gx_stage1 < 0) ? -gx_stage1 : gx_stage1;
            abs_gy     <= (gy_stage1 < 0) ? -gy_stage1 : gy_stage1;
            sum_stage2 <= abs_gx + abs_gy;
        end
    end

    // Stage 3: Threshold 비교 및 출력
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sobel_out <= 12'd0;
        end else begin
            sobel_out <= (sum_stage2 > 14'd30) ? 12'h0F0 : 12'd0;  // 초록색 엣지
        end
    end

endmodule
*/



//-----------------------------------------------------




module log_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] p0,
    p1,
    p2,
    input  logic [11:0] p3,
    p5,
    input  logic [11:0] p6,
    p7,
    p8,
    output logic [11:0] log_out
);
    logic signed [13:0] r, g, b;
    logic signed [13:0] abs_r, abs_g, abs_b;
    logic [13:0] sum;

    always_comb begin
        // R 채널
        r = -p0[11:8] - p1[11:8] - p2[11:8]
            -p3[11:8] + (8 * p5[11:8])
            -p6[11:8] - p7[11:8] - p8[11:8];

        // G 채널
        g = -p0[7:4] - p1[7:4] - p2[7:4]
            -p3[7:4] + (8 * p5[7:4])
            -p6[7:4] - p7[7:4] - p8[7:4];

        // B 채널
        b = -p0[3:0] - p1[3:0] - p2[3:0]
            -p3[3:0] + (8 * p5[3:0])
            -p6[3:0] - p7[3:0] - p8[3:0];
    end

    assign abs_r = (r < 0) ? -r : r;
    assign abs_g = (g < 0) ? -g : g;
    assign abs_b = (b < 0) ? -b : b;

    assign sum   = (abs_r + abs_g + abs_b) / 3;  // Grayscale 평균

    always_ff @(posedge clk or posedge reset) begin
        if (reset) log_out <= 12'd0;
        else if (sum > 255)
            log_out <= {4'hF, 4'hF, 4'hF};  // 최대값 클램핑
        else log_out <= {sum[7:4], sum[7:4], sum[7:4]};  // RGB444 Grayscale
    end
endmodule




