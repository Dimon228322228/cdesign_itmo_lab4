`timescale 1ns / 1ps

module bist_top (
    input  wire        CLK,
    input  wire        RST_N,
    input  wire        KEY2_N,
    input  wire        KEY3_N,
    input  wire [16:0] GPIO_1_input_pullup,
    output wire [3:0]  LED,
    output wire [7:0]  SEG_DATA,
    output wire [7:0]  SEG_SEL,
    output wire [16:0] GPIO_1_out_zero_value
);

    localparam [7:0] LFSR1_TAPS = 8'h63;
    localparam [7:0] LFSR2_TAPS = 8'hC5;
    localparam [7:0] CRC_POLY   = 8'hA9;
    localparam [7:0] LFSR1_SEED = 8'hA5;
    localparam [7:0] LFSR2_SEED = 8'h5A;

    wire clk   = CLK;
    wire reset = ~RST_N;

    wire bist_press, norm_press;
    btn_sync u_key2 (
        .clk(clk), .reset(reset), .btn_n(KEY2_N), .press(bist_press)
    );
    btn_sync u_key3 (
        .clk(clk), .reset(reset), .btn_n(KEY3_N), .press(norm_press)
    );

    wire       bist_mode;
    wire       calc_start;
    wire       lfsr_en;
    wire       crc_clear;
    wire       crc_valid;
    wire [7:0] bist_count;
    wire [7:0] iter_count;

    wire [7:0] lfsr1_q, lfsr2_q;
    lfsr8 #(.TAPS(LFSR1_TAPS), .SEED(LFSR1_SEED)) u_lfsr1 (
        .clk(clk), .reset(reset), .en(lfsr_en), .q(lfsr1_q)
    );
    lfsr8 #(.TAPS(LFSR2_TAPS), .SEED(LFSR2_SEED)) u_lfsr2 (
        .clk(clk), .reset(reset), .en(lfsr_en), .q(lfsr2_q)
    );

    wire [7:0] a_gpio = GPIO_1_input_pullup[7:0];
    wire [7:0] b_gpio = GPIO_1_input_pullup[15:8];
    wire [7:0] a_in   = bist_mode ? lfsr1_q : a_gpio;
    wire [7:0] b_in   = bist_mode ? lfsr2_q : b_gpio;

    wire       busy_func;
    wire [4:0] y_func;
    func_calc u_dut (
        .clk(clk),
        .reset(reset),
        .start(calc_start),
        .a(a_in),
        .b(b_in),
        .busy(busy_func),
        .y(y_func)
    );

    bist_control u_bist (
        .clk(clk),
        .reset(reset),
        .bist_press(bist_press),
        .norm_press(norm_press),
        .busy_func(busy_func),
        .bist_mode(bist_mode),
        .calc_start(calc_start),
        .lfsr_en(lfsr_en),
        .crc_clear(crc_clear),
        .crc_valid(crc_valid),
        .bist_count(bist_count),
        .iter_count(iter_count)
    );

    wire [7:0] crc_out;
    crc8 #(.POLY(CRC_POLY)) u_crc (
        .clk(clk),
        .reset(reset),
        .clear(crc_clear),
        .valid(crc_valid),
        .data_in({3'b0, y_func}),
        .crc_out(crc_out)
    );

    reg        seg_start;
    reg [15:0] disp_value;
    reg        busy_d;
    reg        was_bist;
    wire       busy_seg;

    always @(posedge clk) begin
        if (reset) begin
            seg_start  <= 1'b0;
            disp_value <= 16'd0;
            busy_d     <= 1'b0;
            was_bist   <= 1'b0;
        end else begin
            busy_d    <= busy_func;
            was_bist  <= bist_mode;
            seg_start <= 1'b0;

            if (bist_mode) begin
                disp_value <= {bist_count, crc_out};
            end else if (busy_d && !busy_func) begin
                disp_value <= {11'd0, y_func};
                seg_start  <= 1'b1;
            end

            if (was_bist && !bist_mode) begin
                disp_value <= {bist_count, crc_out};
                seg_start  <= 1'b1;
            end
        end
    end

    hex_to_7seg_dynamic #(
        .REFRESH_DIV(100_000),
        .PASSES(8)
    ) u_disp (
        .clk(clk),
        .reset(reset),
        .start(seg_start),
        .value(disp_value),
        .busy(busy_seg),
        .SEG_DATA(SEG_DATA),
        .SEG_SEL(SEG_SEL)
    );

    assign LED[0] = ~bist_mode;
    assign LED[1] = busy_func;
    assign LED[2] = bist_mode;
    assign LED[3] = 1'b0;

    assign GPIO_1_out_zero_value = 17'd0;

endmodule
