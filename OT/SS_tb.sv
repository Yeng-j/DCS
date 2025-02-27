module SS_tb();
    // 時脈和重置信號
    logic clk;
    logic rst_n;
    
    // DUT的輸入信號
    logic in_valid;
    logic [15:0] matrix;
    logic matrix_size;
    
    // DUT的輸出信號
    logic out_valid;
    logic [39:0] out_value;
    
    // 時脈產生
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // DUT實例化
    SS dut(
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .matrix(matrix),
        .matrix_size(matrix_size),
        .out_valid(out_valid),
        .out_value(out_value)
    );
    
    // 測試向量
    initial begin
        // 初始化
        rst_n = 1;
        in_valid = 0;
        matrix = 0;
        matrix_size = 0;
        
        // 重置
        #10 rst_n = 0;
        #10 rst_n = 1;
        
        // 測試2x2矩陣
        #10;
        // 輸入W矩陣
        @(posedge clk);
        in_valid = 1;
        matrix_size = 0; // 2x2
        matrix = 16'd1;  // W[0][0]
        
        @(posedge clk);
        matrix = 16'd2;  // W[0][1]
        
        @(posedge clk);
        matrix = 16'd3;  // W[1][0]
        
        @(posedge clk);
        matrix = 16'd4;  // W[1][1]
        
        // 輸入X矩陣
        @(posedge clk);
        matrix = 16'd5;  // X[0][0]
        
        @(posedge clk);
        matrix = 16'd6;  // X[0][1]
        
        @(posedge clk);
        matrix = 16'd7;  // X[1][0]
        
        @(posedge clk);
        matrix = 16'd8;  // X[1][1]
        @(posedge clk);
        in_valid = 0;
        
        // 等待輸出
        wait(out_valid);
        repeat(3) @(posedge clk);
        
        // 測試4x4矩陣
        #20;
        @(posedge clk);
        in_valid = 1;
        matrix_size = 1; // 4x4
        
        // 輸入W矩陣 (16個值)
        for(int i=1; i<=16; i++) begin
            matrix = i;
            @(posedge clk);
        end
        
        // 輸入X矩陣 (16個值)
        for(int i=1; i<=16; i++) begin
            matrix = i;
            @(posedge clk);
        end
        in_valid = 0;
        
        // 等待輸出完成
        wait(out_valid);
        repeat(8) @(posedge clk);
        
        // 結束模擬
        #100;
        $finish;
    end
    
    // 監控輸出
    //  initial begin
    //    $monitor("Time=%0t out_valid=%b out_value=%d", $time, out_valid, out_value);
    //end
    

endmodule 