module SS(
// input signals
    clk,
    rst_n,
    in_valid,
    matrix,
    matrix_size,
// output signals
    out_valid,
    out_value   
);
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
input               clk, rst_n, in_valid;
input        [15:0] matrix;
input               matrix_size;

output logic        out_valid;
output logic [39:0] out_value;

logic out_valid_nxt;
logic [39:0] out_value_nxt;

parameter [4:0] IDLE = 0, DATA_2 = 1, DATA_4 = 2, 
                CALC2 = 3, CALC4 = 4, OUT2 = 5, OUT4 = 6;

logic [4:0] state, state_nxt;
logic mtx_size, mtx_size_nxt;
logic [5:0] counter, counter_nxt;

// 權重矩陣 W
logic [39:0] W [0:3][0:3];
logic [39:0] W_nxt [0:3][0:3];

// 輸入矩陣 X
logic [39:0] X [0:3][0:3];
logic [39:0] X_nxt [0:3][0:3];

// Systolic array 的暫存器 Y_r
logic [39:0] Y_r [0:3][0:3];
logic [39:0] Y_r_nxt [0:3][0:3];

// Systolic array 的計算結果 Y
logic [39:0] Y [0:3][0:3];
logic [39:0] Y_nxt [0:3][0:3];

// Systolic array 的輸入
logic [39:0] Y_in [0:3];

// 輸出緩衝區
logic [39:0] out_buffer [0:6];
logic [39:0] out_buffer_nxt [0:6];

// 主要控制邏輯
always_comb begin
    state_nxt = state;
    mtx_size_nxt = mtx_size;
    counter_nxt = counter;

    out_valid_nxt = 0;
    out_value_nxt = 0;

    Y_in[0] = 0;
    Y_in[1] = 0;
    Y_in[2] = 0;
    Y_in[3] = 0;

    // 預設值賦值
    for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
            W_nxt[i][j] = W[i][j];
            X_nxt[i][j] = X[i][j];
        end
    end

    case (state)
        IDLE: begin
            if (in_valid) begin
                mtx_size_nxt = matrix_size;
                W_nxt[0][0] = matrix;
                counter_nxt = 0;
                state_nxt = matrix_size ? DATA_4 : DATA_2;
            end
        end

        DATA_2: begin
            counter_nxt = counter + 1;
            case (counter)
                0: W_nxt[0][1] = matrix;
                1: W_nxt[1][0] = matrix;
                2: W_nxt[1][1] = matrix;
                3: X_nxt[0][0] = matrix;
                4: X_nxt[0][1] = matrix;
                5: X_nxt[1][0] = matrix;
                6: begin
                    X_nxt[1][1] = matrix;
                    state_nxt = CALC2;
                    counter_nxt = 0;
                end
            endcase
        end

        DATA_4: begin
            counter_nxt = counter + 1;
            if (counter < 15)
                W_nxt[counter[3:2]][counter[1:0]] = matrix;
            else if (counter < 31) begin
                X_nxt[(counter-16)/4][(counter-16)%4] = matrix;
            end
            else begin
                X_nxt[3][3] = matrix;
                state_nxt = CALC4;
                counter_nxt = 0;
            end
        end

        CALC2: begin
            counter_nxt = counter + 1;
            case(counter)
                0: Y_in[0] = X[0][0];
                1: begin
                    Y_in[0] = X[1][0];
                    Y_in[1] = X[0][1];
                end
                2: begin
                    Y_in[1] = X[1][1];
                    out_buffer_nxt[0] = Y[1][0] + Y[1][1];
                end
                3: out_buffer_nxt[1] = Y[1][0] + Y[1][1];
                4: begin
                    out_buffer_nxt[2] = Y[1][0] + Y[1][1];
                    state_nxt = OUT2;
                    counter_nxt = 0;
                end
            endcase
        end

        CALC4: begin
            counter_nxt = counter + 1;
            case(counter)
                0: Y_in[0] = X[0][0];
                1: begin
                    Y_in[0] = X[1][0];
                    Y_in[1] = X[0][1];
                end
                2: begin
                    Y_in[0] = X[2][0];
                    Y_in[1] = X[1][1];
                    Y_in[2] = X[0][2];
                end
                3: begin
                    Y_in[0] = X[3][0];
                    Y_in[1] = X[2][1];
                    Y_in[2] = X[1][2];
                    Y_in[3] = X[0][3];
                end
                4: begin
                    Y_in[1] = X[3][1];
                    Y_in[2] = X[2][2];
                    Y_in[3] = X[1][3];
                    out_buffer_nxt[0] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                end
                5: begin
                    Y_in[2] = X[3][2];
                    Y_in[3] = X[2][3];
                    out_buffer_nxt[1] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                end
                6: begin
                    Y_in[3] = X[3][3];
                    out_buffer_nxt[2] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                end
                7: out_buffer_nxt[3] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                8: out_buffer_nxt[4] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                9: out_buffer_nxt[5] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                10: begin
                    out_buffer_nxt[6] = Y[3][0] + Y[3][1] + Y[3][2] + Y[3][3];
                    state_nxt = OUT4;
                    counter_nxt = 0;
                end
            endcase
        end

        OUT2: begin
            counter_nxt = counter + 1;
            out_valid_nxt = 1;
            case (counter)
                0: out_value_nxt = out_buffer[0];
                1: out_value_nxt = out_buffer[1];
                2: begin
                    out_value_nxt = out_buffer[2];
                    state_nxt = IDLE;
                end
            endcase
        end

        OUT4: begin
            counter_nxt = counter + 1;
            out_valid_nxt = 1;
            case (counter)
                0: out_value_nxt = out_buffer[0];
                1: out_value_nxt = out_buffer[1];
                2: out_value_nxt = out_buffer[2];
                3: out_value_nxt = out_buffer[3];
                4: out_value_nxt = out_buffer[4];
                5: out_value_nxt = out_buffer[5];
                6: begin
                    out_value_nxt = out_buffer[6];
                    state_nxt = IDLE;
                end
            endcase
        end
    endcase
