`timescale 1ns/1ps

module tb_dot_product;
    reg clk;
    reg reset;
    reg valid_in;
    
    reg signed [23:0] row_a;
    reg signed [23:0] col_b;
    
    wire signed [15:0] result;
    wire valid_out;

    dot_product #(
        .K(3),
        .WIDTH_IN(8),
        .WIDTH_OUT(16)
    ) uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .row_a(row_a),
        .col_b(col_b),
        .result(result),
        .valid_out(valid_out)
    );

    // period = 10ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dot_product.vcd");
        $dumpvars(0, tb_dot_product);

        clk = 0; 
        reset = 1; 
        valid_in = 0; 
        row_a = 0; 
        col_b = 0;

        #20 reset = 0;

        @(posedge clk); #1;
        valid_in = 1;
        
        row_a = {8'sd3, 8'sd2, 8'sd1};
        col_b = {8'sd6, 8'sd5, 8'sd4};

        wait(valid_out == 1);
        
        @(posedge clk); #1;
        valid_in = 0;

        #40 $finish;
    end
endmodule