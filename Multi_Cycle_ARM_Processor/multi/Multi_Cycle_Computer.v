module Multi_Cycle_Computer
	(
		input clk, reset,
		input [3:0] Debug_Source_select,
		output [31:0] PC, Debug_out,
		output [3:0] state
	);
wire PCWrite,AdrSrc,MemWrite, IRWrite, ALUSrcA, RegWrite, BL, BX, N, Z, CO, OVF, CarryIN;
wire [1:0] RegSrc, ALUSrcB, ResultSrc, ImmSrc, ShiftControl;
wire [3:0] ALUControl;
wire [31:0] Instruction;
wire [4:0] shamt;
wire [4:0] rot;

Datapath my_datapath
	(
		.clk(clk), 
		.reset(reset),
		.PCWrite(PCWrite),
		.AdrSrc(AdrSrc),
		.MemWrite(MemWrite), 
		.IRWrite(IRWrite), 
		.ALUSrcA(ALUSrcA),
		.RegWrite(RegWrite),
		.CarryIN(CarryIN),
		.BL(BL),
		.BX(BX),
		.RegSrc(RegSrc), 
		.ALUSrcB(ALUSrcB), 
		.ResultSrc(ResultSrc), 
		.ImmSrc(ImmSrc),
		.ShiftControl(ShiftControl),
		.ALUControl(ALUControl), 
		.Debug_Source_select(Debug_Source_select),
		.shamt(shamt),
		.rot(rot),
		.Instruction(Instruction), 
		.PC(PC), 
		.Debug_out(Debug_out),
		.N(N),
		.Z(Z),
		.CO(CO),
		.OVF(OVF)
	);
ControllerUnit my_controller
	(
		.clk(clk), 
		.reset(reset),
		.Instr(Instruction),
		.CO(CO),
		.OVF(OVF),
		.N(N),
		.Z(Z),
		.PCWrite(PCWrite), 
		.MemWrite(MemWrite), 
		.RegWrite(RegWrite), 
		.BL(BL), 
		.BX(BX),
		.RegSrc(RegSrc), 
		.ImmSrc(ImmSrc),
		.ALUControl(ALUControl),
		.AdrSrc(AdrSrc), 
		.IRWrite(IRWrite), 
		.ALUSrcA(ALUSrcA), 
		.ALUSrcB(ALUSrcB), 
		.ResultSrc(ResultSrc),
		.CarryIN(CarryIN),
		.shamt(shamt),
		.ShiftControl(ShiftControl),
		.rot(rot),
		.CurrentState(state)
	);
	
endmodule