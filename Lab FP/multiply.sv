module multiply(
		a_reg, b_reg,
		out_multiply
);
input [15:0] a_reg, b_reg;
output logic [15:0] out_multiply;

logic a_sign, b_sign, sign;
logic signed [8:0] a_exp, b_exp;
logic signed [9:0] out_exp;
logic signed [10:0] exp;
logic [7:0] a_frac, b_frac;
logic [15:0] result, result_shift1;
logic [6:0] result_shift;

assign a_sign = a_reg[15];
assign b_sign = b_reg[15];
assign a_exp = ({1'b0, a_reg[14:7]}) - ({2'b00, 7'd127});	
assign b_exp = ({1'b0, b_reg[14:7]}) - ({2'b00, 7'd127});	
	
assign a_frac = {1'b1, a_reg[6:0]};
assign b_frac = {1'b1, b_reg[6:0]};	

assign result = a_frac * b_frac;

always_comb
	casez(result)
		16'b1???????????????:	begin
								result_shift1 = result << 1;
								out_exp = a_exp + b_exp + 2'b01;
								end
		16'b01??????????????: 	begin
								result_shift1 = result << 2;
								out_exp = a_exp + b_exp;
								end
		16'b001?????????????:	begin
								result_shift1 = result << 3;
								out_exp = a_exp + b_exp - (2'b01);
								end
		16'b0001????????????:	begin
								result_shift1 = result << 4;
								out_exp = a_exp + b_exp - (3'b010);
								end
		16'b00001???????????:	begin
								result_shift1 = result << 5;
								out_exp = a_exp + b_exp - (3'b011);
								end
		16'b000001??????????:	begin
								result_shift1 = result << 6;
								out_exp = a_exp + b_exp - (4'b0100); 
								end
		16'b0000001?????????:	begin
								result_shift1 = result << 7;
								out_exp = a_exp + b_exp - (4'b0101);
								end
		16'b00000001????????:	begin
								result_shift1 = result << 8;
								out_exp = a_exp + b_exp - (4'b0110);
								end
		16'b000000001???????:	begin
								result_shift1 = result << 9;
								out_exp = a_exp + b_exp - (4'b0111);
								end
		16'b0000000001??????:	begin
								result_shift1 = result << 10;
								out_exp = a_exp + b_exp - (5'b01000);
								end
		16'b00000000001?????:	begin
								result_shift1 = result << 11;
								out_exp = a_exp + b_exp - (5'b01001);
								end
		16'b000000000001????:	begin
								result_shift1 = result << 12;
								out_exp = a_exp + b_exp - (5'b01010);
								end
		16'b0000000000001???:	begin
								result_shift1 = result << 13;
								out_exp = a_exp + b_exp - (5'b01011);
								end
		16'b00000000000001??:	begin
								result_shift1 = result << 14;
								out_exp = a_exp + b_exp - (5'b01100);
								end
		16'b000000000000001?:	begin
								result_shift1 = result << 15;
								out_exp = a_exp + b_exp - (5'b01101);
								end
		16'b0000000000000001:	begin
								result_shift1 = result << 16;					
								out_exp = a_exp + b_exp - (5'b01110);
								end
		16'b0000000000000000:	begin
								result_shift1 = 9'b0;
								out_exp = a_exp + b_exp;
								end
		default:				begin
								result_shift1 = 9'b0;
								out_exp = a_exp + b_exp;
								end
	endcase
	
assign result_shift[6:0] = result_shift1[15:9];
assign exp = out_exp + {1'b0, 7'd127};
assign sign = a_sign ^ b_sign;
assign out_multiply = {sign, exp[7:0], result_shift};

endmodule 