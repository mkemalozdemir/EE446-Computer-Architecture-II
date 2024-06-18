module Datapath
	(
	input clk,reset,
	input wire [3:0] DEBUG_IN,
	output wire [31:0] DEBUG_OUT,
	output wire [31:0] PC
	);
wire [31:0] shifter_out, WD;
wire [31:0] PCnew, PCPlus4, PCPlus8;
wire [31:0] Instr;	
wire [31:0]	RA1, RA2, SrcA, SrcB;
wire [31:0] ExtImm, WriteData, ALUResult, ReadData, Result;
wire [3:0] DEST;

wire PCSrc, RegWrite, MemWrite, MemtoReg, ALUSrc, BL;
wire [1:0] ImmSrc, RegSrc;
wire [3:0] ALUFlags, ALUControl;
wire [31:0] BXorResult;


//MULTIPLEXERS
Mux_2to1#(.WIDTH(32)) PCMUX(.select(PCSrc), .input_0(PCPlus4), .input_1(BXorResult), .output_value(PCnew));
Mux_2to1#(.WIDTH(32)) RA1MUX(.select(RegSrc[0]), .input_0(Instr[19:16]), .input_1(15), .output_value(RA1));
Mux_2to1#(.WIDTH(32)) RA2MUX(.select(RegSrc[1]), .input_0(Instr[3:0]), .input_1(Instr[15:12]), .output_value(RA2));
Mux_2to1#(.WIDTH(32)) SrcBMUX(.select(ALUSrc), .input_0(shifter_out), .input_1(ExtImm), .output_value(SrcB));
Mux_2to1#(.WIDTH(32)) ResultMUX(.select(MemtoReg), .input_0(ALUResult), .input_1(ReadData), .output_value(Result));
Mux_2to1#(.WIDTH(4)) BLMUX(.select(BL), .input_0(Instr[15:12]), .input_1(4'b1110), .output_value(DEST));
Mux_2to1#(.WIDTH(32)) WDMUX(.select(BL), .input_0(Result), .input_1(PCPlus4), .output_value(WD));
Mux_2to1#(.WIDTH(32)) BXMUX(.select((Instr[26:25] == 2'b00)&(Instr[25:21] == 4'b11001)), .input_0(Result), .input_1(WriteData), .output_value(BXorResult));

//Adders
Adder#(.WIDTH(32)) PCP4Adder(.DATA_A(PC), .DATA_B(4), .OUT(PCPlus4));
Adder#(.WIDTH(32)) PCP8Adder(.DATA_A(4), .DATA_B(PCPlus4), .OUT(PCPlus8));

//EXTEND
Extender Extend(.Extended_data(ExtImm), .DATA(Instr[23:0]), .select(ImmSrc));

//ALU
ALU#(.WIDTH(32)) ALUDesign(.control(ALUControl), .CI(ALUFlags[1]), .DATA_A(SrcA), .DATA_B(SrcB), .OUT(ALUResult), .CO(ALUFlags[1]), .OVF(ALUFlags[0]), .N(ALUFlags[3]), .Z(ALUFlags[2]));

//INSTRUCTION MEMORY
Inst_Memory#(.BYTE_SIZE(4), .ADDR_WIDTH(32)) INSTR_MEMORY(.ADDR(PC), .RD(Instr));

//DATA MEMORY
Memory#(.BYTE_SIZE(4), .ADDR_WIDTH(32)) MEMORY(.clk(clk), .WE(MemWrite), .ADDR(ALUResult), .WD(WriteData), .RD(ReadData));

//REGISTER FILE
Register_file #(.WIDTH(32)) reg_file_dp(.clk(clk), .write_enable(RegWrite), .reset(reset), .Source_select_0(RA1), .Source_select_1(RA2), .Debug_Source_select(DEBUG_IN), .Destination_select(DEST), .DATA(WD), .Reg_15(PCPlus8), .out_0(SrcA), .out_1(WriteData), .Debug_out(DEBUG_OUT));

//PROGRAM COUNTER
Register_reset#(.WIDTH(32)) PCREG(.clk(clk), .reset(reset), .DATA(PCnew), .OUT(PC));

//SHIFTER
shifter#(.WIDTH(32)) SHIFT(.control(Instr[6:5]), .shamt(Instr[11:7]), .DATA(WriteData), .OUT(shifter_out));



//CONTROLLER UNIT
ControllerUnit my_controller
		( .clk(clk), 
	   .reset(reset),
		.Cond(Instr[31:28]),
		.ALUFlags(ALUFlags),
		.Rd(Instr[15:12]),
		.Op(Instr[27:26]),
		.Funct(Instr[25:20]),
		.ALUControl(ALUControl), 
		.PCSrc(PCSrc),
		.RegWrite(RegWrite),
		.MemWrite(MemWrite),
		.MemtoReg(MemtoReg),
		.ALUSrc(ALUSrc),
		.bl(BL),
		.ImmSrc(ImmSrc),
		.RegSrc(RegSrc));

endmodule