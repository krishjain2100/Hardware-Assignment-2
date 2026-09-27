`timescale 1ns / 1ps

module tb_universal;

    parameter M = `M_VAL;
    parameter K = `K_VAL;
    parameter N = `N_VAL;
    parameter WIDTH_IN = `WIDTH_IN_VAL;
    parameter WIDTH_OUT = `WIDTH_OUT_VAL;

    reg clk;
    reg reset;
    reg valid_in;

    wire [(M*K > 1 ? $clog2(M*K) : 1)-1:0] addr_a;
    wire [(K*N > 1 ? $clog2(K*N) : 1)-1:0] addr_b;
    wire [(M*N > 1 ? $clog2(M*N) : 1)-1:0] addr_c;

    wire signed [WIDTH_IN-1:0] data_a, data_b;
    wire signed [WIDTH_OUT-1:0] data_c;
    wire we_c;
    wire valid_out;

    bram #(.DATA_WIDTH(WIDTH_IN), .MEM_DEPTH(M * K), .INIT_FILE(`FILE_A)) 
        bram_a (.clk(clk), .we(1'b0), .addr(addr_a), .data_in(8'd0), .data_out(data_a));

    bram #(.DATA_WIDTH(WIDTH_IN), .MEM_DEPTH(K * N), .INIT_FILE(`FILE_B)) 
        bram_b (.clk(clk), .we(1'b0), .addr(addr_b), .data_in(8'd0), .data_out(data_b));

    bram #(.DATA_WIDTH(WIDTH_OUT), .MEM_DEPTH(M * N), .INIT_FILE("")) 
        bram_c (.clk(clk), .we(we_c), .addr(addr_c), .data_in(data_c), .data_out());

    matmul #(.M(M), .K(K), .N(N), .WIDTH_IN(WIDTH_IN), .WIDTH_OUT(WIDTH_OUT)) uut (
        .clk(clk), .reset(reset), .valid_in(valid_in),
        .addr_a(addr_a), .data_a(data_a),
        .addr_b(addr_b), .data_b(data_b),
        .addr_c(addr_c), .data_c(data_c),
        .we_c(we_c), .valid_out(valid_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1; valid_in = 0;
        #20; reset = 0; #10; valid_in = 1;
        
        @(posedge valid_out);
        $writememh(`FILE_C, bram_c.memory);
        
        @(posedge clk); valid_in = 0; #30; $finish;
    end
endmodule