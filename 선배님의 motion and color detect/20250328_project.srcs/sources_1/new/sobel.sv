`timescale 1ns / 1ps

module sobel_filter (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] p0,
    input  logic [11:0] p1,
    input  logic [11:0] p2,
    input  logic [11:0] p3,
    input  logic [11:0] p5,
    input  logic [11:0] p6,
    input  logic [11:0] p7,
    input  logic [11:0] p8,
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
            sobel_out <= (sum_stage2 > 14'd18) ? 12'h0F0 : 12'd0;  // 초록색 엣지
        end
    end

endmodule
