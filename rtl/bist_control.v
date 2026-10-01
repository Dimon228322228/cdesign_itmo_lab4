`timescale 1ns / 1ps

module bist_control (
    input  wire       clk,
    input  wire       reset,
    input  wire       bist_press,
    input  wire       norm_press,
    input  wire       busy_func,
    output reg        bist_mode,
    output reg        calc_start,
    output reg        lfsr_en,
    output reg        lfsr_load,
    output reg        crc_clear,
    output reg        crc_valid,
    output reg        bist_done,
    output reg [7:0]  bist_count,
    output reg [7:0]  iter_count
);

    localparam NORM           = 3'd0;
    localparam BIST_START     = 3'd1;
    localparam BIST_WAIT_BUSY = 3'd2;
    localparam BIST_WAIT_DONE = 3'd3;
    localparam BIST_CRC       = 3'd4;
    localparam BIST_NEXT      = 3'd5;
    localparam BIST_SETTLE    = 3'd6; 
    localparam BIST_FINISH    = 3'd7; 

    reg [2:0] state;

    always @(posedge clk) begin
        if (reset) begin
            state      <= NORM;
            bist_mode  <= 1'b0;
            calc_start <= 1'b0;
            lfsr_en    <= 1'b0;
            lfsr_load  <= 1'b0;
            crc_clear  <= 1'b0;
            crc_valid  <= 1'b0;
            bist_done  <= 1'b0;
            bist_count <= 8'd0;
            iter_count <= 8'd0;
        end else begin
            calc_start <= 1'b0;
            lfsr_en    <= 1'b0;
            lfsr_load  <= 1'b0;
            crc_clear  <= 1'b0;
            crc_valid  <= 1'b0;
            bist_done  <= 1'b0;

            case (state)
                NORM: begin
                    bist_mode <= 1'b0;
                    if (norm_press)
                        calc_start <= 1'b1;
                    if (bist_press) begin
                        bist_mode  <= 1'b1;
                        bist_count <= bist_count + 8'd1;
                        iter_count <= 8'd0;
                        crc_clear  <= 1'b1;
                        lfsr_load  <= 1'b1; 
                        state      <= BIST_START;
                    end
                end

                BIST_START: begin
                    calc_start <= 1'b1;
                    state      <= BIST_WAIT_BUSY;
                end

                BIST_WAIT_BUSY: begin
                    if (busy_func)
                        state <= BIST_WAIT_DONE;
                end

                BIST_WAIT_DONE: begin
                    if (!busy_func)
                        state <= BIST_CRC;
                end

                BIST_CRC: begin
                    crc_valid <= 1'b1;
                    if (iter_count == 8'd255)
                        state <= BIST_SETTLE;
                    else
                        state <= BIST_NEXT;
                end

                BIST_NEXT: begin
                    lfsr_en    <= 1'b1;
                    iter_count <= iter_count + 8'd1;
                    state      <= BIST_START;
                end

                BIST_SETTLE: begin
                    state <= BIST_FINISH;
                end

                BIST_FINISH: begin
                    bist_mode <= 1'b0;
                    bist_done <= 1'b1;
                    state     <= NORM;
                end

                default: state <= NORM;
            endcase
        end
    end

endmodule
