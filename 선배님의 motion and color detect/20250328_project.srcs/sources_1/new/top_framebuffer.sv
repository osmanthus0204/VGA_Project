`timescale 1ns / 1ps

module top_framebuffer (
    input  logic        pclk,
    input  logic        select,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [11:0] wData,
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr0,
    input  logic [16:0] rAddr1,
    input  logic [16:0] rAddr2,
    input  logic [16:0] rAddr3,
    output logic [11:0] rData0,
    output logic [11:0] rData1,
    output logic [11:0] rData2,
    output logic [11:0] rData3
);
    logic we0, we1;
    logic [11:0] rData00, rData01, rData02, rData03;
    logic [11:0] rData10, rData11, rData12, rData13;

    always_comb begin
        if (select == 0) begin
            we0 = we;
            we1 = 1'b0;

            rData0 = rData00;
            rData1 = rData01;
            rData2 = rData02;
            rData3 = rData03;
        end else begin
            we0 = 1'b0;
            we1 = we;

            rData0 = rData10;
            rData1 = rData11;
            rData2 = rData12;
            rData3 = rData13;
        end
    end

    frameBuffer U_frameBuffer0 (
        .wclk  (pclk),
        .we    (we0),
        .wAddr (wAddr),
        .wData (wData),
        .rclk  (rclk),
        .oe    (oe),
        .rAddr0(rAddr0),
        .rAddr1(rAddr1),
        .rAddr2(rAddr2),
        .rAddr3(rAddr3),
        .rData0(rData00),
        .rData1(rData01),
        .rData2(rData02),
        .rData3(rData03)
    );

    frameBuffer U_frameBuffer1 (
        .wclk  (pclk),
        .we    (we1),
        .wAddr (wAddr),
        .wData (wData),
        .rclk  (rclk),
        .oe    (oe),
        .rAddr0(rAddr0),
        .rAddr1(rAddr1),
        .rAddr2(rAddr2),
        .rAddr3(rAddr3),
        .rData0(rData10),
        .rData1(rData11),
        .rData2(rData12),
        .rData3(rData13)
    );
endmodule

module frameBuffer (
    //write side
    input  logic        wclk,
    input  logic        we,
    input  logic [16:0] wAddr,
    input  logic [11:0] wData,
    //read side
    input  logic        rclk,
    input  logic        oe,
    input  logic [16:0] rAddr0,
    input  logic [16:0] rAddr1,
    input  logic [16:0] rAddr2,
    input  logic [16:0] rAddr3,
    output logic [11:0] rData0,
    output logic [11:0] rData1,
    output logic [11:0] rData2,
    output logic [11:0] rData3
);

    logic [11:0] mem[0:(160*120)-1];

    //write side
    always_ff @(posedge wclk) begin
        if (we) begin
            mem[wAddr] <= wData;
        end
    end

    always_ff @(posedge rclk) begin
        if (oe) begin
            rData0 <= mem[rAddr0];
            rData1 <= mem[rAddr1];
            rData2 <= mem[rAddr2];
            rData3 <= mem[rAddr3];
        end
    end

endmodule
