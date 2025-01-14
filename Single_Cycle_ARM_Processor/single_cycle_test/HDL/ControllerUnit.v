module ControllerUnit 
	(	input clk, reset,
		input wire [3:0] Cond, ALUFlags, Rd,
		input wire [1:0] Op,
		input wire [5:0] Funct,
		output wire [3:0] ALUControl, 
		output wire PCSrc, RegWrite, MemWrite, MemtoReg, ALUSrc, bl,
		output wire [1:0] ImmSrc, RegSrc
	);


//INTERNAL WIRES
wire [1:0]FlagW, FlagWrite;
wire PCS, RegW, MemW, Branch, ALUOp, CondEx;
wire [1:0] Flags32, Flags10;
//FLAG HOLDER REGISTERS
Register_rsten#(.WIDTH(2)) flags32(.clk(clk), .reset(reset), .we(FlagWrite[1]), .DATA(ALUFlags[3:2]), .OUT(Flags32));
Register_rsten#(.WIDTH(2)) flags10(.clk(clk), .reset(reset), .we(FlagWrite[0]), .DATA(ALUFlags[1:0]), .OUT(Flags10));
//MAIN DECODER DIRECT OUTPUTS

assign ImmSrc[1] = (Op == 2'b10);
assign ImmSrc[0] = (Op == 2'b01);

assign RegSrc[1] = (Op == 2'b01)&(Funct[0] == 0);
assign RegSrc[0] = (Op == 2'b10);

assign MemtoReg = (Op == 2'b01) & (Funct[0]); 

assign ALUSrc = ((Op == 2'b00) & Funct[5]) | (Op == 2'b01) | (Op == 2'b10);	
assign bl = (Op == 2'b10) & (Funct[4]); 

assign ALUControl = ALUOp ? Funct[4:1] : 4'b0100; 

//INTERNAL SIGNALS
assign PCSrc = PCS & CondEx; 
assign RegWrite = RegW & CondEx;
assign MemWrite = MemW & CondEx;	


assign PCS = ((Rd == 15) & RegW) | Branch | bl;	
assign RegW = (Op == 2'b00) | ((Op == 2'b01) & (Funct[0])) | ((Op == 2'b10) & (Funct[4]));	
assign MemW = (Op == 2'b01) & (Funct[0] == 0); 
assign Branch = (Op == 2'b10);
assign ALUOp = (Op == 2'b00);
assign CondEx = ((Cond == 0) & (Flags32[0] == 1)) | ((Cond == 1) & (Flags32[0] == 0)) | (Cond == 14);

assign FlagW[1] = (ALUOp & Funct[0]);
assign FlagW[0] = ALUOp & Funct[0] & ((Funct[4:1] == 4'b0010) | (Funct[4:1] == 4'b0011) | (Funct[4:1] == 4'b0100) | (Funct[4:1] == 4'b0101) | (Funct[4:1] == 4'b0110) | (Funct[4:1] == 4'b0111));
assign FlagWrite[1] = FlagW[1] & CondEx;
assign FlagWrite[0] = FlagW[0] & CondEx;

endmodule