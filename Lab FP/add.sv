module add(
		a_reg, b_reg, 
		out_add
);
input [15:0] a_reg, b_reg;
output logic [15:0] out_add;

logic a_sign, b_sign, sign;
logic signed [9:0] a_exp, b_exp, max_exp;
logic [7:0] a_frac, b_frac;
logic [8:0] a_frac_comp, b_frac_comp, a_frac_shift, b_frac_shift;
logic [8:0] sum;
logic [8:0] sum_comp;
logic [8:0] sum_shift1;
logic [6:0] sum_shift;
logic signed [10:0] out_exp;
logic signed [11:0] exp;

assign a_sign = a_reg[15];
assign b_sign = b_reg[15];
assign a_exp = ({1'b0, a_reg[14:7]}) - ({1'b0, 7'd127});	
assign b_exp = ({1'b0, b_reg[14:7]}) - ({1'b0, 7'd127});
assign a_frac = {1'b1, a_reg[6:0]};
assign b_frac = {1'b1, b_reg[6:0]};

assign max_exp = (a_exp > b_exp) ? a_exp : b_exp;

always_comb
	if(a_sign)
		a_frac_comp = ~{1'b0, a_frac_shift} + 1'b1;
	else
		a_frac_comp = {1'b0, a_frac_shift};
	
always_comb
	if(b_sign)
		b_frac_comp = ~{1'b0, b_frac_shift} + 1'b1;
	else
		b_frac_comp = {1'b0, b_frac_shift};

always_comb
	if(a_exp < max_exp)
		a_frac_shift = a_frac >> (max_exp - a_exp);
	else	
		a_frac_shift = a_frac;
		
always_comb
	if(b_exp < max_exp)
		b_frac_shift = b_frac >> (max_exp - b_exp);
	else
		b_frac_shift = b_frac;

assign sum = a_frac_comp + b_frac_comp;

always_comb
	if(a_sign == 1'b0 && b_sign == 1'b0)
		sign = 1'b0;
	else if(a_sign == 1'b1 && b_sign == 1'b1)
		sign = 1'b1;
	else if(a_sign == 1'b1 && b_sign == 1'b0 && a_frac_shift > b_frac_shift)
		sign = 1'b1;
	else if(a_sign == 1'b0 && b_sign == 1'b1 && a_frac_shift < b_frac_shift)
		sign = 1'b1;
	else
		sign = 1'b0;

always_comb
	if(sign)
		sum_comp = ~sum + 1'b1;
	else
		sum_comp = sum;

always_comb
	casez(sum_comp)
		9'b1????????: 	begin
						sum_shift1 = sum_comp << 1;
						out_exp = max_exp + 2'b01;
						end
		9'b01???????:	begin
						sum_shift1 = sum_comp << 2;
						out_exp = max_exp;
						end
		9'b001??????:	begin
						sum_shift1 = sum_comp << 3;
						out_exp = max_exp - 2'b01;
						end
		9'b0001?????:	begin	
						sum_shift1 = sum_comp << 4;
						out_exp = max_exp - 3'b010;
						end
		9'b00001????:	begin
						sum_shift1 = sum_comp << 5;
						out_exp = max_exp - 3'b011;
						end
		9'b000001???:	begin
						sum_shift1 = sum_comp << 6;
						out_exp = max_exp - 4'b0100;
						end
		9'b0000001??:	begin
						sum_shift1 = sum_comp << 7;
						out_exp = max_exp - 4'b0101;
						end
		9'b00000001?:	begin
						sum_shift1 = sum_comp << 8;
						out_exp = max_exp - 4'b0110;
						end
		9'b000000001:	begin
						sum_shift1 = sum_comp << 9;
						out_exp = max_exp - 4'b0111;
						end
		9'b000000000:	begin
						sum_shift1 = 9'b0;
						out_exp = max_exp;
						end
		default:		begin
						sum_shift1 = 9'b0;
						out_exp = max_exp;
						end
	endcase

assign sum_shift = sum_shift1[8:2];
assign exp = out_exp + {1'b0, 7'd127};
assign out_add = {sign, exp[7:0], sum_shift};

endmodule