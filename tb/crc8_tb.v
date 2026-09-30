`timescale 1ns / 1ps

module crc8_tb;
    reg        clk;
    reg        reset;
    reg        clear;
    reg        valid;
    reg  [7:0] data_in;
    wire [7:0] crc_out;

    crc8 #(.POLY(8'hA9)) uut (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .valid(valid),
        .data_in(data_in),
        .crc_out(crc_out)
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
        input [7:0] want;
        input [8*32-1:0] msg;
        begin
            if (crc_out !== want) begin
                $display("FAIL: %0s (got 0x%02h, want 0x%02h)", msg, crc_out, want);
                errors = errors + 1;
            end else
                $display("OK:   %0s (0x%02h)", msg, crc_out);
        end
    endtask

    task feed;
        input [7:0] data;
        begin
            @(negedge clk);
            data_in = data;
            valid   = 1'b1;
            @(posedge clk);
            #1;               
            valid   = 1'b0;
        end
    endtask

    initial begin
        errors  = 0;
        clear   = 0;
        valid   = 0;
        data_in = 8'd0;
        reset   = 1;
        repeat (3) wait_clk;
        reset = 0;
        wait_clk;
        check(8'h00, "after reset");

        $display("--- feed first BIST-like bytes ---");
        feed(8'h0D); check(8'h48, "after y=13");
        feed(8'h08); check(8'h06, "after y=8");
        feed(8'h0C); check(8'h45, "after y=12");

        $display("--- clear without reset ---");
        @(negedge clk);
        clear = 1'b1;
        @(posedge clk);
        #1;
        clear = 1'b0;
        check(8'h00, "after clear");

        data_in = 8'hFF;
        wait_clk;
        check(8'h00, "idle (no valid)");

        if (errors == 0)
            $display("crc8_tb: PASS");
        else
            $display("crc8_tb: FAIL (%0d errors)", errors);
        $finish;
    end
endmodule
