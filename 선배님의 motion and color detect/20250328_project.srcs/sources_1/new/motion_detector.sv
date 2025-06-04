`timescale 1ns / 1ps

module motion_detector (
    input  logic        clk,
    input  logic [11:0] pixel1,
    input  logic [11:0] pixel2,
    output logic        motion
);
    //77 150 29
    logic [11:0] gray_val1, gray_val2;
    logic [3:0] motion_data;

    always_ff @(posedge clk) begin
        gray_val1 <= (pixel1[11:8] * 77 +  pixel1[7:4] * 150 + pixel1[3:0] * 29)/256;
        gray_val2 <= (pixel2[11:8] * 77 +  pixel2[7:4] * 150 + pixel2[3:0] * 29)/256;
        motion_data <= gray_val1 >= gray_val2 ? (gray_val1-gray_val2) : (gray_val2-gray_val1);
        motion <= motion_data > 3 ? 1 : 0;
    end

endmodule
