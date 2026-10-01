`timescale 1ns / 1ps

module lfsr8 #(
    parameter [7:0] TAPS = 8'h63,
    parameter [7:0] SEED = 8'hA5
) (
    input  wire       clk,
    input  wire       reset,
    input  wire       load, 
    input  wire       en,
    output reg  [7:0] q
);

    initial q = SEED;

    wire feedback;
    assign feedback = ^(q & TAPS);

    always @(posedge clk) begin
        if (reset || load)
            q <= SEED;
        else if (en)
            q <= {q[6:0], feedback};
    end

endmodule