end

// Systolic Array 計算邏輯
always_comb begin
    // 移位暫存器邏輯
    for (int i = 0; i < 4; i++) begin
        Y_r_nxt[i][0] = Y_in[i];
        for (int j = 1; j < 4; j++) begin
            Y_r_nxt[i][j] = Y_r[i][j-1];
        end
    end

    // PE 陣列計算
    for (int i = 0; i < 4; i++) begin
        for (int j = 0; j < 4; j++) begin
            if (i == 0)
                Y_nxt[i][j] = W[i][j] * Y_r_nxt[i][j];
            else
                Y_nxt[i][j] = Y[i-1][j] + W[i][j] * Y_r_nxt[i][j];
        end
    end
end

// 時序邏輯
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
        out_value <= 0;
        state <= IDLE;
        mtx_size <= 0;
        counter <= 0;

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                W[i][j] <= 0;
                X[i][j] <= 0;
                Y_r[i][j] <= 0;
                Y[i][j] <= 0;
            end
        end

        for (int i = 0; i < 7; i++) begin
            out_buffer[i] <= 0;
        end
    end
    else begin
        out_valid <= out_valid_nxt;
        out_value <= out_value_nxt;
        state <= state_nxt;
        mtx_size <= mtx_size_nxt;
        counter <= counter_nxt;

        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                W[i][j] <= W_nxt[i][j];
                X[i][j] <= X_nxt[i][j];
                Y_r[i][j] <= Y_r_nxt[i][j];
                Y[i][j] <= Y_nxt[i][j];
            end
        end

        for (int i = 0; i < 7; i++) begin
            out_buffer[i] <= out_buffer_nxt[i];
        end
    end
end

endmodule