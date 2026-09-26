module matmul #(
    parameter M = 8,
    parameter K = 8,
    parameter N = 8,
    parameter WIDTH_IN = 8,
    parameter WIDTH_OUT = 32,
    parameter ADDR_WIDTH_A = (M * K > 1) ? $clog2(M * K) : 1,
    parameter ADDR_WIDTH_B = (K * N > 1) ? $clog2(K * N) : 1,
    parameter ADDR_WIDTH_C = (M * N > 1) ? $clog2(M * N) : 1
) (
    input wire clk,
    input wire reset,
    input wire valid_in,
    output reg [ADDR_WIDTH_A-1:0] addr_a,        // A (Read Only)
    input wire signed [WIDTH_IN-1:0] data_a,
    output reg [ADDR_WIDTH_B-1:0] addr_b,        // B (Read Only)
    input wire signed [WIDTH_IN-1:0] data_b,
    output reg [ADDR_WIDTH_C-1:0] addr_c,        // C (Write Only)
    output reg signed [WIDTH_OUT-1:0] data_c,
    output reg we_c,
    
    output reg  valid_out
);

    reg signed [(K*WIDTH_IN)-1:0] row_buffer;
    reg signed [(K*WIDTH_IN)-1:0] col_buffer;

    reg dp_valid_in;
    wire dp_valid_out;
    reg dp_reset;
    wire signed [WIDTH_OUT-1:0] dp_result;

    reg row_loaded;

    dot_product #(
        .K(K),
        .WIDTH_IN(WIDTH_IN),
        .WIDTH_OUT(WIDTH_OUT)
    ) dp_engine (
        .clk(clk),
        .reset(dp_reset),
        .valid_in(dp_valid_in),
        .row_a(row_buffer),
        .col_b(col_buffer),
        .result(dp_result),
        .valid_out(dp_valid_out)
    );


    localparam IDLE = 3'd0;
    localparam FETCH = 3'd1;
    localparam START_DP = 3'd2;
    localparam WAIT_DP = 3'd3;
    localparam DONE = 3'd4;
               
    reg [2:0] state;

    // Iterators
    reg [$clog2(M+1)-1:0] row_idx;
    reg [$clog2(N+1)-1:0] col_idx;
    reg [$clog2(K+2)-1:0] fetch_cnt;
    reg [ADDR_WIDTH_A-1:0] row_base_addr;

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            row_idx <= 0;
            col_idx <= 0;
            fetch_cnt <= 0;
            we_c <= 0;
            valid_out <= 0;
            dp_valid_in <= 0;
            dp_reset <= 1;
            row_loaded <= 0;
            row_base_addr <= 0;
            addr_c <= 0;
        end else begin

            we_c <= 0;
            dp_reset <= 0;
            
            case (state)
                IDLE: begin
                    valid_out <= 0;
                    row_idx <= 0;
                    col_idx <= 0;
                    fetch_cnt <= 0;
                    row_loaded <= 0;
                    if (valid_in) state <= FETCH;
                end

                FETCH: begin
                    if (fetch_cnt < K) begin
                        if (!row_loaded) addr_a <= (fetch_cnt == 0) ? row_base_addr : addr_a + 1;
                        addr_b <= (fetch_cnt == 0) ? col_idx : addr_b + N;
                    end
                    if (fetch_cnt >= 2) begin
                        if (!row_loaded) row_buffer[(fetch_cnt - 2) * WIDTH_IN +: WIDTH_IN] <= data_a;
                        col_buffer[(fetch_cnt - 2) * WIDTH_IN +: WIDTH_IN] <= data_b;
                    end

                    if (fetch_cnt == K + 1) begin
                        fetch_cnt <= 0;
                        state <= START_DP;
                    end else begin
                        fetch_cnt <= fetch_cnt + 1;
                    end
                end
                
                START_DP: begin
                    dp_valid_in <= 1;
                    state <= WAIT_DP;
                end
                
                WAIT_DP: begin
                    if (dp_valid_out) begin
                        dp_valid_in <= 0;
                        dp_reset <= 1;
                        data_c <= dp_result;
                        we_c <= 1;
                        addr_c <= addr_c + 1; 

                        if (col_idx == N - 1) begin
                            col_idx <= 0;
                            row_loaded <= 0;

                            if (row_idx == M - 1) begin
                                state <= DONE;
                            end else begin
                                row_idx <= row_idx + 1;
                                row_base_addr <= row_base_addr + K;
                                state <= FETCH;
                            end
                        end else begin
                            col_idx <= col_idx + 1;
                            row_loaded <= 1;
                            state <= FETCH;
                        end
                    end
                end
                
                DONE: begin
                    valid_out <= 1;
                    if (!valid_in) begin 
                        valid_out <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule