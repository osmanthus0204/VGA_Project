`timescale 1ns / 1ps

module ISP(
    input logic       clk,
    input logic       xclk,
    input logic       reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [7:0] filter_sel,
    output logic rclk,
    output logic [16:0] rAddr,
    input logic [15:0] rData,

    //수정
    output logic [11:0] filtered_data
    );
    localparam 
        RED_FILTER       = 8'b00000_001,
        GREEN_FILTER     = 8'b00000_010,
        BLUE_FILTER      = 8'b00000_100,
        GRAY_FILTER      = 8'b00001_000,
        REVERSE_FILTER   = 8'b00010_000,
        CHROMA_FILTER    = 8'b00100_000,
        GAUSSIAN_FILTER  = 8'b01000_000,
        SOBEL_FILTER     = 8'b10000_000;
    logic [11:0] gray_value;
    logic [11:0] original_color, filtered_color, chroma_key_color,gaussian_color;
    logic [15:0] background_pixel;
    logic [16:0] bg_rAddr;
    logic [11:0] edge_val;
    assign rclk = clk;
    assign original_color = {rData[15:12], rData[10:7], rData[4:1]}; // RGB 12-bit color



    always_comb begin 
        filtered_color = original_color;
        case (filter_sel)
            RED_FILTER: filtered_color = original_color & 12'b1111_0000_0000; 
            GREEN_FILTER: filtered_color = original_color & 12'b0000_1111_0000;
            BLUE_FILTER: filtered_color = original_color & 12'b0000_0000_1111; 
            GRAY_FILTER: begin
                gray_value = (77*original_color[11:8] + 155*original_color[7:4] + 29*original_color[3:0]);
                filtered_color = {gray_value[11:8], gray_value[11:8], gray_value[11:8]};
            end
            REVERSE_FILTER: filtered_color = ~original_color;
            CHROMA_FILTER : filtered_color = chroma_key_color;
            GAUSSIAN_FILTER: filtered_color = gaussian_color;
            SOBEL_FILTER  : filtered_color = edge_val;
            default: filtered_color = original_color; 
        endcase
    end

    always_comb begin
            bg_rAddr = ((y_pixel >> 1) * 160 + (x_pixel >> 1));
            rAddr = ((y_pixel) * 320 + (x_pixel));
    end

    chromakey U_Chromakey(
        .pixel_in(original_color),
        .background_pixel({background_pixel[15:12], background_pixel[10:7],background_pixel[4:1]}),
        .pixel_out(chroma_key_color)
    );

    background_rom U_BACK_ROM(
        .rAddr(bg_rAddr),
        .rData(background_pixel)
    );
    gaussian U_GAUSSIAN(
        .clk(xclk),
        .reset(reset),
        .addr(rAddr),
        .p_red_port(original_color[11:8]),
        .p_green_port(original_color[7:4]),
        .p_blue_port(original_color[3:0]),
        .red_port(gaussian_color[11:8]),
        .green_port(gaussian_color[7:4]),
        .blue_port(gaussian_color[3:0])
);
sobel_filter U_SOBEL_FILTER(
    .clk(xclk),
    .reset(reset),
    .rAddr(rAddr),
    .original_color(original_color),
    .edge_out(edge_val)
);
    assign filtered_data = filtered_color;


endmodule

module chromakey (
    input  logic [11:0] pixel_in,
    input  logic [11:0] background_pixel,
    output logic [11:0] pixel_out
);
    localparam margin = 1;
    logic [3:0] r, g, b;
    assign r = pixel_in[11:8];
    assign g = pixel_in[7:4];
    assign b = pixel_in[3:0];

    logic is_green;
    assign is_green = (g > (r)) && (g > (b)) && (g >= 4'b0101);



    assign pixel_out = (is_green) ? background_pixel : pixel_in;
endmodule

module background_rom(
    input [16:0] rAddr,  
    output [15:0] rData
);
    logic [15:0] mem [0:160*120 - 1]; // Define memory size based on your requirements
    initial begin
        $readmemh("background.mem", mem);
    end

    assign rData = mem[rAddr];
endmodule

module gaussian (
    input  logic       clk,
    input  logic       reset,
    input  logic [16:0] addr,
    input  logic [3:0] p_red_port,
    input  logic [3:0] p_green_port,
    input  logic [3:0] p_blue_port,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port
);
    logic [11:0] line_buffer[2:0][319:0];

    logic [8:0] row, col;
    assign row = addr / 320;
    assign col = addr % 320;

    logic [11:0] pixel;
    logic [11:0] pixel_cal[2:0][2:0];
    logic pixel_valid;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++) begin
                for (int j = 0; j < 320; j++) begin
                    line_buffer[i][j] <= 0;
                end
            end
        end else begin
            line_buffer[0][col] <= pixel;
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[2][col] <= line_buffer[1][col];
        end
    end

    always_ff @(posedge clk) begin
        pixel_cal[0][0] <= (row == 0 || col == 0)? 0 : line_buffer[2][col-1];
        pixel_cal[0][1] <= (row == 0)? 0 : line_buffer[2][col];
        pixel_cal[0][2] <= (row == 0 || col == 319) ? 0 : line_buffer[2][col+1];

        pixel_cal[1][0] <= (col == 0)? 0 : line_buffer[1][col-1];
        pixel_cal[1][1] <= line_buffer[1][col];
        pixel_cal[1][2] <= (col == 319)? 0 :line_buffer[1][col+1];

        pixel_cal[2][0] <= (col == 0)? 0 : line_buffer[0][col-1];
        pixel_cal[2][1] <= line_buffer[0][col];
        pixel_cal[2][2] <= (col == 319)? 0 : line_buffer[0][col+1];
    end

    always_comb begin
        pixel = {p_red_port, p_green_port, p_blue_port};
        pixel_valid = (row >= 1 && row < 238) && (col >= 1 && col < 318);
        if (pixel_valid) begin 
            red_port = ( (pixel_cal[0][0][11:8] + pixel_cal[0][2][11:8] + pixel_cal[2][0][11:8] + pixel_cal[2][2][11:8]) +
                            ((pixel_cal[0][1][11:8] + pixel_cal[1][0][11:8] + pixel_cal[1][2][11:8] + pixel_cal[2][1][11:8]) *4) +
                            ((pixel_cal[1][1][11:8]) * 16) )/36;

            green_port = ( (pixel_cal[0][0][7:4] + pixel_cal[0][2][7:4] + pixel_cal[2][0][7:4] + pixel_cal[2][2][7:4]) +
                            ((pixel_cal[0][1][7:4] + pixel_cal[1][0][7:4] + pixel_cal[1][2][7:4] + pixel_cal[2][1][7:4]) *4) +
                            ((pixel_cal[1][1][7:4]) * 16) )/36;

            blue_port = ( (pixel_cal[0][0][3:0] + pixel_cal[0][2][3:0] + pixel_cal[2][0][3:0] + pixel_cal[2][2][3:0]) +
                            ((pixel_cal[0][1][3:0] + pixel_cal[1][0][3:0] + pixel_cal[1][2][3:0] + pixel_cal[2][1][3:0]) *4) +
                            ((pixel_cal[1][1][3:0]) * 16) )/36;
         end else begin 
             red_port = 0; 
             green_port = 0; 
             blue_port = 0; 
         end 
    end
endmodule

module sobel_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [16:0] rAddr,

    input  logic [ 11:0] original_color,
    output logic [ 11:0] edge_out
);
    logic [3:0] line_buffer[2:0][319:0];
    logic [3:0] p[0:8];
    logic [8:0] row, col;
    logic [11:0] gray;
    assign row = rAddr / 160;
    assign col = rAddr % 160;


    // 라인버퍼
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < 3; i++)begin
                for (int j = 0; j < 160; j++) begin
                    line_buffer[i][j] <= 0;
                end 
            end
        end else begin        //end else if (DE && (col<320) && (row<240)) begin
            line_buffer[2][col] <= line_buffer[1][col];
            line_buffer[1][col] <= line_buffer[0][col];
            line_buffer[0][col] <= gray[11:8];
        end
    end

    // 3x3 윈도우
    always_ff @(posedge clk) begin
        // 윈도우의 위쪽 행 (line_buffer[2])
            p[0] <= (row == 0 || col == 0) ? 0 : line_buffer[2][col-1];
            p[1] <= (row == 0) ? 0 : line_buffer[2][col];
            p[2] <= (row == 0 || col == 159) ? 0 : line_buffer[2][col+1];
            // 윈도우의 중간 행 (line_buffer[1])
            p[3] <= (col == 0) ? 0 : line_buffer[1][col-1];
            p[4] <= line_buffer[1][col];
            p[5] <= (col == 159) ? 0 : line_buffer[1][col+1];
            // 윈도우의 아래쪽 행 (line_buffer[0])
            p[6] <= (col == 0 || row == 119) ? 0 : line_buffer[0][col-1];
            p[7] <= (row == 119) ? 0 : line_buffer[0][col];
            p[8] <= (col == 159 || row == 119) ? 0 : line_buffer[0][col+1];
    end

    // gx, gy 연산
    logic signed [6:0] gx, gy;
    logic [6:0] abs_gx, abs_gy;
    logic [7:0] sum;

    always_comb begin
        gray =(77*original_color[11:8] + 155*original_color[7:4] + 29*original_color[3:0]);

        gx = (p[2] + 2 * p[5] + p[8]) - (p[0] + 2 * p[3] + p[6]);
        gy = (p[6] + 2 * p[7] + p[8]) - (p[0] + 2 * p[1] + p[2]);

        abs_gx = (gx < 0) ? -gx : gx;
        abs_gy = (gy < 0) ? -gy : gy;

        sum = {abs_gx + abs_gy};

    if (sum > 9)
        edge_out = 12'hFFF; 
    else
        edge_out = 12'h000; 
end
endmodule

