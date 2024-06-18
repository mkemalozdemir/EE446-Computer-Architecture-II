module COMPUTER_MODULE
(
	input clk, reset,
	input wire [3:0] debug_reg_select,
	output wire [31:0] fetchPC, debug_reg_out
);

Datapath my_datapath(.clk(clk), .reset(reset), .DEBUG_IN(debug_reg_select), .DEBUG_OUT(debug_reg_out) , .PC(PC));
endmodule