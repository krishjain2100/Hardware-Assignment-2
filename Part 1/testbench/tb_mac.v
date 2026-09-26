`timescale 1ns/1ps

module tb_mac;
    reg clk;
    reg reset;
    reg valid_in;
    reg [7:0] a, b;
    
    wire [15:0] total;
    wire valid_out;

    mac #(
        .WIDTH_IN(8),
        .WIDTH_OUT(16)
    ) uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .total(total),
        .valid_out(valid_out)
    );

    // period = 10ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mac.vcd");
        $dumpvars(0, tb_mac);

        clk = 0; 
        reset = 1; 
        valid_in = 0; 
        a = 0; 
        b = 0;
        
        #20 reset = 0;

        @(posedge clk); #1
        valid_in = 1; a = 2; b = 3;
        @(posedge clk); #1 
        valid_in = 1; a = 4; b = 5;
        @(posedge clk); #1 
        valid_in = 0; a = 0; b = 0;
        #40 $finish;
    end
endmodule