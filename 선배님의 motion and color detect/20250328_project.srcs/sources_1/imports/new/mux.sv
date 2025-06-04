`timescale 1ns / 1ps

module mux (
    input  logic [ 5:0] sel,
    input  logic [11:0] inData0,
    input  logic [11:0] inData1,
    input  logic [11:0] inData2,
    input  logic [11:0] inData3,
    input  logic [11:0] inData4,
    input  logic [11:0] inData5,
    input  logic [11:0] inData6,
    output logic [11:0] outData
);

    always_comb begin
        case (sel)
            6'b000000: outData = inData0;
            6'b000001: outData = inData1;
            6'b000011: outData = inData2;
            6'b000111: outData = inData3;
            6'b001111: outData = inData4;
            6'b011111: outData = inData5;
            6'b111111: outData = inData6;
            default:  outData = 12'b0;
        endcase
    end
endmodule
