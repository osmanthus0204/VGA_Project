`timescale 1ns / 1ps

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