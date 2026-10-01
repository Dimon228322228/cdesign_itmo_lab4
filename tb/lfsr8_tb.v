`timescale 1ns / 1ps

module lfsr8_tb;
    reg        clk;
    reg        reset;
    reg        en1, en2;
    wire [7:0] q1, q2;

    lfsr8 #(.TAPS(8'h63), .SEED(8'hA5)) u1 (
        .clk(clk), .reset(reset), .load(1'b0), .en(en1), .q(q1)
    );
    lfsr8 #(.TAPS(8'hC5), .SEED(8'h5A)) u2 (
        .clk(clk), .reset(reset), .load(1'b0), .en(en2), .q(q2)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer errors;

    task wait_clk;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task check;
        input [7:0] got;
        input [7:0] want;
        input [8*24-1:0] tag;
        begin
            if (got !== want) begin
                $display("FAIL [%0s]: got 0x%02h, want 0x%02h", tag, got, want);
                errors = errors + 1;
            end else
                $display("OK   [%0s]: 0x%02h", tag, got);
        end
    endtask

    initial begin
        errors = 0;
        en1 = 0;
        en2 = 0;
        reset = 1;
        repeat (3) wait_clk;
        reset = 0;
        wait_clk;

        $display("--- after reset ---");
        check(q1, 8'hA5, "LFSR1 seed");
        check(q2, 8'h5A, "LFSR2 seed");

        $display("--- 4 steps with en ---");
        en1 = 1;
        en2 = 1;
        wait_clk; check(q1, 8'h4A, "LFSR1 #1"); check(q2, 8'hB5, "LFSR2 #1");
        wait_clk; check(q1, 8'h94, "LFSR1 #2"); check(q2, 8'h6B, "LFSR2 #2");
        wait_clk; check(q1, 8'h28, "LFSR1 #3"); check(q2, 8'hD6, "LFSR2 #3");
        wait_clk; check(q1, 8'h51, "LFSR1 #4"); check(q2, 8'hAD, "LFSR2 #4");

        $display("--- en=0: hold ---");
        en1 = 0;
        en2 = 0;
        wait_clk;
        check(q1, 8'h51, "LFSR1 hold");
        check(q2, 8'hAD, "LFSR2 hold");

        if (errors == 0)
            $display("lfsr8_tb: PASS");
        else
            $display("lfsr8_tb: FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
