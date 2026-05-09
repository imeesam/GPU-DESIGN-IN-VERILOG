// simt_alu_tb.sv - Testbench for simt_alu
// EDA Playground: paste this in the Testbench window
`timescale 1ns/1ps
module simt_alu_tb;
    localparam NUM_LANES  = 8;
    localparam DATA_WIDTH = 32;
 
    logic                                    clk, rst_n;
    logic [3:0]                              opcode;
    logic [NUM_LANES-1:0]                    lane_mask;
    logic [NUM_LANES-1:0][DATA_WIDTH-1:0]    src_a, src_b, result;
    logic                                    valid_out;
 
    // ── Instantiate DUT ───────────────────────────────────
    simt_alu #(.NUM_LANES(NUM_LANES), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk), .rst_n(rst_n), .opcode(opcode),
        .lane_mask(lane_mask), .src_a(src_a), .src_b(src_b),
        .result(result), .valid_out(valid_out)
    );
 
    // ── Clock: 10ns period ────────────────────────────────
    initial clk = 1'b0;
    always  #5 clk = ~clk;
 
    // ── Waveform Dump (view in GTKWave) ──────────────────
    initial begin
        $dumpfile("simt_alu.vcd");
        $dumpvars(0, simt_alu_tb);
    end
 
    integer k;
    task apply_add;
        input [3:0] mask;
        integer j;
        begin
            opcode    = 4'h0;   // OP_ADD
            lane_mask = mask;
            for (j = 0; j < NUM_LANES; j = j + 1) begin
                src_a[j] = j + 1;   // 1,2,3,4,5,6,7,8
                src_b[j] = j + 1;   // same
            end
            @(posedge clk);
        end
    endtask
 
    initial begin
        // ── Reset ──────────────────────────────────────
        rst_n = 1'b0; opcode = 4'h0; lane_mask = 8'h00;
        src_a = {(NUM_LANES*DATA_WIDTH){1'b0}};
        src_b = {(NUM_LANES*DATA_WIDTH){1'b0}};
        repeat(3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
 
        // ── Test 1: ADD all lanes (mask=FF) ────────────
        $display("\n=== Test 1: ADD  mask=0xFF ===");
        apply_add(8'hFF);
        repeat(3) @(posedge clk);  // 2-cycle pipeline delay
        for (k = 0; k < NUM_LANES; k = k + 1)
            $display("  Lane[%0d]: %0d + %0d = %0d  %s",
                k, k+1, k+1, result[k],
                (result[k] == 2*(k+1)) ? "PASS" : "FAIL");
 
        // ── Test 2: Masked ADD (alternate lanes) ───────
        $display("\n=== Test 2: ADD  mask=0x55 (lanes 0,2,4,6 only) ===");
        apply_add(8'h55);   // 01010101
        repeat(3) @(posedge clk);
        for (k = 0; k < NUM_LANES; k = k + 1)
            $display("  Lane[%0d] active=%0b  result=%0d",
                k, 8'h55, result[k]);
 
        // ── Test 3: SLT signed comparison ──────────────
        $display("\n=== Test 3: SLT (signed less-than) ===");
        opcode    = 4'h6;   // OP_SLT
        lane_mask = 8'hFF;
        src_a[0]=32'd5;    src_b[0]=32'd10;   // 5  < 10 => 1
        src_a[1]=32'd10;   src_b[1]=32'd5;    // 10 < 5  => 0
        src_a[2]=-32'd1;   src_b[2]=32'd1;    // -1 < 1  => 1 (signed)
        src_a[3]=32'd1;    src_b[3]=-32'd1;   // 1 < -1  => 0 (signed)
        src_a[4]=32'd0;    src_b[4]=32'd0;    // 0 < 0   => 0
        for (k = 5; k < NUM_LANES; k = k + 1) begin
            src_a[k] = 32'd0; src_b[k] = 32'd0;
        end
        @(posedge clk); repeat(3) @(posedge clk);
        $display("  5 < 10  => %0d (expect 1)", result[0]);
        $display("  10 < 5  => %0d (expect 0)", result[1]);
        $display("  -1 < 1  => %0d (expect 1)", result[2]);
        $display("  1 < -1  => %0d (expect 0)", result[3]);
        $display("  0 < 0   => %0d (expect 0)", result[4]);
 
        $display("\n>>> Simulation DONE <<<\n");
        $finish;
    end
endmodule