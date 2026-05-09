// instruction_decoder_tb.sv
`timescale 1ns/1ps
module instruction_decoder_tb;
    logic [31:0]  instruction;
    logic [3:0]   opcode, dst_reg, src_a_reg, src_b_reg;
    logic [15:0]  imm;
    logic         src_sel, is_load, is_store, is_valid;
 
    instruction_decoder dut (
        .instruction(instruction), .opcode(opcode),
        .dst_reg(dst_reg), .src_a_reg(src_a_reg), .src_b_reg(src_b_reg),
        .imm(imm), .src_sel(src_sel), .is_load(is_load),
        .is_store(is_store), .is_valid(is_valid)
    );
 
    // Helper task: print decoded fields
    task show;
        input [63:0] label;
        begin
            $display("%s", label);
            $display("  opcode=%0h dst=%0h srcA=%0h srcB=%0h imm=0x%04h",
                opcode, dst_reg, src_a_reg, src_b_reg, imm);
            $display("  src_sel=%0b is_load=%0b is_store=%0b is_valid=%0b",
                src_sel, is_load, is_store, is_valid);
        end
    endtask
 
    initial begin
        $dumpfile("decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);
 
        // Test 1: ADD r2 = r0 + r1
        // [31:28]=0(ADD) [27:24]=2(dst) [23:20]=0(srcA) [19:16]=1(srcB) [15:0]=0
        instruction = {4'h0, 4'd2, 4'd0, 4'd1, 16'h0000};
        #10; show("--- ADD r2, r0, r1 ---");
 
        // Test 2: ADDI r3 = r0 + 42  (src_sel should be 1)
        instruction = {4'hA, 4'd3, 4'd0, 4'd0, 16'd42};
        #10; show("--- ADDI r3, r0, #42 ---");
        $display("  src_sel should be 1: %s", src_sel ? "PASS":"FAIL");
 
        // Test 3: LD r4 = mem[r1]  (is_load should be 1)
        instruction = {4'h8, 4'd4, 4'd1, 4'd0, 16'h0000};
        #10; show("--- LD r4, [r1] ---");
        $display("  is_load should be 1: %s", is_load ? "PASS":"FAIL");
 
        // Test 4: Unknown opcode F
        instruction = {4'hF, 4'd0, 4'd0, 4'd0, 16'h0};
        #10; show("--- UNKNOWN opcode 0xF ---");
        $display("  is_valid should be 0: %s", !is_valid ? "PASS":"FAIL");
 
        $display("\n>>> Decoder Simulation DONE <<<");
        $finish;
    end
endmodule