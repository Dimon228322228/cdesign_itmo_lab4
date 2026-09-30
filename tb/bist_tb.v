`timescale 1ns / 1ps

module bist_tb;
    localparam [7:0] CRC_GOLDEN = 8'hA2;

    reg         CLK;
    reg         RST_N;
    reg         KEY2_N;  // самотест
    reg         KEY3_N;  // обычный старт
    reg  [16:0] GPIO_1_input_pullup;

    wire [3:0]  LED;
    wire [7:0]  SEG_DATA;
    wire [7:0]  SEG_SEL;
    wire [16:0] GPIO_1_out_zero_value;

    bist_top uut (
        .CLK(CLK),
        .RST_N(RST_N),
        .KEY2_N(KEY2_N),
        .KEY3_N(KEY3_N),
        .GPIO_1_input_pullup(GPIO_1_input_pullup),
        .LED(LED),
        .SEG_DATA(SEG_DATA),
        .SEG_SEL(SEG_SEL),
        .GPIO_1_out_zero_value(GPIO_1_out_zero_value)
    );

    defparam uut.u_key2.CNT_MAX     = 2;
    defparam uut.u_key3.CNT_MAX     = 2;
    defparam uut.u_disp.REFRESH_DIV = 4;
    defparam uut.u_disp.PASSES      = 1;

    initial CLK = 0;
    always #5 CLK = ~CLK;

    integer errors;

    task wait_clk;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge CLK);
        end
    endtask

    task press_key2;
        begin
            KEY2_N = 1'b0;
            wait_clk(8);
            KEY2_N = 1'b1;
            wait_clk(8);
        end
    endtask

    task press_key3;
        begin
            KEY3_N = 1'b0;
            wait_clk(8);
            KEY3_N = 1'b1;
            wait_clk(8);
        end
    endtask

    task check;
        input        ok;
        input [8*48-1:0] msg;
        begin
            if (!ok) begin
                $display("FAIL: %0s", msg);
                errors = errors + 1;
            end else
                $display("OK:   %0s", msg);
        end
    endtask

    task do_bist;
        output [7:0] crc;
        output [7:0] cnt;
        begin
            press_key2();
            wait (LED[2] === 1'b1);
            wait (LED[2] === 1'b0);
            wait_clk(4);
            crc = uut.crc_out;
            cnt = uut.bist_count;
        end
    endtask

    task hard_reset;
        begin
            RST_N = 1'b0;
            wait_clk(10);
            RST_N = 1'b1;
            wait_clk(10);
        end
    endtask

    initial begin
        $dumpfile("tb/bist_tb.vcd");
        $dumpvars(0, bist_tb);

        errors = 0;
        KEY2_N = 1'b1;
        KEY3_N = 1'b1;
        GPIO_1_input_pullup = {1'b0, 8'd8, 8'd3};

        RST_N = 1'b0;
        wait_clk(20);
        RST_N = 1'b1;
        wait_clk(10);

        $display("========== 1. NORM ==========");
        press_key3();
        wait (LED[1] === 1'b1);
        wait (LED[1] === 1'b0);
        wait_clk(2);

        check(uut.y_func === 5'd2, "y == 2  (sqrt(3+cbrt(8)))");
        check(LED[0] === 1'b1,     "LED[0]=1  (normal mode)");
        check(LED[2] === 1'b0,     "LED[2]=0  (not in BIST)");

        $display("========== 2. BIST #1 ==========");
        begin : b1
            reg [7:0] crc, cnt;
            do_bist(crc, cnt);
            $display("       CRC=0x%02h  bist_count=%0d", crc, cnt);
            check(crc === CRC_GOLDEN, "CRC == 0xA2");
            check(cnt === 8'd1,       "bist_count == 1");
            check(LED[2] === 1'b0,    "returned to NORM");
        end

        $display("========== 3. reset + BIST #2 ==========");
        hard_reset();
        begin : b2
            reg [7:0] crc, cnt;
            do_bist(crc, cnt);
            $display("       CRC=0x%02h  bist_count=%0d", crc, cnt);
            check(crc === CRC_GOLDEN, "CRC == 0xA2 after reset");
            check(cnt === 8'd1,       "bist_count == 1 after reset");
        end

        if (errors == 0)
            $display("bist_tb: PASS");
        else
            $display("bist_tb: FAIL (%0d errors)", errors);
        $finish;
    end

    initial begin
        #500_000_000;
        $display("FAIL: timeout");
        $finish;
    end
endmodule
