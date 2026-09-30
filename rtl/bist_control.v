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
    output reg        crc_clear,
    output reg        crc_valid,
    output reg [7:0]  bist_count,
    output reg [7:0]  iter_count
);

    localparam NORM      = 3'd0;
    localparam BIST_INIT = 3'd1;
    localparam BIST_WAIT = 3'd2;

    reg [2:0] state;
    reg       busy_armed;

    always @(posedge clk) begin
        if (reset) begin
            state      <= NORM;
            bist_mode  <= 1'b0;
            calc_start <= 1'b0;
            lfsr_en    <= 1'b0;
            crc_clear  <= 1'b0;
            crc_valid  <= 1'b0;
            bist_count <= 8'd0;
            iter_count <= 8'd0;
            busy_armed <= 1'b0;
        end else begin
            calc_start <= 1'b0;
            lfsr_en    <= 1'b0;
            crc_clear  <= 1'b0;
            crc_valid  <= 1'b0;

            case (state)
                NORM: begin
                    bist_mode  <= 1'b0;
                    busy_armed <= 1'b0;
                    if (norm_press)
                        calc_start <= 1'b1;
                    if (bist_press) begin
                        bist_mode  <= 1'b1;
                        bist_count <= bist_count + 8'd1;
                        iter_count <= 8'd0;
                        crc_clear  <= 1'b1;
                        state      <= BIST_INIT;
                    end
                end

                BIST_INIT: begin
                    calc_start <= 1'b1;
                    busy_armed <= 1'b0;
                    state      <= BIST_WAIT;
                end

                BIST_WAIT: begin
                    if (busy_func)
                        busy_armed <= 1'b1;
                    if (busy_armed && !busy_func) begin
                        crc_valid <= 1'b1;
                        if (iter_count == 8'd255) begin
                            bist_mode <= 1'b0;
                            state     <= NORM;
                        end else begin
                            lfsr_en    <= 1'b1;
                            iter_count <= iter_count + 8'd1;
                            state      <= BIST_INIT;
                        end
                    end
                end

                default: state <= NORM;
            endcase
        end
    end

endmodule
