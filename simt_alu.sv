//  ============================================================
//  MODULE : simt_alu.sv
//  DESC   : 8-Lane SIMT ALU with 2-stage pipeline
//  SESSION: Semirise GPU Workshop
// ------------------------------------------------------------
//  EDA Playground Setup:
//    Design    : simt_alu.sv
//    Testbench : simt_alu_tb.sv
// ============================================================
 
module simt_alu #(
    parameter NUM_LANES  = 8,    // Number of parallel SIMT lanes
    parameter DATA_WIDTH = 32    // Operand width in bits
)(
    input  logic                                       clk,
    input  logic                                       rst_n,      // Active-low synchronous reset
 
    // Control
    input  logic [3:0]                                 opcode,     // Operation to perform
    input  logic [NUM_LANES-1:0]                       lane_mask,  // 1=active, 0=skip this lane
 
    // Operands (packed: lane is outer dimension)
    input  logic [NUM_LANES-1:0][DATA_WIDTH-1:0]       src_a,
    input  logic [NUM_LANES-1:0][DATA_WIDTH-1:0]       src_b,
 
    // Results
    output logic [NUM_LANES-1:0][DATA_WIDTH-1:0]       result,
    output logic                                       valid_out   // High when result is ready
);
 
    // ── Opcode Table ──────────────────────────────────────
    localparam OP_ADD = 4'h0;   // result = src_a + src_b
    localparam OP_SUB = 4'h1;   // result = src_a - src_b
    localparam OP_MUL = 4'h2;   // result = src_a * src_b (lower 32b)
    localparam OP_AND = 4'h3;   // result = src_a & src_b
    localparam OP_OR  = 4'h4;   // result = src_a | src_b
    localparam OP_XOR = 4'h5;   // result = src_a ^ src_b
    localparam OP_SLT = 4'h6;   // result = ($signed(A) < $signed(B)) ? 1 : 0
    localparam OP_SRL = 4'h7;   // result = src_a >> src_b[4:0]
 
    // ── Stage-1 Pipeline Registers ────────────────────────
    // Capture all inputs on clock edge to begin pipeline
    logic [3:0]                              opcode_r;
    logic [NUM_LANES-1:0]                    mask_r;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]    src_a_r;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]    src_b_r;
    logic                                    valid_r;
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opcode_r <= 4'h0;
            mask_r   <= {NUM_LANES{1'b0}};
            src_a_r  <= {NUM_LANES*DATA_WIDTH{1'b0}};
            src_b_r  <= {NUM_LANES*DATA_WIDTH{1'b0}};
            valid_r  <= 1'b0;
        end else begin
            opcode_r <= opcode;
            mask_r   <= lane_mask;
            src_a_r  <= src_a;
            src_b_r  <= src_b;
            valid_r  <= 1'b1;
        end
    end
 
    // ── Stage-2: One ALU per Lane (generate block) ─────────
    // 'generate for' replicates this logic NUM_LANES times.
    // Synthesis creates 8 independent ALU instances.
    genvar i;
    generate
        for (i = 0; i < NUM_LANES; i = i + 1) begin : lane_gen
 
            logic [DATA_WIDTH-1:0] lane_out;  // Combinational result for lane i
 
            always_comb begin
                if (!mask_r[i]) begin
                    lane_out = {DATA_WIDTH{1'b0}}; // Inactive lane outputs zero
                end else begin
                    case (opcode_r)
                        OP_ADD : lane_out = src_a_r[i] + src_b_r[i];
                        OP_SUB : lane_out = src_a_r[i] - src_b_r[i];
                        OP_MUL : lane_out = src_a_r[i] * src_b_r[i];
                        OP_AND : lane_out = src_a_r[i] & src_b_r[i];
                        OP_OR  : lane_out = src_a_r[i] | src_b_r[i];
                        OP_XOR : lane_out = src_a_r[i] ^ src_b_r[i];
                        OP_SLT : lane_out = ($signed(src_a_r[i]) < $signed(src_b_r[i]))
                                            ? 32'd1 : 32'd0;
                        OP_SRL : lane_out = src_a_r[i] >> src_b_r[i][4:0];
                        default: lane_out = {DATA_WIDTH{1'b0}};
                    endcase
                end
            end
 
            // Register the lane output (Stage-2 register = output pipeline)
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) result[i] <= {DATA_WIDTH{1'b0}};
                else        result[i] <= lane_out;
            end
        end
    endgenerate
 
    // valid_out follows valid_r by 1 cycle (matches result latency)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_out <= 1'b0;
        else        valid_out <= valid_r;
    end
 
endmodule