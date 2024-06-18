module HazardUnit
	(
		input [3:0] RA1E,RA2E,RA1D,RA2D, WA3E, WA3M, WA3W,
		input PCSrcD,PCSrcE,PCSrcM, PCSrcW, BranchTakenE,
		input RegWriteM, RegWriteW, MemtoRegE,
		output FlushE, FlushD, StallD, StallF,
		output reg [1:0] ForwardAE, ForwardBE
	);
	
	wire Match_1E_M, Match_1E_W;
	wire Match_2E_M, Match_2E_W;
	
	
	wire Match_12D_E, LDRStall, PCWrPendingF;
	
	
	assign Match_1E_M = (RA1E == WA3M);
	assign Match_1E_W = (RA1E == WA3W);
	
	assign Match_2E_M = (RA2E == WA3M);
	assign Match_2E_W = (RA2E == WA3W);
	
	assign Match_12D_E = (RA1D == WA3E) | (RA2D == WA3E);
	assign LDRStall = Match_12D_E & MemtoRegE;
	
	assign PCWrPendingF = PCSrcD | PCSrcE | PCSrcM;
	assign StallF = LDRStall | PCWrPendingF;	//Fetch is stalled when LDR happens or directly PC write operation
	assign StallD = LDRStall;	//Decode is stalled when LDR happens
	
	assign FlushD = PCWrPendingF | PCSrcW | BranchTakenE;	//When a PC write happens, Decode is flushed
	assign FlushE = LDRStall | BranchTakenE;	//When branch or LDR happens, execute flushed
	
	always@(*) begin		//ForwardAE signal is arranged for forwarding 
		
		if(Match_1E_M & RegWriteM) begin
			ForwardAE = 2'b10;
		end
		else if (Match_1E_W & RegWriteW) begin
			ForwardAE = 2'b01;
		end
		else begin
			ForwardAE = 2'b00;
		end
	end
	
	always@(*) begin		//ForwardBE signal is arranged for forwarding
		
		if(Match_2E_M & RegWriteM) begin
			ForwardBE = 2'b10;
		end
		else if (Match_2E_W & RegWriteW) begin
			ForwardBE = 2'b01;
		end
		else begin
			ForwardBE = 2'b00;
		end
	end
	
endmodule
