module Fpc(
// input signals
clk,
rst_n,
in_valid,
in_a,
in_b,
mode,
// output signals
out_valid,
out
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input clk, rst_n, in_valid, mode;
input [15:0] in_a, in_b;
output logic out_valid;
output logic [15:0] out;

//---------------------------------------------------------------------
//   Your design                       
//---------------------------------------------------------------------
logic out_valid_comb;
logic [15:0] out_comb, out_add, out_multiply;
logic [15:0] a_reg, b_reg, a_reg_comb, b_reg_comb;
logic mode_reg, mode_reg_comb;

logic [1:0] state, next_state;
parameter S_idle = 2'd0;
parameter S_in = 2'd1;
parameter S_out = 2'd2;

always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		state <= S_idle;
	else
		state <= next_state;

always_comb
	case(state)
		S_idle:	next_state = in_valid ? S_in : S_idle;
		S_in : 	next_state = S_out;
		S_out:	next_state = in_valid ? S_in : S_idle;
		default:next_state = S_idle;
	endcase
	
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		out_valid <= 1'b0;
	else
		out_valid <= out_valid_comb;
	
always_comb
	if(next_state == S_out)
		out_valid_comb = 1'b1;
	else
		out_valid_comb = 1'b0;

always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		a_reg <= 16'b0;
	else
		a_reg <= a_reg_comb;
		
always_comb
	if(next_state == S_in)
		a_reg_comb = in_a;
	else
		a_reg_comb = a_reg;

always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		b_reg <= 16'b0;
	else
		b_reg <= b_reg_comb;
		
always_comb
	if(next_state == S_in)
		b_reg_comb = in_b;
	else
		b_reg_comb = b_reg;
		
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		mode_reg <= 1'b0;
	else
		mode_reg <= mode_reg_comb;

always_comb
	if(next_state == S_in)
		mode_reg_comb = mode;
	else
		mode_reg_comb = mode_reg;

//instance declaration	
add inst1(a_reg, b_reg, out_add);
multiply inst2(a_reg, b_reg, out_multiply);
		
always_ff@(posedge clk, negedge rst_n)
	if(!rst_n)
		out <= 16'b0;
	else
		out <= out_comb;
		
always_comb
	if(next_state == S_out) begin
		if(mode_reg == 1'b0)
			out_comb = out_add;
		else
			out_comb = out_multiply;
		end
	else
		out_comb = 16'b0;

endmodule





							
