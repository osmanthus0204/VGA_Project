`timescale 1ns / 1ps

module shift_reg_3x3 #(
    parameter WIDTH = 1
)(
    input  logic              clk,
    input  logic              reset,
    input  logic              enable,
    input  logic [WIDTH-1:0]  data_in,
    output logic [WIDTH-1:0]  window[0:2][0:2]
);
    logic [WIDTH-1:0] shift[0:2][0:2];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 3; i++)
                for (int j = 0; j < 3; j++)
                    shift[i][j] <= '0;
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