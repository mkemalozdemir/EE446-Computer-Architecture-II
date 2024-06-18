module ControllerUnit
	(
		input clk, reset,
		input [31:0] Instr,
		input CO,OVF,N,Z,
		output PCWrite, MemWrite, RegWrite, BL, BX,
		output[1:0] RegSrc, ImmSrc,
		output [3:0] ALUControl,
		output reg AdrSrc, IRWrite, ALUSrcA, 
		output reg [1:0] ALUSrcB, ResultSrc, 
		output CarryIN,
		output [4:0] shamt,
		output [1:0]ShiftControl,
		output [4:0] rot,
		output reg [3:0] CurrentState
	);
	
	wire [3:0] Cond;
	wire [1:0] Op;
	wire [5:0] Funct;
	wire [3:0] Rd;
	
	//INTERNAL SIGNALS
	wire [3:0] ALUFlags;
	wire PCS, CondEx, CondExOut;
	wire [1:0] FlagW, FlagWrite, Flag32, Flag10;
	reg NextPC, RegW, MemW, ALUOp, Branch; 
	
	//INTERNAL REGISTERS
	Register_rsten#(.WIDTH(2)) flags32(.clk(clk), .reset(reset), .we(FlagWrite[1]), .DATA(ALUFlags[3:2]), .OUT(Flag32));
	Register_rsten#(.WIDTH(2)) flags10(.clk(clk), .reset(reset), .we(FlagWrite[0]), .DATA(ALUFlags[1:0]), .OUT(Flag10));
	Register_reset#(.WIDTH(1)) CONDEX(.clk(clk), .reset(reset), .DATA(CondEx), .OUT(CondExOut));
	
	//INSTRUCTION DECODER
	assign ImmSrc = Op;
	assign RegSrc[1] = (Op == 2'b01);
	assign RegSrc[0] = (Op == 2'b10);
	
	assign ShiftControl = Instr[6:5];
	assign shamt = Instr[11:7];
	
	assign rot = (({1'b0,Instr[11:8]} << 1));
	
	
	initial begin
		AdrSrc = 1'b0;
		IRWrite = 1'b0;
		ALUSrcA = 1'b0;
		Branch = 1'b0;
		ALUSrcB = 2'b0;
		ResultSrc = 2'b0;
		NextPC = 1'b0;
		RegW = 1'b0;
		MemW = 1'b0;
		ALUOp = 1'b0;
		CurrentState = 4'b0;
		NextState = 4'b0;
	end
	
	
	//Decoding of instruction
	assign Cond = Instr[31:28];
	assign Op = Instr[27:26];
	assign Funct = Instr[25:20];
	assign Rd = Instr[15:12];
	
	assign ALUFlags = {N,Z,CO,OVF};
	assign PCWrite = (PCS & CondExOut) | NextPC;
	assign RegWrite = RegW & CondExOut;
	assign MemWrite = MemW & CondExOut;
	assign FlagWrite[1] = CondEx & FlagW[1];
	assign FlagWrite[0] = CondEx & FlagW[0];
	assign CondEx = ((Cond == 0) & (Flag32[0] == 1)) | ((Cond == 1) & (Flag32[0] == 0)) | (Cond == 14);
	assign PCS = ((Rd==15)& RegW) | Branch | BL;
	assign FlagW[1] = (ALUOp & Funct[0]);
	assign FlagW[0] = ALUOp & Funct[0] & ((Funct[4:1] == 4'b0010) | (Funct[4:1] == 4'b0011) | (Funct[4:1] == 4'b0100) | (Funct[4:1] == 4'b0101) | (Funct[4:1] == 4'b0110) | (Funct[4:1] == 4'b0111));
	assign BX = (Instr[27:4] == 24'b000100101111111111110001) & (Instr[0] == 0); //From the arm instruction set
	assign BL = (Op == 2'b10) & (Funct[4]);
	assign ALUControl = ALUOp ? Funct[4:1] : 4'b0100;
	assign CarryIN = Flag10[1];
	
	
	//FSM
	reg [3:0] NextState;
	
	parameter S0 = 'd0;
	parameter S1 = 'd1;
	parameter S2 = 'd2;
	parameter S3 = 'd3;
	parameter S4 = 'd4;
	parameter S5 = 'd5;
	parameter S6 = 'd6;
	parameter S7 = 'd7;
	parameter S8 = 'd8;
	parameter S9 = 'd9;

	
	always@(posedge clk)
		begin
			if(reset)begin
				CurrentState <= S0;
			end
			else begin
				CurrentState <= NextState;
			end
	end
	
	always@(*) 
		begin
			case(CurrentState)
				
				S0: begin	//Fetch
					AdrSrc = 1'b0;
					ALUSrcA = 1'b1;
					ALUSrcB = 2'b10;
					ALUOp = 1'b0;
					ResultSrc = 2'b10;
					
					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b1;
					NextPC = 1'b1;
					Branch = 1'b0;
					
					NextState = S1;
				end
				
				S1: begin	//Decode
					AdrSrc = 1'b0;
					ALUSrcA = 1'b1;
					ALUSrcB = 2'b10;
					ALUOp = 1'b0;
					
					
					
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					if(Op == 2'b01)begin
						RegW = 1'b0;
						ResultSrc = 2'b10;
						NextState = S2;
					end
					
					else if ((Op == 2'b00) && (Funct[5] == 0)) begin
						if(BX) begin		//Directs the RD2 to PC
							RegW = 1'b0;
							ResultSrc =2'b11;
							Branch = 1'b1;
						end
						else begin
							RegW = 1'b1;
							ResultSrc =2'b10;
							Branch = 1'b0;
						end
						NextState = S6;
					end
					
					else if ((Op == 2'b00) && (Funct[5] == 1))begin
						RegW = 1'b0;
						ResultSrc = 2'b10;
						NextState = S7;
					end
					else begin
						ResultSrc = 2'b10;
						if(BL) begin
							RegW = 1'b1;	//Save the PC into R14
						end
						else begin
							RegW = 1'b0;					
						end
						NextState = S9;
					end
				end
				
				S2: begin 	//MemAdr
					AdrSrc = 1'b0;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b01;
					ALUOp = 1'b0;
					ResultSrc = 2'b00;
					
					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					if(Funct[0] == 1) begin
						NextState = S3;
					end
					else begin
						NextState = S5;
					end
				end
				
				S3: begin 	//MemRead
					AdrSrc = 1'b1;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					ALUOp = 1'b0;
					ResultSrc = 2'b00;

					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					NextState = S4;
				end
				
				S4: begin	//MemWB
					AdrSrc = 1'b0;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					ALUOp = 1'b0;
					ResultSrc = 2'b01;
					
					RegW = 1'b1;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					NextState = S0;
				end
				
				S5: begin	//MemWrite
					AdrSrc = 1'b1;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					ALUOp = 1'b0;
					ResultSrc = 2'b00;
					
					RegW = 1'b0;
					MemW = 1'b1;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					NextState = S0;
				end
				
				S6: begin	//ExecuteR
					AdrSrc = 1'b0;
					ResultSrc = 2'b00;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					if(BX) begin
						ALUOp = 1'b0;
						NextState = S0;	//It is branch instruction so it longs 3 cycle
					end
					else begin
						ALUOp = 1'b1;
						NextState = S8;
					end
				end
				
				S7: begin	//ExecuteI
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b11;
					ALUOp = 1'b1;
					AdrSrc = 1'b0;
					ResultSrc = 2'b00;
					
					RegW = 1'b1;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					NextState = S8;
				end
				
				S8: begin	//ALUWB
					AdrSrc = 1'b0;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					ALUOp = 1'b0;
					ResultSrc = 2'b00;
					
					RegW = 1'b1;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					
					NextState = S0;
				end
				
				S9: begin	//Branch
					AdrSrc = 1'b0;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b01;
					ALUOp = 1'b0;
					ResultSrc = 2'b10;
					
					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b1;
					
					NextState = S0;
				end
				
				default: begin
					AdrSrc = 1'b0;
					ALUSrcA = 1'b0;
					ALUSrcB = 2'b00;
					ALUOp = 1'b0;
					ResultSrc = 2'b00;
					
					RegW = 1'b0;
					MemW = 1'b0;
					IRWrite = 1'b0;
					NextPC = 1'b0;
					Branch = 1'b0;
					NextState = S0;
				end
			endcase
	end	
endmodule