module Single_Cycle_Computer
(
	input clk, reset,
	input wire [3:0] DEBUG_IN,
	output wire [31:0] PC, DEBUG_OUT
);

Datapath my_datapath(.clk(clk), .reset(reset), .DEBUG_IN(DEBUG_IN), .DEBUG_OUT(DEBUG_OUT) , .PC(PC));
endmodule