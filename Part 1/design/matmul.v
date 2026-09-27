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
    reg row_loaded;

    reg signed [WIDTH_OUT-1:0] acc;

    localparam IDLE = 2'd0;
    localparam PIPE = 2'd1;
    localparam DONE = 2'd2;
    reg [1:0] state;

    // Iterators
    reg [$clog2(M+1)-1:0] row_idx;
    reg [$clog2(N+1)-1:0] col_idx;
    reg [$clog2(K+2)-1:0] fetch_cnt;
    reg [ADDR_WIDTH_A-1:0] row_base_addr;

    wire signed [WIDTH_IN-1:0] data_a_use = row_loaded ? row_buffer[(fetch_cnt - 2) * WIDTH_IN +: WIDTH_IN] : data_a;

    always @(posedge clk) begin
        if (reset) begin
            addr_a <= 0;
            addr_b <= 0;
            addr_c <= 0;
            data_c <= 0;
            we_c <= 0;
            valid_out <= 0;
            acc <= 0;
            state <= IDLE;
            row_idx <= 0;
            col_idx <= 0;
            fetch_cnt <= 0;
            row_base_addr <= 0;
            row_loaded <= 0;
        end else begin
            we_c <= 0;
            if (we_c) addr_c <= addr_c + 1;
            case (state)
                IDLE: begin
                    valid_out <= 0;
                    acc <= 0;
                    row_idx <= 0;
                    col_idx <= 0;
                    fetch_cnt <= 0;
                    row_base_addr <= 0;
                    row_loaded <= 0;
                    if (valid_in) state <= PIPE;
                end

                PIPE: begin
                    if (fetch_cnt < K) begin
                        if (!row_loaded) addr_a <= (fetch_cnt == 0) ? row_base_addr : addr_a + 1;
                        addr_b <= (fetch_cnt == 0) ? col_idx : addr_b + N;
                    end
                    if (fetch_cnt >= 2) begin
                        if (!row_loaded) begin
                            row_buffer[(fetch_cnt - 2) * WIDTH_IN +: WIDTH_IN] <= data_a;
                        end
                        if (fetch_cnt == K + 1) begin
                            data_c <= acc + (data_a_use * data_b);
                            we_c <= 1;
                            acc <= 0;
                            if (col_idx == N - 1) begin
                                col_idx <= 0;
                                row_loaded <= 0;
                                if (row_idx == M - 1) begin
                                    state <= DONE;
                                end else begin
                                    row_idx <= row_idx + 1;
                                    row_base_addr <= row_base_addr + K;
                                end
                            end else begin
                                col_idx <= col_idx + 1;
                                row_loaded <= 1;
                            end
                        end else begin
                            acc <= acc + (data_a_use * data_b);
                        end
                    end
                    fetch_cnt <= (fetch_cnt == K + 1) ? 0 : fetch_cnt + 1;
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