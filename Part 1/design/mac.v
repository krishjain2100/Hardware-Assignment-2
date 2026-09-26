module mac #( 
    parameter WIDTH_IN = 8,
    parameter WIDTH_OUT = 32
) (
    input wire clk,
    input wire reset, 
    input wire valid_in,     
    input wire signed [WIDTH_IN-1:0] a,
    input wire signed [WIDTH_IN-1:0] b,
    output reg signed [WIDTH_OUT-1:0] total,
    output reg valid_out    
);
    
    reg signed [WIDTH_OUT-1:0] product;         

    always @(posedge clk) begin
        if (reset) begin
            total <= 0;
            product <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            total <= total + (a * b);
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule