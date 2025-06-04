`timescale 1ns / 1ps

module TOP_SCCB (
    input  logic clk,
    input  logic reset,
    input  logic btn,
    output logic scl,
    output logic sda
);
    logic [ 7:0] rom_addr;
    logic [15:0] rom_data;

    qqvga_config_rom U_SCCB_ROM (
        .clk (clk),
        .addr(rom_addr),
        .dout(rom_data)
    );

    SCCB U_SCCB (
        .clk     (clk),
        .reset   (reset),
        .btn     (btn),
        .rom_data(rom_data),
        .rom_addr(rom_addr),
        .scl     (scl),
        .sda     (sda)
    );

endmodule

module SCCB (
    input  logic        clk,
    input  logic        reset,
    input  logic        btn,
    input  logic [15:0] rom_data,
    output logic [ 7:0] rom_addr,
    output logic        scl,
    output logic        sda
);

    logic tick_200KHz;  // 5ns scl half
    logic tick_100KHz, tick_400KHz;
    logic [1:0] tick_count, tick_count_next;
    logic [13:0] count_ns, count_ns_next;
    logic [3:0] bit_count, bit_count_next;
    logic temp_data;
    logic [7:0] rom_addr_reg, rom_addr_next;
    logic en_100KHz, en_200KHz, en_400KHz;
    logic w_btn;
    logic [7:0] id_addr;

    assign rom_addr = rom_addr_reg;

    typedef enum {
        IDLE,
        START,
        ADDR,
        ACK1,
        REG_ADDR,
        ACK2,
        DATA,
        ACK3,
        STOP
    } sccb_state_e;

    sccb_state_e state, state_next;

    always_ff @(posedge clk, posedge reset) begin : scl_100KHz
        if (reset) begin
            scl <= 1'b1;
            id_addr <= 8'h42;
        end else begin
            id_addr <= 8'h42;
            if (state == IDLE || state == START) begin
                scl <= 1'b1;
            end else if (state == ADDR && count_ns == 0) begin
                scl <= 0;
            end else if (state == STOP && count_ns == 1000) begin
                scl <= 1;
            end else begin
                if (tick_200KHz) begin
                    scl <= ~scl;
                end
            end
        end
    end


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            tick_count   <= 0;
            bit_count    <= 0;
            count_ns     <= 0;
            rom_addr_reg <= 0;
        end else begin
            state        <= state_next;
            tick_count   <= tick_count_next;
            bit_count    <= bit_count_next;
            count_ns     <= count_ns_next;
            rom_addr_reg <= rom_addr_next;
        end
    end

    always_comb begin
        state_next = state;
        tick_count_next = tick_count;
        bit_count_next = bit_count;
        count_ns_next = count_ns;
        rom_addr_next = rom_addr_reg;
        en_100KHz = 0;
        en_200KHz = 0;
        en_400KHz = 0;

        case (state)
            IDLE: begin
                sda = 1'b1;
                rom_addr_next = 0;
                count_ns_next = 0;
                if (btn) begin
                    state_next = START;
                    count_ns_next = 0;
                end
            end
            START: begin
                sda = 1'b0;
                count_ns_next = count_ns + 1;
                if (count_ns >= 1000) begin
                    state_next = ADDR;
                    count_ns_next = 0;
                    temp_data = 0;
                end
            end
            ADDR: begin
                count_ns_next = count_ns + 1;
                en_100KHz = 1;
                en_200KHz = 1;
                en_400KHz = 1;
                if (tick_400KHz) begin
                    tick_count_next = tick_count + 1;
                end
                if (tick_count == 0) begin
                    if (tick_400KHz) begin
                        sda = id_addr[7-bit_count];
                    end
                end
                if (tick_100KHz) begin
                    bit_count_next = bit_count + 1;
                end
                if (bit_count == 7 && tick_100KHz) begin
                    state_next = ACK1;
                    count_ns_next = 0;
                    bit_count_next = 0;
                    temp_data = 0;
                    sda = 0;
                    tick_count_next = 0;
                end
            end
            ACK1: begin
                en_200KHz = 1;
                en_100KHz = 1;
                if (tick_100KHz) begin
                    state_next = REG_ADDR;
                    tick_count_next = 0;
                    en_400KHz = 0;
                end
            end
            REG_ADDR: begin
                en_100KHz = 1;
                en_200KHz = 1;
                en_400KHz = 1;
                if (tick_400KHz) begin
                    tick_count_next = tick_count + 1;
                end
                if (tick_count == 0) begin
                    if (tick_400KHz) begin
                        sda = rom_data[15-bit_count];
                    end
                end
                if (tick_100KHz) begin
                    bit_count_next = bit_count + 1;
                end
                if (bit_count == 7 && tick_100KHz) begin
                    state_next = ACK2;
                    bit_count_next = 0;
                    temp_data = 0;
                    sda = 0;
                    tick_count_next = 0;
                end
            end
            ACK2: begin
                en_200KHz = 1;
                en_100KHz = 1;
                if (tick_100KHz) begin
                    state_next = DATA;
                    tick_count_next = 0;
                end
            end
            DATA: begin
                en_100KHz = 1;
                en_200KHz = 1;
                en_400KHz = 1;
                if (tick_400KHz) begin
                    tick_count_next = tick_count + 1;
                end
                if (tick_count == 0) begin
                    if (tick_400KHz) begin
                        sda = rom_data[7-bit_count];
                    end
                end

                if (tick_100KHz) begin
                    bit_count_next = bit_count + 1;
                end

                if (bit_count == 7 && tick_100KHz) begin
                    state_next = ACK3;
                    bit_count_next = 0;
                    temp_data = 0;
                    sda = 0;
                    tick_count_next = 0;
                end
            end
            ACK3: begin
                en_200KHz = 1;
                en_100KHz = 1;
                if (tick_100KHz) begin
                    rom_addr_next = rom_addr_reg + 1;
                    state_next = STOP;
                    tick_count_next = 0;
                    count_ns_next = 0;
                    en_200KHz = 0;
                end
            end
            STOP: begin
                count_ns_next = count_ns + 1;
                en_200KHz = 0;
                en_100KHz = 1;
                if (count_ns >= 2000) begin
                    sda = 1;
                end
                if (count_ns >= 5000) begin
                    if (rom_addr_reg < 75) begin
                        state_next = START;
                        count_ns_next = 0;
                    end else begin
                        state_next = IDLE;
                        count_ns_next = 0;
                    end
                end
            end
        endcase
    end

    clk_div_para #(
        .CLK_DIV(100_000_000 / 200_000),
        .r_cnt  (9)
    ) U_clk_200KHz (
        .clk         (clk),
        .reset       (reset),
        .en          (en_200KHz),
        .tick_para_hz(tick_200KHz)
    );

    clk_div_para #(
        .CLK_DIV(100_000_000 / 100_000),
        .r_cnt  (9)
    ) U_clk_100KHz (
        .clk         (clk),
        .reset       (reset),
        .en          (en_100KHz),
        .tick_para_hz(tick_100KHz)
    );
    clk_div_para #(
        .CLK_DIV(100_000_000 / 400_000),
        .r_cnt  (7)
    ) U_clk_400KHz (
        .clk         (clk),
        .reset       (reset),
        .en          (en_400KHz),
        .tick_para_hz(tick_400KHz)
    );

endmodule

module qqvga_config_rom (
    input  logic        clk,
    input  logic [ 7:0] addr,
    output logic [15:0] dout
);

    //FFFF is end of rom, FFF0 is delay
    always @(posedge clk) begin
        case (addr)
            0: dout <= 16'h12_80;  //reset
            1: dout <= 16'hFF_F0;  //delay
            2: dout <= 16'h12_14;  // COM7,     set RGB color output
            3: dout <= 16'h11_80;  // CLKRC     internal PLL matches input clock
            4: dout <= 16'h0C_00;  // COM3,     default settings
            5: dout <= 16'h3E_00;  // COM14,    no scaling, normal pclock
            6: dout <= 16'h04_00;  // COM1,     disable CCIR656
            7: dout <= 16'h40_d0;  //COM15,     RGB565, full output range
            8: dout <= 16'h3a_04;  //TSLB       
            9: dout <= 16'h14_18;  //COM9       MAX AGC value x4
            10: dout <= 16'h4F_B3;  //MTX1       
            11: dout <= 16'h50_B3;  //MTX2
            12: dout <= 16'h51_00;  //MTX3
            13: dout <= 16'h52_3d;  //MTX4
            14: dout <= 16'h53_A7;  //MTX5
            15: dout <= 16'h54_E4;  //MTX6
            16: dout <= 16'h58_9E;  //MTXS
            17:
            dout <= 16'h3D_C0; //COM13      sets gamma enable, does not preserve reserved bits, may be wrong?
            18: dout <= 16'h17_16;  //HSTART     start high 8 bits
            19:
            dout <= 16'h18_04; //HSTOP      stop high 8 bits //these kill the odd colored line
            20: dout <= 16'h32_9A;  //91  //HREF       edge offset
            21: dout <= 16'h19_02;  //VSTART     start high 8 bits
            22: dout <= 16'h1A_7A;  //VSTOP      stop high 8 bits
            23: dout <= 16'h03_00;  // 00 //VREF       vsync edge offset
            24: dout <= 16'h0F_41;  //COM6       reset timings
            25:
            dout <= 16'h1E_00; //MVFP       disable mirror / flip //might have magic value of 03
            26: dout <= 16'h33_0B;  //CHLF       //magic value from the internet
            27: dout <= 16'h3C_78;  //COM12      no HREF when VSYNC low
            28: dout <= 16'h69_00;  //GFIX       fix gain control
            29: dout <= 16'h74_00;  //REG74      Digital gain control
            30:
            dout <= 16'hB0_84; //RSVD       magic value from the internet *required* for good color
            31: dout <= 16'hB1_0c;  //ABLC1
            32: dout <= 16'hB2_0e;  //RSVD       more magic internet values
            33: dout <= 16'hB3_80;  //THL_ST
            //begin mystery scaling numbers
            34: dout <= 16'h70_3a;
            35: dout <= 16'h71_35;
            36: dout <= 16'h72_21;
            37: dout <= 16'h73_f0;
            38: dout <= 16'ha2_02;
            //gamma curve values
            39: dout <= 16'h7a_20;
            40: dout <= 16'h7b_10;
            41: dout <= 16'h7c_1e;
            42: dout <= 16'h7d_35;
            43: dout <= 16'h7e_5a;
            44: dout <= 16'h7f_69;
            45: dout <= 16'h80_76;
            46: dout <= 16'h81_80;
            47: dout <= 16'h82_88;
            48: dout <= 16'h83_8f;
            49: dout <= 16'h84_96;
            50: dout <= 16'h85_a3;
            51: dout <= 16'h86_af;
            52: dout <= 16'h87_c4;
            53: dout <= 16'h88_d7;
            54: dout <= 16'h89_e8;
            //AGC and AEC
            55: dout <= 16'h13_e0;  //COM8, disable AGC / AEC
            56: dout <= 16'h00_00;  //set gain reg to 0 for AGC
            57: dout <= 16'h10_00;  //set ARCJ reg to 0
            58: dout <= 16'h0d_40;  //magic reserved bit for COM4
            59: dout <= 16'h14_18;  //COM9, 4x gain + magic bit
            60: dout <= 16'ha5_05;  // BD50MAX
            61: dout <= 16'hab_07;  //DB60MAX
            62: dout <= 16'h24_95;  //AGC upper limit
            63: dout <= 16'h25_33;  //AGC lower limit
            64: dout <= 16'h26_e3;  //AGC/AEC fast mode op region
            65: dout <= 16'h9f_78;  //HAECC1
            66: dout <= 16'ha0_68;  //HAECC2
            67: dout <= 16'ha1_03;  //magic
            68: dout <= 16'ha6_d8;  //HAECC3
            69: dout <= 16'ha7_d8;  //HAECC4
            70: dout <= 16'ha8_f0;  //HAECC5
            71: dout <= 16'ha9_90;  //HAECC6
            72: dout <= 16'haa_94;  //HAECC7
            73: dout <= 16'h13_e7;  //COM8, enable AGC / AEC
            74: dout <= 16'h69_07;
            default: dout <= 16'hFF_FF;  //mark end of ROM
        endcase
    end
endmodule

module clk_div_para #(
    parameter CLK_DIV = 24_999_999,
    parameter r_cnt   = 13
) (
    input  logic clk,
    input  logic reset,
    input  logic en,
    output logic tick_para_hz
);

    logic [r_cnt:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter    <= 0;
            tick_para_hz <= 0;
        end else begin
            if (en) begin
                if (r_counter == CLK_DIV - 1) begin
                    r_counter    <= 0;
                    tick_para_hz <= 1;
                end else begin
                    r_counter    <= r_counter + 1;
                    tick_para_hz <= 0;
                end
            end else begin
                r_counter <= 0;
                tick_para_hz <= 0;
            end
        end
    end
endmodule

module button_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);

    reg [3:0] r_debounce;
    reg r_dff;
    wire w_debounce;
    reg [$clog2(100_000)-1 : 0] r_counter;
    reg r_debounce_clk;
    // for debounce clock div 100M -> 1Khz

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            if (r_counter == 100_000) begin
                r_counter <= 0;
                r_debounce_clk <= 1;
            end else begin
                r_counter = r_counter + 1;
                r_debounce_clk <= 0;
            end
        end
    end

    // debounce logic
    always @(posedge r_debounce_clk, posedge reset) begin
        if (reset) begin
            r_debounce <= 0;
        end else begin
            r_debounce <= {i_btn, r_debounce[3:1]};  // shift
        end
    end

    assign w_debounce = &r_debounce;  // debounce success (and)

    // find edge
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_dff <= 1'b0;
        end else begin
            r_dff <= w_debounce;
        end
    end

    assign o_btn = w_debounce & ~r_dff;

endmodule
