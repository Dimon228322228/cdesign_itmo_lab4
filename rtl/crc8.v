`timescale 1ns / 1ps

module crc8 #(
    parameter [7:0] POLY = 8'hA9
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       clear,
    input  wire       valid,
    input  wire [7:0] data_in,
    output reg  [7:0] crc_out
);

    integer i;
    reg [7:0] crc_next;

    always @(posedge clk) begin
        if (reset || clear)
            crc_out <= 8'd0;
        else if (valid) begin
            crc_next = crc_out ^ data_in;
            for (i = 0; i < 8; i = i + 1) begin
                if (crc_next[7])
                    crc_next = {crc_next[6:0], 1'b0} ^ POLY;
                else
                    crc_next = {crc_next[6:0], 1'b0};
            end
            crc_out <= crc_next;
        end
    end

endmodule
