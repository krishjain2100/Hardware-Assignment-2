`include "design.v"

module tb;
  reg in;
  wire out;
  
  inverter uut (.in(in), .out(out));
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb);      
    
    in = 0; #10;
    in = 1; #10;
    $finish;
  end
endmodule