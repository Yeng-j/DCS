module Conv(
	// Input signals
	clk,
	rst_n,
	filter_valid,
	image_valid,
	filter_size,
	image_size,
	pad_mode,
	act_mode,
	in_data,
	// Output signals
	out_valid,
	out_data
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, image_valid, filter_valid, filter_size, pad_mode, act_mode;
input [3:0] image_size;
input signed [7:0] in_data;
output logic out_valid;
output logic signed [15:0] out_data;

//---------------------------------------------------------------------
//   Your design                       
//---------------------------------------------------------------------
logic
// 狀態機
logic [1:0] state;
parameter IDLE = 2'b00;
parameter CALC = 2'b01;
parameter OUTPUT = 2'b10;


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


endmodule