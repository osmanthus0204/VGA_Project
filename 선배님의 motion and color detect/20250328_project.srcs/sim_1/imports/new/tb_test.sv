`timescale 1ns / 1ps

module tb_test ();

    logic       clk;
    logic       reset;
    logic       pclk;
    logic       xclk;
    logic [7:0] cam_data;
    logic       cam_href;
    logic       cam_v_sync;
    logic       h_sync;
    logic       v_sync;
    logic [3:0] red_port;
    logic [3:0] grn_port;
    logic [3:0] blu_port;
    logic [5:0] sw;
    logic       start;
    logic       scl;
    logic       sda;
    logic [1:0] monitor_sel;

    Camera_OV7670 U_Camera_OV7670 (.*);

    always #5 clk = ~clk;

    initial begin
        #00 clk = 0;
        reset = 1;
        pclk = 0;
        cam_data = 0;
        cam_href = 0;
        cam_v_sync = 0;
        sw = 0;
        start = 0;
        #10 reset = 0;
        #345 start = 1;
        #20 start = 0;
        #100 $finish;
    end
endmodule
