`timescale 1ns / 1ps

module tb_matmul;

    parameter M = 8;
    parameter K = 8;
    parameter N = 8;
    parameter WIDTH_IN = 8;
    parameter WIDTH_OUT = 16;
    parameter ADDR_WIDTH = 6;

    reg clk;
    reg reset;
    reg valid_in;

    wire [ADDR_WIDTH-1:0] addr_a, addr_b, addr_c;
    wire signed [WIDTH_IN-1:0] data_a, data_b;
    wire signed [WIDTH_OUT-1:0] data_c;
    wire we_c;
    wire valid_out;

    bram #(
        .DATA_WIDTH(WIDTH_IN),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(64),
        .INIT_FILE("testbench/matrix_a.txt")
    ) bram_a (
        .clk(clk),
        .we(1'b0),
        .addr(addr_a),
        .data_in(8'sd0),
        .data_out(data_a)
    );

    bram #(
        .DATA_WIDTH(WIDTH_IN),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(64),
        .INIT_FILE("testbench/matrix_b.txt")
    ) bram_b (
        .clk(clk),
        .we(1'b0),
        .addr(addr_b),
        .data_in(8'sd0),
        .data_out(data_b)
    );

    bram #(
        .DATA_WIDTH(WIDTH_OUT),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_DEPTH(64),
        .INIT_FILE("")
    ) bram_c (
        .clk(clk),
        .we(we_c),
        .addr(addr_c),
        .data_in(data_c),
        .data_out()
    );

    matmul #(
        .M(M), .K(K), .N(N),
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT),
        .ADDR_WIDTH_A(ADDR_WIDTH),
        .ADDR_WIDTH_B(ADDR_WIDTH),
        .ADDR_WIDTH_C(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .addr_a(addr_a),
        .data_a(data_a),
        .addr_b(addr_b),
        .data_b(data_b),
        .addr_c(addr_c),
        .data_c(data_c),
        .we_c(we_c),
        .valid_out(valid_out)
    );

    // Period = 10ns
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        valid_in = 0;
        $dumpfile("waveforms/matmul.vcd");
        $dumpvars(0, tb_matmul);

        #20;
        reset = 0;
        #10;

        valid_in = 1;

        @(posedge valid_out);
        $display("Matrix multiplication finished successfully at time %t!", $time);
        @(posedge clk);
        valid_in = 0;
        #50;
        $finish;
    end

endmodule