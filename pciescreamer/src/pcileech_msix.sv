// (c) 2024

`timescale 1ns / 1ps

module pcileech_msix(
    input               clk,
    input               rst,

    output reg          cfg_rden,
    output reg [9:0]    cfg_rd_addr,
    input      [31:0]   cfg_rd_data,

    input               trigger_req,
    output reg          interrupt_active
    );

    reg [1:0] state;

    always @ (posedge clk) begin
        if (rst) begin
            state <= 0;
            cfg_rden <= 0;
            interrupt_active <= 0;
        end else begin
            case (state)
                0: begin
                    if (trigger_req) begin
                         state <= 1;
                         cfg_rden <= 1;
                         cfg_rd_addr <= 10'h10;
                    end
                end
                1: begin
                    cfg_rden <= 0;
                    state <= 2;
                end
                2: begin
                    if (cfg_rd_data[31]) begin
                        interrupt_active <= 1;
                    end else begin
                        interrupt_active <= 0;
                    end
                    state <= 0;
                end
            endcase
        end
    end

endmodule
