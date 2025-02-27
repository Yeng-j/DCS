module test3 #(
           parameter DATA_WIDTH = 8,
           parameter IMG_SIZE = 5,    // 可以是 3, 5, 6, 7
           parameter FILTER_SIZE = 3  // 可以是 3 或 5
       )(
           input wire clk,
           input wire rst_n,
           input wire [DATA_WIDTH-1:0] data_in,
           input wire data_valid,
           input wire pad_mode,       // 0: zero padding, 1: replication padding
           output reg [DATA_WIDTH-1:0] data_out,
           output reg out_valid
       );
//--------------------------------
//寫一個input 可以允許 3*3 5*5 6*6 7*7，
//且可以依據filter_size決定filter大小為3*3 或 5*5，
//而輸入的訊號根據filter大小做zero_padding
//--------------------------------



// 計算填充大小
localparam PADDING = (FILTER_SIZE-1)/2;
// 計算填充後的圖像大小
localparam PADDED_SIZE = IMG_SIZE + 2*PADDING;

// 用於儲存填充後的圖像
reg [DATA_WIDTH-1:0] padded_img [0:PADDED_SIZE-1][0:PADDED_SIZE-1];

// 計數器
reg [$clog2(IMG_SIZE)-1:0] row_cnt, col_cnt;

// 初始化和填充邏輯
integer i, j;
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        // 重置所有變數
        row_cnt <= 0;
        col_cnt <= 0;
        out_valid <= 0;

        // 初始化填充區域為0
        for (i = 0; i < PADDED_SIZE; i = i + 1)
        begin
            for (j = 0; j < PADDED_SIZE; j = j + 1)
            begin
                padded_img[i][j] <= 0;
            end
        end
    end
    else if (data_valid)
    begin
        // 將輸入數據存入適當位置（跳過填充區域）
        padded_img[PADDING + row_cnt][PADDING + col_cnt] <= data_in;

        // Replication padding：複製邊緣像素
        if (pad_mode)
        begin
            // 更新上方填充區域
            if (row_cnt == 0)
            begin
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    padded_img[i][PADDING + col_cnt] <= data_in;
                end
            end
            // 更新下方填充區域
            if (row_cnt == IMG_SIZE-1)
            begin
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    padded_img[PADDING + IMG_SIZE + i][PADDING + col_cnt] <= data_in;
                end
            end
            // 更新左側填充區域
            if (col_cnt == 0)
            begin
                for (j = 0; j < PADDING; j = j + 1)
                begin
                    padded_img[PADDING + row_cnt][j] <= data_in;
                end
            end
            // 更新右側填充區域
            if (col_cnt == IMG_SIZE-1)
            begin
                for (j = 0; j < PADDING; j = j + 1)
                begin
                    padded_img[PADDING + row_cnt][PADDING + IMG_SIZE + j] <= data_in;
                end
            end
            // 更新角落區域
            if (row_cnt == 0 && col_cnt == 0)
            begin  // 左上角
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    for (j = 0; j < PADDING; j = j + 1)
                    begin
                        padded_img[i][j] <= data_in;
                    end
                end
            end
            if (row_cnt == 0 && col_cnt == IMG_SIZE-1)
            begin  // 右上角
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    for (j = 0; j < PADDING; j = j + 1)
                    begin
                        padded_img[i][PADDING + IMG_SIZE + j] <= data_in;
                    end
                end
            end
            if (row_cnt == IMG_SIZE-1 && col_cnt == 0)
            begin  // 左下角
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    for (j = 0; j < PADDING; j = j + 1)
                    begin
                        padded_img[PADDING + IMG_SIZE + i][j] <= data_in;
                    end
                end
            end
            if (row_cnt == IMG_SIZE-1 && col_cnt == IMG_SIZE-1)
            begin  // 右下角
                for (i = 0; i < PADDING; i = i + 1)
                begin
                    for (j = 0; j < PADDING; j = j + 1)
                    begin
                        padded_img[PADDING + IMG_SIZE + i][PADDING + IMG_SIZE + j] <= data_in;
                    end
                end
            end
        end

        // 更新計數器
        if (col_cnt == IMG_SIZE-1)
        begin
            col_cnt <= 0;
            if (row_cnt == IMG_SIZE-1)
                row_cnt <= 0;
            else
                row_cnt <= row_cnt + 1;
        end
        else
        begin
            col_cnt <= col_cnt + 1;
        end
    end
end

endmodule
