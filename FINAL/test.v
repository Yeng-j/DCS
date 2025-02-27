module CNN(
    // Output Ports
    input                    clk,
    input                    rst_n,
    input                    in_valid,
    input      signed [15:0] in_data,
    input                    opt,
    // Input Ports
    output reg               out_valid, 
    output reg signed [15:0] out_data	
);

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter   IDLE = 0,
            READ = 1,
            CALC = 2,
            OUT  = 3;

genvar i;
//==============================================//
//       Wire and Register Declaration          //
//==============================================//
// state
reg [1:0] current_state, next_state;

// counter
reg [5:0] counter;

// row and column coordinate
reg [2:0] row,col;

// input register
reg opt_reg;
reg signed [15:0] feature_map[0:35];   
reg signed [15:0] kernel[0:8];  

// convolution result
reg signed [15:0] cnn_layer[0:15];

// relu result
reg signed [15:0] relu_layer[0:15];

// max pooling result
wire signed [15:0] pooling1 [0:7];
wire signed [15:0] pooling2 [0:3];

//==============================================//
//             Update Current State             //
//==============================================//
always @(posedge clk , negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

//==============================================//
//             Calculate Next State             //
//==============================================//
always @(*) begin
    case(current_state)
        IDLE: begin
            if(in_valid) next_state <= READ;
            else next_state <= IDLE;
        end
        // read (6*6 image) + (3*3 kernel) = 45 cycles
        READ: begin
            if(counter == 44) next_state <= CALC;
            else next_state <= READ;
        end
        // do convolution in 16 cycles
        CALC: begin
            if(counter == 16) next_state <= OUT;
            else next_state <= CALC;
        end
        // output in 4 cycles
        OUT: begin
            if(counter == 3) next_state <= IDLE;
            else next_state <= OUT;
        end
    // default: next_state <= IDLE; // illigal state
    endcase
end

//==============================================//
//                Counter                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter <= 0;
    // READ -> CALC state
	end else if(counter == 44 && current_state == READ) begin
		counter <= 0;
    // CALC -> OUT state
	end else if(counter == 16 && current_state == CALC) begin
		counter <= 0;
    end else if(in_valid) begin
		counter <= counter + 1;
	end else if(current_state == CALC || current_state == OUT) begin
		counter <= counter + 1;
    // OUT -> IDLE state
    end else begin
		counter <= 0;
	end
end

//==============================================//
//                  Read Data                   //
//==============================================//
// 1-bit option
always @(posedge clk) begin
    if(in_valid && counter == 0)begin
        opt_reg <= opt;
    end
end

// 6*6 feature map
always @(posedge clk) begin
	if(in_valid && (counter < 36 && counter >= 0))begin
        feature_map[counter] <= in_data;
    end
end

// 3*3 kernel
always @(posedge clk) begin
    if(in_valid && (counter < 45 && counter >= 36))begin
        kernel[counter - 36] <= in_data;
    end
end

//==============================================//
//           Update Current Position            //
//==============================================//
always @(posedge clk) begin
	if(current_state == IDLE)begin
        row <= 0;
        col <= 0;
    // next row
    end else if(col == 3 && current_state == CALC)begin
        row <= row + 1;
        col <= 0;
    // shift right
	end else if(current_state == CALC)begin
		row <= row;
        col <= col + 1;
	end
end

//==============================================//
//        Convoultion in 9 * 9 block            //
//==============================================//
always @(posedge clk) begin
    if(counter < 16 && current_state == CALC)begin
        cnn_layer[counter] <=   kernel[0] * feature_map[row    *6 + col]
                            +   kernel[1] * feature_map[row    *6 + col+1]
                            +   kernel[2] * feature_map[row    *6 + col+2]
                            +   kernel[3] * feature_map[(row+1)*6 + col]
                            +   kernel[4] * feature_map[(row+1)*6 + col+1]
                            +   kernel[5] * feature_map[(row+1)*6 + col+2]
                            +   kernel[6] * feature_map[(row+2)*6 + col]
                            +   kernel[7] * feature_map[(row+2)*6 + col+1]
                            +   kernel[8] * feature_map[(row+2)*6 + col+2];
    end
end

//==============================================//
//           ReLu Activation Function           //
//==============================================//
generate
for(i = 0; i < 16; i = i + 1)begin
    always @(posedge clk) begin
        if(opt_reg == 0 && cnn_layer[i][15] == 1)begin
            relu_layer[i] <= 0;
        end else begin
            relu_layer[i] <= cnn_layer[i];      
        end
    end
end
endgenerate

//==============================================//
//                 Max Pooling                  //
//==============================================//
// first compare
assign pooling1[0] = (relu_layer[ 0] > relu_layer[ 1])? relu_layer[ 0]:relu_layer[ 1];
assign pooling1[1] = (relu_layer[ 2] > relu_layer[ 3])? relu_layer[ 2]:relu_layer[ 3];
assign pooling1[2] = (relu_layer[ 4] > relu_layer[ 5])? relu_layer[ 4]:relu_layer[ 5];
assign pooling1[3] = (relu_layer[ 6] > relu_layer[ 7])? relu_layer[ 6]:relu_layer[ 7];
assign pooling1[4] = (relu_layer[ 8] > relu_layer[ 9])? relu_layer[ 8]:relu_layer[ 9];
assign pooling1[5] = (relu_layer[10] > relu_layer[11])? relu_layer[10]:relu_layer[11];
assign pooling1[6] = (relu_layer[12] > relu_layer[13])? relu_layer[12]:relu_layer[13];
assign pooling1[7] = (relu_layer[14] > relu_layer[15])? relu_layer[14]:relu_layer[15];

// second compare
assign pooling2[0] = (pooling1[0] > pooling1[2])? pooling1[0]:pooling1[2];
assign pooling2[1] = (pooling1[1] > pooling1[3])? pooling1[1]:pooling1[3];
assign pooling2[2] = (pooling1[4] > pooling1[6])? pooling1[4]:pooling1[6];
assign pooling2[3] = (pooling1[5] > pooling1[7])? pooling1[5]:pooling1[7];

//==============================================//
//             Output Logic                     //
//==============================================//
// output valid
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out_valid <= 0;
    end else if(current_state == OUT)begin
        out_valid <= 1;
    end else begin
        out_valid <= 0;
    end
end

// output data
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out_data <= 0;
    end else if(current_state == OUT)begin
        out_data <= pooling2[counter];
    end else begin
        out_data <= 0;
    end
end

endmodule