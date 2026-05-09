// Code your design here
// ============================================================
//  MODULE : instruction_decoder.sv
//  DESC   : Purely combinational — no clock, no state.
//           Breaks 32-bit instruction word into control fields.
// ------------------------------------------------------------
//  Instruction encoding (fixed format):
//  [31:28] opcode  | [27:24] dst_reg | [23:20] src_a_reg
//  [19:16] src_b_reg | [15:0] immediate
// ============================================================
module instruction_decoder (
    input  logic [31:0]   instruction,   // Raw 32-bit instruction
 
    // Decoded fields
    output logic [3:0]    opcode,
    output logic [3:0]    dst_reg,       // Destination register index
    output logic [3:0]    src_a_reg,     // Source A register index
    output logic [3:0]    src_b_reg,     // Source B register index
    output logic [15:0]   imm,           // 16-bit immediate value
 
    // Control signals derived from opcode
    output logic          src_sel,       // 0=use src_b_reg, 1=use imm
    output logic          is_load,       // Instruction reads shared memory
    output logic          is_store,      // Instruction writes shared memory
    output logic          is_valid       // Opcode recognized (not undefined)
);
 
    // Opcode constants (must match simt_alu.sv)
    localparam OP_ADD  = 4'h0;
    localparam OP_SUB  = 4'h1;
    localparam OP_MUL  = 4'h2;
    localparam OP_AND  = 4'h3;
    localparam OP_OR   = 4'h4;
    localparam OP_XOR  = 4'h5;
    localparam OP_SLT  = 4'h6;
    localparam OP_SRL  = 4'h7;
    localparam OP_LD   = 4'h8;   // Load  from shared memory
    localparam OP_ST   = 4'h9;   // Store to   shared memory
    localparam OP_ADDI = 4'hA;   // Add immediate (uses imm field)
 
    // ── Field Extraction (simple bit slicing) ─────────────
    always_comb begin
        // Direct field extraction — no logic, just wires
        opcode    = instruction[31:28];
        dst_reg   = instruction[27:24];
        src_a_reg = instruction[23:20];
        src_b_reg = instruction[19:16];
        imm       = instruction[15:0];
 
        // Default control signals (overridden by case below)
        src_sel  = 1'b0;
        is_load  = 1'b0;
        is_store = 1'b0;
        is_valid = 1'b1;
 
        // ── Opcode Decode ─────────────────────────────────
        // Each case sets only the signals that differ from defaults.
        // SystemVerilog requires default assignment first to avoid latches.
        case (opcode)
            OP_ADD  : ;  // All defaults are correct
            OP_SUB  : ;
            OP_MUL  : ;
            OP_AND  : ;
            OP_OR   : ;
            OP_XOR  : ;
            OP_SLT  : ;
            OP_SRL  : ;
            OP_LD   : is_load  = 1'b1;          // Load  instruction
            OP_ST   : is_store = 1'b1;          // Store instruction
            OP_ADDI : src_sel  = 1'b1;          // Use immediate
            default : is_valid = 1'b0;          // Unknown opcode
        endcase
    end
 
endmodule