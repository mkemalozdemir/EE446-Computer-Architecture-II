module Controller
	(
		input clk, reset,
		input [31:0] Instruction,
		input CO,OVF,N,Z,
		input FlushE,
		output shift_controlE, BLD, BLW, BXE,
		output PCSrcW, BranchTakenE, ALUSrcE, MemtoRegW, CarryIN,
		output [1:0] RegSrcD, ImmSrcD,
		output RegWriteW, RegWriteM, MemWriteM,
		output [3:0]ALUControlE,
		output [4:0] shamtE,
		output [4:0] rotE,
		output PCSrcD,PCSrcE,PCSrcM,
		output MemtoRegE
	);
	
	//DECODE WIRES
	wire [1:0] Op;
	wire [5:0] Funct;
	wire [3:0] Cond, Rd;
	
	wire BranchD, RegWriteD, MemWriteD, MemtoRegD, ALUSrcD, FlagWriteD, BXD;
	wire [3:0] ALUControlD;
	
	wire [4:0] shamtD, rotD;
	wire shift_controlD, ALUOp;
	
	//EXECUTE WIRES
	wire BranchE, RegWriteE, MemWriteE, FlagWriteE, CondEx, BLE;
	wire PCSrcEE, RegWriteEE, MemWriteEE;
	wire [3:0] FlagsE, CondE, Flags;
	
	//MEMORY WIRES
	wire MemtoRegM, BLM;
	
	//WRITEBACK WIRES (defined as outputs)

	//DECODE
	
	assign BXD = (Instruction[27:4] == 24'b000100101111111111110001) & (Instruction[0] == 0); //From the arm instruction set
	
	assign BLD = (Op == 2'b10) & (Funct[4]);	//BL passes through all stages and when it is at writeback, needed signals are arranged to write operation to regfile
	
	assign shamtD = Instruction[11:7];
	assign rotD = (({1'b0,Instruction[11:8]} << 1));
	
	assign shift_controlD = ((Op == 2'b00) & (Funct[5] == 1));
	
	assign Op = Instruction[27:26];
	assign Funct = Instruction[25:20];
	assign Cond = Instruction[31:28];
	assign Rd = Instruction[15:12];
	
	assign RegSrcD[1] = (Op == 2'b01);
	assign RegSrcD[0] = (Op == 2'b10); 
	
	assign ImmSrcD = Op;
	
	assign ALUOp = (Op == 2'b00);
	
	assign PCSrcD = ((Rd == 15) & RegWriteD & (~BXD));	//I apply BX as branch operation; therefore, I prevent StallF when BX is at decode stage
	assign BranchD = (Op == 2'b10) | BXD;	//BX behaves as branch operation
	assign RegWriteD = (Op == 2'b00) | ((Op == 2'b01) & (Funct[0])) | ((Op == 2'b10) & (Funct[4]));
	assign MemWriteD = (Op == 2'b01) & (Funct[0] == 0);
	assign MemtoRegD = (Op == 2'b01) & (Funct[0]);
	assign ALUControlD = ALUOp ? Funct[4:1] : 4'b0100;
	assign ALUSrcD = ((Op == 2'b00) & Funct[5]) | (Op == 2'b01) | (Op == 2'b10);
	assign FlagWriteD = (Op == 2'b00) & Funct[0];
	
	//EXECUTE
	
	Register_reset#(.WIDTH(1)) EPR_BXE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(BXD),
		.OUT(BXE)
	);	
	
	Register_reset#(.WIDTH(1)) EPR_BLE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(BLD),
		.OUT(BLE)
	);	
	
	Register_reset#(.WIDTH(5)) EPR_shamtE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(shamtD),
		.OUT(shamtE)
	);
	
	Register_reset#(.WIDTH(5)) EPR_rotE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(rotD),
		.OUT(rotE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_shift_controlE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(shift_controlD),
		.OUT(shift_controlE)
	);	
	
	Register_reset#(.WIDTH(1)) EPR_PCSrcE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(PCSrcD),
		.OUT(PCSrcE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_BranchE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(BranchD),
		.OUT(BranchE)
	);

	Register_reset#(.WIDTH(1)) EPR_RegWriteE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(RegWriteD),
		.OUT(RegWriteE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_MemWriteE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(MemWriteD),
		.OUT(MemWriteE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_MemtoRegE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(MemtoRegD),
		.OUT(MemtoRegE)
	);
	
	Register_reset#(.WIDTH(4)) EPR_ALUControlE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(ALUControlD),
		.OUT(ALUControlE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_ALUSrcE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(ALUSrcD),
		.OUT(ALUSrcE)
	);
	
	Register_reset#(.WIDTH(4)) EPR_FlagsE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(Flags),
		.OUT(FlagsE)
	);
	
	Register_reset#(.WIDTH(1)) EPR_FlagsWriteE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(FlagWriteD),
		.OUT(FlagWriteE)
	);
	
	Register_reset#(.WIDTH(4)) EPR_CondE
	(
		.clk(clk), 
		.reset(reset | FlushE),
		.DATA(Cond),
		.OUT(CondE)
	);
	
	assign Flags = FlagWriteE ? {N,Z,CO,OVF} : FlagsE;
	assign CondEx = ((CondE == 0) & (FlagsE[2] == 1)) | ((CondE == 1) & (FlagsE[2] == 0)) | (CondE == 14);
	
	assign CarryIN = Flags[1];
	
	assign PCSrcEE = PCSrcE & CondEx;
	assign BranchTakenE = BranchE & CondEx;
	assign RegWriteEE = RegWriteE & CondEx;
	assign MemWriteEE = MemWriteE & CondEx;
	
	//MEMORY
	
	Register_reset#(.WIDTH(1)) EPR_BLM
	(
		.clk(clk), 
		.reset(reset),
		.DATA(BLE),
		.OUT(BLM)
	);	
	
	Register_reset#(.WIDTH(1)) EPR_PCSrcM
	(
		.clk(clk), 
		.reset(reset),
		.DATA(PCSrcEE),
		.OUT(PCSrcM)
	);
	
	Register_reset#(.WIDTH(1)) EPR_RegWriteM
	(
		.clk(clk), 
		.reset(reset),
		.DATA(RegWriteEE),
		.OUT(RegWriteM)
	);	

	Register_reset#(.WIDTH(1)) EPR_MemWriteM
	(
		.clk(clk), 
		.reset(reset),
		.DATA(MemWriteEE),
		.OUT(MemWriteM)
	);

	Register_reset#(.WIDTH(1)) EPR_MemtoRegM
	(
		.clk(clk), 
		.reset(reset),
		.DATA(MemtoRegE),
		.OUT(MemtoRegM)
	);
	
	//WRITEBACK

	Register_reset#(.WIDTH(1)) EPR_BLW
	(
		.clk(clk), 
		.reset(reset),
		.DATA(BLM),
		.OUT(BLW)
	);	
	
	Register_reset#(.WIDTH(1)) EPR_PCSrcW
	(
		.clk(clk), 
		.reset(reset),
		.DATA(PCSrcM),
		.OUT(PCSrcW)
	);
	
	Register_reset#(.WIDTH(1)) EPR_RegWriteW
	(
		.clk(clk), 
		.reset(reset),
		.DATA(RegWriteM),
		.OUT(RegWriteW)
	);
	
	Register_reset#(.WIDTH(1)) EPR_MemtoRegW
	(
		.clk(clk), 
		.reset(reset),
		.DATA(MemtoRegM),
		.OUT(MemtoRegW)
	);
endmodule	