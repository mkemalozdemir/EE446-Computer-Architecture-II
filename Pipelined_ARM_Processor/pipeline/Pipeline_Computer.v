module Pipeline_Computer
	(
		input clk, reset,
		input [3:0] Debug_Source_select,
		output [31:0] fetchPC, Debug_out,
		output StallF,StallD, FlushD, FlushE
	);
	
	wire shift_controlE, BLD, BLW, BXE;
	wire PCSrcW, BranchTakenE, ALUSrcE, MemtoRegW, CarryIN;
	wire RegWriteW, MemWriteM;
	wire N,Z,CO,OVF;
	wire [1:0] RegSrcD, ImmSrcD, ForwardAE, ForwardBE;
	wire [3:0] ALUControlE;
	wire [4:0] shamtE, rotE;
	wire [3:0] RA1D, RA2D, RA1E, RA2E, WA3E, WA3M, WA3W;
	wire [31:0] Instruction;
	wire PCSrcD,PCSrcE,PCSrcM;
	wire RegWriteM, MemtoRegE;
	
	Datapath my_datapath
	(
		.clk(clk),
		.reset(reset),
		.shift_controlE(shift_controlE), 
		.BLD(BLD), 
		.BLW(BLW), 
		.BXE(BXE),
		.PCSrcW(PCSrcW), 
		.BranchTakenE(BranchTakenE), 
		.ALUSrcE(ALUSrcE), 
		.MemtoRegW(MemtoRegW), 
		.CarryIN(CarryIN),
		.RegSrcD(RegSrcD), 
		.ImmSrcD(ImmSrcD), 
		.ForwardAE(ForwardAE), 
		.ForwardBE(ForwardBE),
		.StallF(StallF), 
		.StallD(StallD), 
		.FlushD(FlushD), 
		.FlushE(FlushE),
		.RegWriteW(RegWriteW), 
		.MemWriteM(MemWriteM),
		.ALUControlE(ALUControlE), 
		.Debug_Source_select(Debug_Source_select),
		.shamtE(shamtE),
		.rotE(rotE),
		.RA1D(RA1D), 
		.RA2D(RA2D), 
		.RA1E(RA1E), 
		.RA2E(RA2E), 
		.WA3E(WA3E), 
		.WA3M(WA3M), 
		.WA3W(WA3W),
		.Instruction(Instruction), 
		.PC(fetchPC), 
		.Debug_out(Debug_out),
		.N(N),
		.Z(Z),
		.CO(CO),
		.OVF(OVF)	
	);
	
	Controller my_controller
	(
		.clk(clk), 
		.reset(reset),
		.Instruction(Instruction),
		.CO(CO),
		.OVF(OVF),
		.N(N),
		.Z(Z),
		.FlushE(FlushE),
		.shift_controlE(shift_controlE), 
		.BLD(BLD), 
		.BLW(BLW), 
		.BXE(BXE),
		.PCSrcW(PCSrcW), 
		.BranchTakenE(BranchTakenE), 
		.ALUSrcE(ALUSrcE), 
		.MemtoRegW(MemtoRegW),  
		.CarryIN(CarryIN),
		.RegSrcD(RegSrcD),
		.ImmSrcD(ImmSrcD),
		.RegWriteW(RegWriteW), 
		.RegWriteM(RegWriteM), 
		.MemWriteM(MemWriteM),
		.ALUControlE(ALUControlE), 
		.shamtE(shamtE),
		.rotE(rotE),
		.PCSrcD(PCSrcD),
		.PCSrcE(PCSrcE),
		.PCSrcM(PCSrcM),
		.MemtoRegE(MemtoRegE)
	);
	
	HazardUnit my_hazard_unit
	(
		.RA1E(RA1E),
		.RA2E(RA2E),
		.RA1D(RA1D),
		.RA2D(RA2D), 
		.WA3E(WA3E), 
		.WA3M(WA3M), 
		.WA3W(WA3W),
		.PCSrcD(PCSrcD),
		.PCSrcE(PCSrcE),
		.PCSrcM(PCSrcM), 
		.PCSrcW(PCSrcW), 
		.BranchTakenE(BranchTakenE),
		.RegWriteM(RegWriteM), 
		.RegWriteW(RegWriteW), 
		.MemtoRegE(MemtoRegE),
		.FlushE(FlushE), 
		.FlushD(FlushD), 
		.StallD(StallD), 
		.StallF(StallF),
		.ForwardAE(ForwardAE), 
		.ForwardBE(ForwardBE)
	);
endmodule	