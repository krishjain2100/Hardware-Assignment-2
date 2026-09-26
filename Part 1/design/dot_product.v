module dot_product #(
    parameter K = 3, // number of elements in the vectors
    parameter WIDTH_IN = 8,
    parameter WIDTH_OUT = 32
) (
    input wire clk,
    input wire reset,
    input wire valid_in,    
    input wire signed [(K*WIDTH_IN)-1:0] row_a,
    input wire signed [(K*WIDTH_IN)-1:0] col_b,
    output wire signed [WIDTH_OUT-1:0] result, 
    output reg valid_out
);

    reg mac_reset;
    reg mac_valid_in;
    reg signed [WIDTH_IN-1:0] mac_a, mac_b;
    wire mac_valid_out;

    reg [$clog2(K+1)-1:0] index;
    reg [$clog2(K+1)-1:0] valid_count;

    // FSM States
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    reg [1:0] state;

    mac #(
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT)
    ) mac_engine (
        .clk(clk),
        .reset(mac_reset),
        .valid_in(mac_valid_in),
        .a(mac_a),
        .b(mac_b),
        .total(result),
        .valid_out(mac_valid_out)
    );

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            valid_out <= 0;
            mac_reset <= 1;
            mac_valid_in <= 0;
            index <= 0;
            valid_count <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (valid_in) begin
                        state <= CALC;
                        mac_reset <= 0;
                        mac_valid_in <= 0;
                        index <= 0;
                        valid_count <= 0;
                    end
                end

                CALC: begin
                    if (index < K) begin
                        mac_a <= row_a[index * WIDTH_IN +: WIDTH_IN];
                        mac_b <= col_b[index * WIDTH_IN +: WIDTH_IN];
                        mac_valid_in <= 1;
                        index <= index + 1;
                    end else begin
                        mac_valid_in <= 0;
                        state <= DONE;
                        valid_out <= 1;
                    end
                end
                
                DONE: begin
                    if (!valid_in) begin
                        state <= IDLE;
                        valid_out <= 0;
                        mac_reset <= 1;
                    end
                end
            endcase
        end
    end

endmodule