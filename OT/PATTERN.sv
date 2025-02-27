module PATTERN(
    // Output signals
    output logic          clk,
    output logic          rst_n,
    output logic          in_valid,
    output logic [15:0]    matrix ,
    output logic     matrix_size,
    // Input signals
    input  logic          out_valid,
    input  logic [39:0]   out_value
);
    parameter PATNUM = 1000;
    // 變數宣告
    integer latency;
    integer total_latency;
    integer patcount;
    integer cycles;
    integer i, j;
    integer out_valid_cycles;
    integer matrix_size_current;
    integer total_cycles;
    logic [15:0] weight_matrix [0:3][0:3];
    logic [15:0] input_matrix [0:3][0:3];
    
    // 時脈產生器，週期為5ns
    initial begin
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        // 初始化
        reset_signal();
        
        // 執行測試案例
        for(patcount = 0; patcount < PATNUM; patcount = patcount + 1) begin
            matrix_size = $random() % 2;
            total_cycles = (matrix_size == 1'b0) ? 8 : 32;  // 2x2需要8個週期，4x4需要32個週期
            
            // 初始化 weight 和 input matrix
            if(matrix_size == 1'b0) begin  // 2x2 matrix
                for(i = 0; i < 2; i = i + 1) begin
                    for(j = 0; j < 2; j = j + 1) begin
                        weight_matrix[i][j] = $random() % 256;  // 假設數值範圍為 0-255
                        input_matrix[i][j] = $random() % 256;
                    end
                end
            end
            else begin  // 4x4 matrix
                for(i = 0; i < 4; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        weight_matrix[i][j] = $random() % 256;
                        input_matrix[i][j] = $random() % 256;
                    end
                end
            end

            // 開始輸入資料
            @(negedge clk);
            in_valid = 1'b1;
            
            // 輸入 weight matrix (第一半週期)
            if(matrix_size == 1'b0) begin  // 2x2 matrix
                for(i = 0; i < 2; i = i + 1) begin
                    for(j = 0; j < 2; j = j + 1) begin
                        matrix = weight_matrix[i][j];
                        @(negedge clk);
                    end
                end
                // 輸入 input matrix (第二半週期)
                for(i = 0; i < 2; i = i + 1) begin
                    for(j = 0; j < 2; j = j + 1) begin
                        matrix = input_matrix[i][j];
                        @(negedge clk);
                    end
                end
            end
            else begin  // 4x4 matrix
                for(i = 0; i < 4; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        matrix = weight_matrix[i][j];
                        @(negedge clk);
                    end
                end
                // 輸入 input matrix (第二半週期)
                for(i = 0; i < 4; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        matrix = input_matrix[i][j];
                        @(negedge clk);
                    end
                end
            end
            
            in_valid = 1'b0;
            matrix = 'dx;  // 設為不定值
            
            // 計算延遲時間
            latency = 0;
            while(!out_valid) begin
                latency = latency + 1;
                if(latency > 20) begin
                    $display("Error! Latency exceeds 20 cycles!");
                    $finish;
                end
                @(negedge clk);
            end
            
            // 檢查out_valid的持續時間
            out_valid_cycles = 0;
            while(out_valid) begin
                out_valid_cycles = out_valid_cycles + 1;
                if(out_valid_cycles > 7) begin
                    $display("Error! out_valid remains high for too long!");
                    $finish;
                end
                if(out_value === 0) begin
                    $display("Error! out_value should not be 0 when out_valid is high!");
                    $finish;
                end
                @(negedge clk);
            end
            
            if(out_valid_cycles != 3 && out_valid_cycles != 7) begin
                $display("Error! out_valid must be high for exactly 3 or 7 cycles!");
                $finish;
            end
            
            // 確認out_value在out_valid為低時為0
            if(out_value !== 0) begin
                $display("Error! out_value should be 0 when out_valid is low!");
                $finish;
            end
            
            total_latency = total_latency + latency;
        end
        
        // 顯示測試結果
        $display("All patterns have been completed!");
        $display("Average latency: %d cycles", total_latency/PATNUM);
        $finish;
    end
    
    // 重置信號的任務
    task reset_signal; begin
        rst_n = 1;
        in_valid = 0;
        matrix_size = 'dx;
        matrix = 'dx;    // 直接將16位元的matrix設為不定值
        
        #1;
        rst_n = 0;
        #4;
        rst_n = 1;
    end
    endtask

    // 檢查時序
    property check_out_valid_timing;
        @(posedge clk) in_valid |-> !out_valid;
    endproperty
    assert property (check_out_valid_timing)
    else begin
        $display("Error! out_valid should not be high when in_valid is high!");
        $finish;
    end

endmodule 