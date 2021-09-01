module MorseEncoder(	
	
	// Avalon interface
	input logic clk, 		
	input logic rst_n,
	input logic [4:0] address,
	output logic [7:0] read_data,
	input logic write_enable,
	input logic [7:0] write_data,
	
	// 7 LEDs in FPGA
	output logic [6:0] leds
	
	);
	
	integer i;

	// FSM
	logic [2:0] current_state;
	logic [2:0] next_state;
	
	// parameters don't work correctly 
	logic [2:0] IDLE, QUEUE_LOAD, QUEUE_CHECK, DOT, DASH, SHORT_DELAY, LONG_DELAY, FINISH;
	assign IDLE = 3'd0;
	assign QUEUE_LOAD = 3'd1;
	assign QUEUE_CHECK = 3'd2;
	assign DOT = 3'd3;
	assign DASH = 3'd4;
	assign SHORT_DELAY = 3'd5;
	assign LONG_DELAY = 3'd6;
	assign FINISH = 3'd7;
	
	logic [7:0] register [31:0];		// 32-bit register accessible from HPS
	
	logic [4:0] index;					// keep track of characters send
	
	logic [2:0] queue [0:5];			// 6 position queue
	
	// to generate delays (periods with leds off or on)
	logic [31:0] counter1;	// dot
	logic [31:0] counter2; 	// dash
	logic [31:0] counter3; 	// short
	logic [31:0] counter4;	// long
	
	
	always_ff @ (negedge rst_n or posedge clk) begin
	
		// reset logic
		if (!rst_n) begin 
			current_state <= IDLE;
			index <= 5'd1;
			for (i=0; i<32; i=i+1) register[i] <= 8'd0;
			for (i=0; i<6; i=i+1) queue[i] <= 3'd0;
			counter1 <= 0;
			counter2 <= 0;
			counter3 <= 0;
			counter4 <= 0;
		end
		// writes synchronous to clk
		else begin 
			
			current_state <= next_state;
			
			case (current_state) 
				IDLE:
					begin
						index <= 5'd1;				// start pointing to position 1, as position 0 is a flag
						if (write_enable) begin						// only in IDLE can the HPS write
							register[address] <= write_data;
						end
						else begin 
							for (i=0; i<32; i=i+1) register[i] <= register[i];
						end
						for (i=0; i<6; i=i+1) queue[i] <= queue[i];
						counter1 <= 0;
						counter2 <= 0;
						counter3 <= 0;
						counter4 <= 0;
					end
				QUEUE_LOAD:
					begin
						index <= index;
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						case (register[index])
							"0": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DASH,DASH,DASH,LONG_DELAY}; 	
							"1": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DASH,DASH,DASH,LONG_DELAY}; 		
							"2": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DASH,DASH,DASH,LONG_DELAY}; 		
							"3": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,DASH,DASH,LONG_DELAY}; 		
							"4": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,DOT,DASH,LONG_DELAY}; 		
							"5": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,DOT,DOT,LONG_DELAY}; 			
							"6": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DOT,DOT,DOT,LONG_DELAY}; 		
							"7": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DOT,DOT,DOT,LONG_DELAY}; 		
							"8": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DASH,DOT,DOT,LONG_DELAY}; 		
							"9": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DASH,DASH,DOT,LONG_DELAY}; 		
							"E": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,LONG_DELAY,3'd0,3'd0,3'd0,3'd0};								
							"T": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,LONG_DELAY,3'd0,3'd0,3'd0,3'd0};								
							"A": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,LONG_DELAY,3'd0,3'd0,3'd0};							
							"I": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,LONG_DELAY,3'd0,3'd0,3'd0};							
							"M": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,LONG_DELAY,3'd0,3'd0,3'd0};						
							"N": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,LONG_DELAY,3'd0,3'd0,3'd0};							
							"D": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DOT,LONG_DELAY,3'd0,3'd0};					
							"G": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DOT,LONG_DELAY,3'd0,3'd0};					
							"K": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DASH,LONG_DELAY,3'd0,3'd0};					
							"O": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DASH,LONG_DELAY,3'd0,3'd0};					
							"R": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DOT,LONG_DELAY,3'd0,3'd0};					
							"S": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,LONG_DELAY,3'd0,3'd0};						
							"U": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DASH,LONG_DELAY,3'd0,3'd0};					
							"W": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DASH,LONG_DELAY,3'd0,3'd0};					
							"B": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DOT,DOT,LONG_DELAY,3'd0};				
							"C": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DASH,DOT,LONG_DELAY,3'd0};				
							"F": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DASH,DOT,LONG_DELAY,3'd0};				
							"H": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,DOT,LONG_DELAY,3'd0}; 				
							"J": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DASH,DASH,LONG_DELAY,3'd0}; 			
							"L": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DOT,DOT,LONG_DELAY,3'd0};				
							"P": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DASH,DASH,DOT,LONG_DELAY,3'd0};				
							"Q": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DOT,DASH,LONG_DELAY,3'd0};			
							"V": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DOT,DOT,DOT,DASH,LONG_DELAY,3'd0};				
							"X": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DOT,DASH,LONG_DELAY,3'd0};				
							"Y": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DOT,DASH,DASH,LONG_DELAY,3'd0};			
							"Z": {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {DASH,DASH,DOT,DOT,LONG_DELAY,3'd0};
							default: {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} = {FINISH,3'd0,3'd0,3'd0,3'd0,3'd0};
						endcase
						counter1 <= counter1;
						counter2 <= counter2;
						counter3 <= counter3;
						counter4 <= counter4;
					end
				QUEUE_CHECK:
					begin
						index <= index;
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						for (i=0; i<6; i=i+1) queue[i] <= queue[i];
						counter1 <= 0;
						counter2 <= 0;
						counter3 <= 0;
						counter4 <= 0;
					end
				DOT:
					begin
						index <= index;
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						for (i=0; i<6; i=i+1) queue[i] <= queue[i];
						counter1 <= counter1 + 1;
						counter2 <= counter2;
						counter3 <= counter3;
						counter4 <= counter4;
					end
				DASH:
					begin
						index <= index;
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						for (i=0; i<6; i=i+1) queue[i] <= queue[i];
						counter1 <= counter1;
						counter2 <= counter2 + 1;
						counter3 <= counter3;
						counter4 <= counter4;
					end
				SHORT_DELAY:
					begin
						index <= index;
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						if (counter3 == 0) begin 
							{queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} <= {queue[1],queue[2],queue[3],queue[4],queue[5],3'd0};
						end
						else begin 
							{queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]} <= {queue[0],queue[1],queue[2],queue[3],queue[4],queue[5]};
						end					
						counter1 <= counter1;
						counter2 <= counter2;
						counter3 <= counter3 + 1;
						counter4 <= counter4;
					end
				LONG_DELAY:
					begin
						if(counter4 == 0) begin
							index <= index + 5'd1;		// increase to load next char
						end
						else begin 
							index <= index;
						end
						for (i=0; i<32; i=i+1) register[i] <= register[i];
						for (i=0; i<6; i=i+1) queue[i] <= queue[i];
						counter1 <= counter1;
						counter2 <= counter2;
						counter3 <= counter3;
						counter4 <= counter4 + 1;
					end
				FINISH:
					begin
						index <= 5'd1;
						for (i=0; i<32; i=i+1) register[i] <= 8'd0;				// clear buffer and flag
						for (i=0; i<6; i=i+1) queue[i] <= 3'd0;					// clear queue 
						counter1 <= 0;
						counter2 <= 0;
						counter3 <= 0;
						counter4 <= 0;
					end
				default:
					begin
						index <= 5'd1;
						for (i=0; i<32; i=i+1) register[i] <= 8'd0;				
						for (i=0; i<6; i=i+1) queue[i] <= 3'd0;					 
						counter1 <= 0;
						counter2 <= 0;
						counter3 <= 0;
						counter4 <= 0;
					end
			endcase
		
		end	// else
		
	end	// always_ff
	
	
	
	// asynchronous read
	assign read_data = register[address];
	
	always_comb begin 
		
		// next state logic
		case (current_state)
			IDLE:
				begin
					if (register[0] == 8'd1) begin			// this is the start flag
						next_state = QUEUE_LOAD;
					end
					else begin
						next_state = IDLE;
					end
					leds = 7'b0000000;
				end
			QUEUE_LOAD:
				begin
					if (index == 5'd0)	begin						// we went through all buffer		
						next_state = FINISH;
					end
					else begin 
						next_state = QUEUE_CHECK;
					end
					leds = 7'b0000000;
				end
			QUEUE_CHECK:
				begin
					case (queue[0]) 
						DOT: next_state = DOT;
						DASH: next_state = DASH;
						LONG_DELAY: next_state = LONG_DELAY;
						FINISH: next_state = FINISH;
						default: next_state = FINISH;
					endcase
					leds = 7'b0000000;
				end
			DOT:
				begin
					if(counter1 < 12500000) begin 
						next_state = DOT;
					end
					else begin
						next_state = SHORT_DELAY;
					end
					leds = 7'b1111111;
				end
			DASH:
				begin
					if(counter2 < 37500000) begin			// dash last 3 times dot
						next_state = DASH;
					end
					else begin
						next_state = SHORT_DELAY;
					end
					leds = 7'b1111111;
				end
			SHORT_DELAY:
				begin
					if(counter3 < 12500000) begin 		// time between dot or dash is the same as a dot
						next_state = SHORT_DELAY;
					end
					else begin
						next_state = QUEUE_CHECK;
					end
					leds = 7'b0000000;
				end
			LONG_DELAY:
				begin
					if(counter4 < 25000000) begin 		// this + short delay is a 3x delay, used as space between letters
						next_state = LONG_DELAY;
					end
					else begin
						next_state = QUEUE_LOAD;
					end
					leds = 7'b0000000;
				end
			FINISH:
				begin
					next_state = IDLE;
					leds = 7'b0000000;
				end
			default:
				begin
					next_state = FINISH;
					leds = 7'b0000000;
				end
		endcase
	end
	

endmodule
