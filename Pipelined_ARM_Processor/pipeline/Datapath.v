module Datapath
	(
		input clk,reset,
		input shift_controlE, BLD, BLW, BXE,
		input PCSrcW, BranchTakenE, ALUSrcE, MemtoRegW, CarryIN,
		input [1:0] RegSrcD, ImmSrcD, ForwardAE, ForwardBE,
		input StallF, StallD, FlushD, FlushE,
		input RegWriteW, MemWriteM,
		input [3:0]ALUControlE, Debug_Source_select,
		input [4:0] shamtE,
		input [4:0] rotE,
		output [3:0] RA1D, RA2D, RA1E, RA2E, WA3E, WA3M, WA3W,
		output [31:0] Instruction, PC, Debug_out,
		output N,Z,CO,OVF
	);


	//FETCH WIRES
	wire [31:0] PCPrime, PCPlus4F, IMRD, FirstMuxOut;
	//DECODE WIRES
	wire [3:0] WA3D;
	wire [31:0] RD1, RD2, ExtImmD, BL_save, RegFileInput;
	//EXECUTE WIRES
	wire [4:0] shift_amount;
	wire [1:0] ShiftControl;
	wire [31:0] RD1E, RD2E, ExtImmE, SrcAE, SrcBE, ALUResultE, ShifterInput,ShifterOutput, FBEOut, BX_MUXOut;
	//MEMORY WIRES
	wire [31:0] RD2M, ALUOutM, DMRD;
	//WRITEBACK WIRES
	wire [31:0] ReadDataW, ALUOutW, ResultW;

	//FETCH
	Mux_2to1#(.WIDTH(32)) PCP4orResultW
	(
		.select(PCSrcW),
		.input_0(PCPlus4F),
		.input_1(ResultW),
		.output_value(FirstMuxOut)
	);

	Mux_2to1#(.WIDTH(32)) FMOorALUResultE
	(
		.select(BranchTakenE),
		.input_0(FirstMuxOut),
		.input_1(BX_MUXOut),
		.output_value(PCPrime)
	);

	Register_rsten#(.WIDTH(32)) FetchPipelineRegister
	(
		.clk(clk),
		.reset(reset),
		.we(~StallF),
		.DATA(PCPrime),
		.OUT(PC)
	);

	Adder#(.WIDTH(32)) PCAdder
	(
		.DATA_A(PC),
		.DATA_B(4),
		.OUT(PCPlus4F)
	);
	
	Inst_Memory#(.BYTE_SIZE(4), .ADDR_WIDTH(32)) InstructionMemory
	(
		.ADDR(PC),
		.RD(IMRD)
	);

	//DECODE
	
	Register_rsten#(.WIDTH(32)) DecodePipelineRegister
	(
		.clk(clk),
		.reset(FlushD | reset),
		.we(~StallD),
		.DATA(IMRD),
		.OUT(Instruction)
	);
	
	Mux_2to1#(.WIDTH(4)) RA1D_MUX
	(
		.select(RegSrcD[0]),
		.input_0(Instruction[19:16]),
		.input_1(15),
		.output_value(RA1D)
	);
	
	Mux_2to1#(.WIDTH(4)) RA2D_MUX
	(
		.select(RegSrcD[1]),
		.input_0(Instruction[3:0]),
		.input_1(Instruction[15:12]),
		.output_value(RA2D)
	);
	
	Mux_2to1#(.WIDTH(4)) WA3D_MUX
	(
		.select(BLD),
		.input_0(Instruction[15:12]),
		.input_1(4'b1110),
		.output_value(WA3D)			
	);
	
	Register_rsten#(.WIDTH(32)) BL_Memory
	(
	  .clk(clk), 
	  .reset(reset),
	  .we(BLD),												//For BL operation, when the BL is decoded, the PC value of the next instruction is saved
	  .DATA(PC),
	  .OUT(BL_save)		
	);
	
	Mux_2to1#(.WIDTH(32)) BL_MUX_SAVE
	(
		.select(BLW),
		.input_0(ResultW),								//At the writeback stage saved PC value is written to R14
		.input_1(BL_save),
		.output_value(RegFileInput)			
	);
	
	Register_file#(.WIDTH(32)) reg_file_dp
	(
	  .clk(~clk), 
	  .write_enable(RegWriteW), 
	  .reset(reset),
	  .Source_select_0(RA1D), 
	  .Source_select_1(RA2D), 
	  .Debug_Source_select(Debug_Source_select), 
	  .Destination_select(WA3W),
	  .DATA(RegFileInput), 
	  .Reg_15(PCPlus4F),
	  .out_0(RD1), 
	  .out_1(RD2), 
	  .Debug_out(Debug_out)
	);
	
	Extender ExtenderD
	(
    .Extended_data(ExtImmD),
    .DATA(Instruction[23:0]),
    .select(ImmSrcD)		
	);
	
	//EXECUTE	(ExecutePipelineRegister == EPR)
	
	Register_reset#(.WIDTH(4)) EPR_RA1E
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(RA1D),
	  .OUT(RA1E)		
	);
	
	Register_reset#(.WIDTH(4)) EPR_RA2E
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(RA2D),
	  .OUT(RA2E)		
	);
	
	Register_reset#(.WIDTH(32)) EPR_RD1
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(RD1),
	  .OUT(RD1E)		
	);
	
	Register_reset#(.WIDTH(32)) EPR_RD2
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(RD2),
	  .OUT(RD2E)		
	);

	Register_reset#(.WIDTH(4)) EPR_WA3D
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(WA3D),
	  .OUT(WA3E)		
	);

	Register_reset#(.WIDTH(32)) EPR_ExtImmD
	(
	  .clk(clk), 
	  .reset(FlushE | reset),
	  .DATA(ExtImmD),
	  .OUT(ExtImmE)		
	);
	
	Mux_4to1#(.WIDTH(32)) ForwardAE_MUX
	(
	  .select(ForwardAE),
	  .input_0(RD1E), 
	  .input_1(ResultW), 
	  .input_2(ALUOutM), 
	  .input_3(0),
     .output_value(SrcAE)		
	);

	Mux_2to1#(.WIDTH(2)) SHIFTCONTROL
	(
	  .select(shift_controlE),
	  .input_0(ExtImmE[6:5]), 
	  .input_1(2'b11),
     .output_value(ShiftControl)		
	);
															//For the operations that need shifts, I added one shifter after the SrcBE mux
	Mux_2to1#(.WIDTH(5)) ShamtorRot				//Inputs of the shifter are arrranged according to the instruction when it is at decode stage
	(
	  .select(shift_controlE),
	  .input_0(shamtE), 
	  .input_1(rotE),
     .output_value(shift_amount)		
	);
	
	Mux_4to1#(.WIDTH(32)) ForwardBE_MUX
	(
	  .select(ForwardBE),
	  .input_0(RD2E), 
	  .input_1(ResultW), 
	  .input_2(ALUOutM), 
	  .input_3(0),
     .output_value(FBEOut)		
	);
	
	shifter#(.WIDTH(32)) SHIFTER
	(
	  .control(ShiftControl),
	  .shamt(shift_amount),
	  .DATA(ShifterInput),
	  .OUT(ShifterOutput)		
	);
	
	Mux_2to1#(.WIDTH(32)) SrcBE_MUX
	(
	  .select(ALUSrcE),
	  .input_0(FBEOut), 
	  .input_1(ExtImmE),
     .output_value(ShifterInput)		
	);
	
	ALU #(.WIDTH(32)) ALUE
	(
	  .control(ALUControlE),
	  .CI(CarryIN),
	  .DATA_A(SrcAE),
	  .DATA_B(ShifterOutput),
     .OUT(ALUResultE),
	  .CO(CO),
	  .OVF(OVF),
	  .N(N), 
	  .Z(Z)		
	);
	
	Mux_2to1#(.WIDTH(32)) BX_MUX
	(
	  .select(BXE),
	  .input_0(ALUResultE), 
	  .input_1(BL_save),
     .output_value(BX_MUXOut)		
	);	
	
	//MEMORY (MemoryPipelineRegister == MPR)
	
	Register_reset#(.WIDTH(32)) MPR_ALUResultE
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(ALUResultE),
	  .OUT(ALUOutM)		
	);
	
	Register_reset#(.WIDTH(32)) MPR_RD2E
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(RD2E),
	  .OUT(RD2M)		 
	);

	Register_reset#(.WIDTH(4)) MPR_WA3E
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(WA3E),
	  .OUT(WA3M)		 
	);
	
	Memory#(.BYTE_SIZE(4), .ADDR_WIDTH(32)) DataMemory
	(
		.clk(clk),
		.WE(MemWriteM),
		.ADDR(ALUOutM),
		.WD(RD2M),
		.RD(DMRD)
	);
	
	//WRITEBACK (WritebackPipelineRegister == WPR)
	
	Register_reset#(.WIDTH(32)) WPR_DMRD
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(DMRD),
	  .OUT(ReadDataW)		 
	);

	Register_reset#(.WIDTH(32)) MPR_ALUOutM
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(ALUOutM),
	  .OUT(ALUOutW)		 
	);	
	
	Register_reset#(.WIDTH(4)) MPR_WA3M
	(
	  .clk(clk),
	  .reset(reset),
	  .DATA(WA3M),
	  .OUT(WA3W)		 
	);
	
	Mux_2to1#(.WIDTH(32)) ReadDataWorALUOutW
	(
	  .select(MemtoRegW),
	  .input_0(ALUOutW), 
	  .input_1(ReadDataW),
     .output_value(ResultW)		
	);
	
endmodule
