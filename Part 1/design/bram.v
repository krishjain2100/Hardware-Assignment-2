module bram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6, // 6 bits can address 64 slots (for an 8x8 matrix)
    parameter MEM_DEPTH = 64,
    parameter INIT_FILE = "" // Path to the text file
) (
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire signed [DATA_WIDTH-1:0] data_in,
    output reg signed [DATA_WIDTH-1:0] data_out
);

    reg signed [DATA_WIDTH-1:0] memory [0:MEM_DEPTH-1];
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    always @(posedge clk) begin
        if (we) memory[addr] <= data_in;
        data_out <= memory[addr]; 
    end

endmodule