// register_file_tb.sv
`timescale 1ns/1ps
module register_file_tb;
    logic        clk, rst_n, wr_en;
    logic [2:0]  rd_warp_a, rd_warp_b, wr_warp;
    logic [3:0]  rd_reg_a, rd_reg_b, wr_reg;
    logic [31:0] rd_data_a, rd_data_b, wr_data;
 
    register_file #(.NUM_WARPS(8),.NUM_REGS(16),.DATA_WIDTH(32)) dut (
        .clk(clk), .rst_n(rst_n),
        .rd_warp_a(rd_warp_a), .rd_reg_a(rd_reg_a), .rd_data_a(rd_data_a),
        .rd_warp_b(rd_warp_b), .rd_reg_b(rd_reg_b), .rd_data_b(rd_data_b),
        .wr_en(wr_en), .wr_warp(wr_warp), .wr_reg(wr_reg), .wr_data(wr_data)
    );
 
    initial clk = 1'b0;
    always  #5 clk = ~clk;
    initial begin $dumpfile("rf.vcd"); $dumpvars(0, register_file_tb); end
 
    initial begin
        rst_n=1'b0; wr_en=1'b0;
        rd_warp_a=0; rd_reg_a=0; rd_warp_b=0; rd_reg_b=0;
        wr_warp=0; wr_reg=0; wr_data=0;
        repeat(3) @(posedge clk); rst_n=1'b1;
 
        // Test 1: Write warp=0, reg=3 = 0xABCD_1234
        @(posedge clk);
        wr_en=1; wr_warp=3'd0; wr_reg=4'd3; wr_data=32'hABCD1234;
        @(posedge clk); wr_en=0;
        rd_warp_a=3'd0; rd_reg_a=4'd3;
        #1;
        $display("Test1 W[0][3]=0x%08h (expect 0xABCD1234) %s",
            rd_data_a, rd_data_a==32'hABCD1234 ? "PASS":"FAIL");
 
        // Test 2: Write-Before-Read forwarding
        // Read and write same address in same cycle
        @(posedge clk);
        wr_en=1; wr_warp=3'd1; wr_reg=4'd5; wr_data=32'hDEAD_BEEF;
        rd_warp_a=3'd1; rd_reg_a=4'd5;   // Read the register being written
        #1;
        $display("Test2 Forward rd_data_a=0x%08h (expect 0xDEADBEEF) %s",
            rd_data_a, rd_data_a==32'hDEADBEEF ? "PASS":"FAIL");
        @(posedge clk); wr_en=0;
 
        // Test 3: Dual read ports simultaneously
        rd_warp_a=3'd0; rd_reg_a=4'd3;   // Previously written
        rd_warp_b=3'd1; rd_reg_b=4'd5;   // Previously written
        #1;
        $display("Test3 PortA=0x%08h PortB=0x%08h",rd_data_a,rd_data_b);
 
        $display("\n>>> RF Simulation DONE <<<");
        $finish;
    end
endmodule
