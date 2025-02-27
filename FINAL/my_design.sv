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

parameter [1:0] IDLE = 0, FILTER = 1, IMAGE = 2, CONV = 3;
logic [1:0] state, state_nxt;
logic [2:0] counter, counter_nxt;

logic signed [7:0] filter [0:4][0:4];
logic signed [7:0] filter_nxt [0:4][0:4];

logic signed [7:0] image_buffer [0:4][0:11];
logic signed [7:0] image_buffer_nxt [0:4][0:11];

logic filter_size_reg, pad_mode_reg, act_mode_reg;
logic filter_size_reg_nxt, pad_mode_reg_nxt, act_mode_reg_nxt;

logic [3:0] image_size_reg;

logic [2:0] row_cnt, col_cnt;
logic [2:0] row_cnt_nxt, col_cnt_nxt;

integer i, j;

always_comb begin
    case(state)
        IDLE: begin
            if(filter_valid) begin
                filter_size_reg_nxt = filter_size;
				pad_mode_reg_nxt 	= pad_mode;
				act_mode_reg_nxt 	= act_mode;
				image_size_reg_nxt 	= image_size;

                state_nxt = FILTER;
            end
        end
        FILTER: begin
            if(filter_size) begin
                for(i = 0; i < 5; i++) begin
                    for(j = 0; j < 5; j++) begin
                        filter_nxt[i][j] = in_data;
                    end
                end
            end
            else begin
                for(i = 0; i < 3; i++) begin
                    for(j = 0; j < 3; j++) begin
                        filter_nxt[i][j] = in_data;
                    end
                end
            end
            if(image_valid) begin
                state_nxt = IMAGE;
            else begin
                state_nxt = FILTER;
            end
            end
        end
        IMAGE: begin
            case(image_size)
                4'd3: if(pad_mode_reg) begin
                    
                    
                    end
                    else begin
                        // 上方padding零
                        for(i = 0; i < 5; i++) begin
                            image_buffer_nxt[0][i] = 8'd0;
                        end
                        // 左右padding零
                        for(i = 1; i < 4; i++) begin
                            image_buffer_nxt[i][0] = 8'd0;
                            image_buffer_nxt[i][4] = 8'd0;
                        end
                        // 下方padding零
                        for(i = 0; i < 5; i++) begin
                            image_buffer_nxt[4][i] = 8'd0;
                        end
                        if (row_cnt < 3 && col_cnt < 3) begin
                        // 更新image buffer
                            image_buffer_nxt[row_cnt+1][col_cnt+1] = in_data;                            
                            // 更新計數器
                            if (col_cnt == 2) begin
                                col_cnt_nxt = 0;
                                row_cnt_nxt = row_cnt + 1;
                            end else begin
                                col_cnt_nxt = col_cnt + 1;
                                row_cnt_nxt = row_cnt;
                            end
                        end
                    end
            endcase
        end
        CONV: begin

        end


            



    endcase
end

always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        
        row_cnt <= 0;
        col_cnt <= 0;
    end else begin
        
        row_cnt <= row_cnt_nxt;
        col_cnt <= col_cnt_nxt;
    end
end


endmodule
