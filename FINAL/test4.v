module test4 #(
           parameter DATA_WIDTH = 8,
           parameter IMG_SIZE = 5,
           parameter FILTER_SIZE = 3
       )(
           input wire clk,
           input wire rst_n,
           input wire [DATA_WIDTH-1:0] filter [0:FILTER_SIZE-1][0:FILTER_SIZE-1],
           input wire [DATA_WIDTH-1:0] padded_img [0:IMG_SIZE+FILTER_SIZE-2][0:IMG_SIZE+FILTER_SIZE-2],
           input wire img_valid,
           output reg [DATA_WIDTH*2-1:0] conv_out,
           output reg conv_valid
       );

// 定義參數
localparam PADDING = (FILTER_SIZE-1)/2;
localparam OUTPUT_SIZE = IMG_SIZE;

// 計數器
reg [$clog2(OUTPUT_SIZE)-1:0] out_row, out_col;
reg [$clog2(FILTER_SIZE)-1:0] filter_row, filter_col;

// 暫存計算結果
reg [DATA_WIDTH*2-1:0] temp_sum;

// 狀態機
reg [1:0] state;
localparam IDLE = 2'b00;
localparam CALC = 2'b01;
localparam OUTPUT = 2'b10;

// 控制邏輯和計算
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        out_row <= 0;
        out_col <= 0;
        filter_row <= 0;
        filter_col <= 0;
        temp_sum <= 0;
        conv_out <= 0;
        conv_valid <= 0;
        state <= IDLE;
    end
    else
    begin
        case (state)
            IDLE:
            begin
                if (img_valid)
                begin
                    state <= CALC;
                    temp_sum <= 0;
                    filter_row <= 0;
                    filter_col <= 0;
                    conv_valid <= 0;
                end
            end

            CALC:
            begin
                // 進行卷積計算
                temp_sum <= temp_sum +
                padded_img[out_row + filter_row][out_col + filter_col] *
                filter[filter_row][filter_col];

                // 更新filter位置
                if (filter_col == FILTER_SIZE-1)
                begin
                    filter_col <= 0;
                    if (filter_row == FILTER_SIZE-1)
                    begin
                        state <= OUTPUT;
                    end
                    else
                    begin
                        filter_row <= filter_row + 1;
                    end
                end
                else
                begin
                    filter_col <= filter_col + 1;
                end
            end

            OUTPUT:
            begin
                // 輸出結果
                conv_out <= temp_sum;
                conv_valid <= 1;

                // 更新輸出位置
                if (out_col == OUTPUT_SIZE-1)
                begin
                    out_col <= 0;
                    if (out_row == OUTPUT_SIZE-1)
                    begin
                        out_row <= 0;
                    end
                    else
                    begin
                        out_row <= out_row + 1;
                    end
                end
                else
                begin
                    out_col <= out_col + 1;
                end

                // 準備下一次計算
                state <= IDLE;
                temp_sum <= 0;
                filter_row <= 0;
                filter_col <= 0;
            end
        endcase
    end
end

endmodule
