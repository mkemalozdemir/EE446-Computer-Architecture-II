module Datapath
	(
		input clk, reset,
		input PCWrite,AdrSrc,MemWrite, IRWrite, ALUSrcA, RegWrite,CarryIN, BL,BX,
		input [1:0] RegSrc, ALUSrcB, ResultSrc, ImmSrc, ShiftControl,
		input [3:0] ALUControl, Debug_Source_select,
		input [4:0] shamt,
		input [4:0] rot,
		output [31:0] Instruction, PC, Debug_out,
		output N,Z,CO,OVF
	);
	wire[31:0] BLSAVEMUXOut, shifter_out, Adr, ReadData, WriteData, ExtImm, shifter_out_immediate; 
	wire[31:0] A, Data, SrcA, SrcB, ALUResult, ALUOut, Result, RD1, RD2;
	wire [3:0] RA1, RA2, BLMUXOut;
	
	//MULTIPLEXERS
	Mux_2to1#(.WIDTH(32)) ADRMUX(.select(AdrSrc), .input_0(PC), .input_1(Result), .output_value(Adr));
	Mux_2to1#(.WIDTH(32)) SRCAMUX(.select(ALUSrcA), .input_0(A), .input_1(PC), .output_value(SrcA));
	Mux_2to1#(.WIDTH(4)) RA1MUX(.select(RegSrc[0]), .input_0(Instruction[19:16]), .input_1(15), .output_value(RA1));
	Mux_2to1#(.WIDTH(4)) RA2MUX(.select(RegSrc[1]), .input_0(Instruction[3:0]), .input_1(Instruction[15:12]), .output_value(RA2));
	Mux_4to1#(.WIDTH(32)) SRCBMUX(.select(ALUSrcB), .input_0(shifter_out), .input_1(ExtImm), .input_2(4), .input_3(shifter_out_immediate), .output_value(SrcB));
	Mux_4to1#(.WIDTH(32)) RESULTMUX(.select(ResultSrc), .input_0(ALUOut), .input_1(Data), .input_2(ALUResult), .input_3(RD2), .output_value(Result));

	//ADDED MULTIPLEXERS - To chose R14 and Save PC+4 when BL operation is processing
	Mux_2to1#(.WIDTH(4)) BLDESTMUX(.select(BL), .input_0(Instruction[15:12]), .input_1(14), .output_value(BLMUXOut));
	Mux_2to1#(.WIDTH(32)) BLSAVEMUX(.select(BL), .input_0(Result), .input_1(PC), .output_value(BLSAVEMUXOut));
	
	//PC REGISTER
	Register_rsten#(.WIDTH(32)) PCRegister(.clk(clk), .reset(reset), .we(PCWrite), .DATA(Result), .OUT(PC));
	
	//IR REGISTER
	Register_rsten#(.WIDTH(32)) IRRegister(.clk(clk), .reset(reset), .we(IRWrite), .DATA(ReadData), .OUT(Instruction));
	
	//DATA REGISTER
	Register_reset#(.WIDTH(32)) DATARegister(.clk(clk), .reset(reset), .DATA(ReadData), .OUT(Data));
	
	//REGFILE REGISTERS
	Register_reset#(.WIDTH(32)) REGFILERegister1(.clk(clk), .reset(reset), .DATA(RD1), .OUT(A));
	Register_reset#(.WIDTH(32)) REGFILERegister2(.clk(clk), .reset(reset), .DATA(RD2), .OUT(WriteData));
	
	//ALU REGISTER
	Register_reset#(.WIDTH(32)) ALURegister(.clk(clk), .reset(reset), .DATA(ALUResult), .OUT(ALUOut));
	
	//INSTR/DATA MEMORY
	ID_memory#(.BYTE_SIZE(4), .ADDR_WIDTH(32)) IDM(.clk(clk), .WE(MemWrite), .ADDR(Adr), .WD(WriteData), .RD(ReadData));
	
	//REGISTER FILE
	Register_file#(.WIDTH(32)) reg_file_dp(.clk(clk), .write_enable(RegWrite), .reset(reset), .Source_select_0(RA1), 
						.Source_select_1(RA2), .Debug_Source_select(Debug_Source_select), .Destination_select(BLMUXOut), .DATA(BLSAVEMUXOut), 
						.Reg_15(Result), .out_0(RD1), .out_1(RD2), .Debug_out(Debug_out));
	
	//ALU
	ALU#(.WIDTH(32)) MYALU(.control(ALUControl), .CI(CarryIN), .DATA_A(SrcA), .DATA_B(SrcB), .OUT(ALUResult), .CO(CO), .OVF(OVF), .N(N), .Z(Z));
	
	//EXTENDER
	Extender EXTEND(.Extended_data(ExtImm), .DATA(Instruction[23:0]), .select(ImmSrc));
	
	//ADDED SHIFTERS - To arrange register shifted immediate and MOV operations
	shifter#(.WIDTH(32)) SHIFT(.control(ShiftControl), .shamt(shamt), .DATA(WriteData), .OUT(shifter_out));
	shifter#(.WIDTH(32)) EXTSHIFT(.control(2'b11), .shamt(rot), .DATA(ExtImm), .OUT(shifter_out_immediate));

endmodule