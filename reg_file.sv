// ============================================================
//  MODULE : register_file.sv
//  DESC   : Warp Register File — 8 warps x 16 regs x 32-bit
//           Dual read ports (combinational)
//           Single write port (synchronous)
//           Write-before-read forwarding on same warp+reg
// ============================================================
module register_file #(
    parameter NUM_WARPS  = 8,    // Independent warp contexts
    parameter NUM_REGS   = 16,   // Registers per warp
    parameter DATA_WIDTH = 32    // Bits per register
)(
    input  logic                           clk,
    input  logic                           rst_n,
 
    // ── Read Port A (combinational) ───────────────────────
    input  logic [2:0]                     rd_warp_a,   // Which warp to read
    input  logic [3:0]                     rd_reg_a,    // Which register (0-15)
    output logic [DATA_WIDTH-1:0]          rd_data_a,   // Data out
 
    // ── Read Port B (combinational) ───────────────────────
    input  logic [2:0]                     rd_warp_b,
    input  logic [3:0]                     rd_reg_b,
    output logic [DATA_WIDTH-1:0]          rd_data_b,
 
    // ── Write Port (synchronous, clk edge) ────────────────
    input  logic                           wr_en,
    input  logic [2:0]                     wr_warp,
    input  logic [3:0]                     wr_reg,
    input  logic [DATA_WIDTH-1:0]          wr_data
);
 
    // ── Storage Array ─────────────────────────────────────
    // Declared as: rf[warp_id][register_id] = 32-bit value
    // Total: 8 x 16 x 32 = 4096 bits = 512 bytes
    logic [NUM_WARPS-1:0][NUM_REGS-1:0][DATA_WIDTH-1:0] rf;
 
    // ── Write Logic (synchronous) ─────────────────────────
    integer w, r;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Zero out all registers on reset
            for (w = 0; w < NUM_WARPS; w = w + 1)
                for (r = 0; r < NUM_REGS; r = r + 1)
                    rf[w][r] <= {DATA_WIDTH{1'b0}};
        end else if (wr_en) begin
            rf[wr_warp][wr_reg] <= wr_data;
        end
    end
 
    // ── Read Logic (combinational + forwarding) ────────────
    // Write-before-read: if the write port targets the same
    // warp+register we are reading, forward the new write data
    // directly instead of reading stale storage.
    always_comb begin
        // Port A
        if (wr_en && (wr_warp == rd_warp_a) && (wr_reg == rd_reg_a))
            rd_data_a = wr_data;   // Forwarding path
        else
            rd_data_a = rf[rd_warp_a][rd_reg_a];
 
        // Port B
        if (wr_en && (wr_warp == rd_warp_b) && (wr_reg == rd_reg_b))
            rd_data_b = wr_data;   // Forwarding path
        else
            rd_data_b = rf[rd_warp_b][rd_reg_b];
    end
 
endmodule