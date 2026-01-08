//
// PCILeech FPGA.
//
// MSI-X Controller Logic.
// Handles active interrupt generation and configuration space monitoring.
//
// (c) 2024
//

`timescale 1ns / 1ps

module pcileech_msix(
    input               clk,
    input               rst,
    
    // Interface to Shadow Config Space (to check Enable bit)
    output reg          cfg_rden,
    output reg [9:0]    cfg_rd_addr,
    input      [31:0]   cfg_rd_data,
    
    // Interrupt Trigger Interface
    input               trigger_req,
    output reg          interrupt_active
    );

    // State Machine
    // 0: Idle
    // 1: Read Config 
    // 2: Check Enable
    
    reg [1:0] state;
    
    // Example: Check MSI-X Control Register at Offset 0xC0 (DWORD 0x30)
    // Bit 31 = Enable? No, MSI-X Control is 16-bit.
    // Cap Header: ID(8), Next(8), MsgCtrl(16).
    // offset + 2 bytes.
    // Let's assume MSI-X Cap is at 0x40. 0x40 >> 2 = 0x10.
    
    always @ (posedge clk) begin
        if (rst) begin
            state <= 0;
            cfg_rden <= 0;
            interrupt_active <= 0;
        end else begin
            case (state)
                0: begin
                    // Periodically check or check on trigger
                    if (trigger_req) begin
                         state <= 1;
                         cfg_rden <= 1;
                         cfg_rd_addr <= 10'h10; // 0x40 / 4
                    end
                end
                
                1: begin
                    // Wait for BRAM latency (1 cycle? shadow module has pipelining)
                    cfg_rden <= 0;
                    state <= 2;
                end
                
                2: begin
                    // Check Enable Bit (Bit 15 of Message Control, which is upper 16 bits of DWORD 0)
                    // Data: [31:16] = Msg Ctrl, [15:8] = Next, [7:0] = Cap ID
                    // Enable is Bit 15 of Msg Ctrl -> Bit 31 of DWORD.
                    if (cfg_rd_data[31]) begin
                        interrupt_active <= 1; // Signal that we COULD fire
                    end else begin
                        interrupt_active <= 0;
                    end
                    state <= 0;
                end
            endcase
        end
    end

endmodule
