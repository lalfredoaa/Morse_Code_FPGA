


module MorseDecoder2(	
	
	// Avalon interface
	input logic clk, 		
	input logic rst_n,
	input logic [1:0] address,
	output logic [7:0] read_data,
	input logic write_enable,
	input logic [7:0] write_data,
	
	// FPGA input
	input logic [1:0] button_in,
	input logic [3:0] switch_in	// connect whole dip switch interface, although we use only one 
	
	);
	
	// rename inputs
	logic dot_in, dash_in, done_in;
	assign dot_in = (~button_in[0]) & (~switch_in[0]);	// buttons use active low logic
	assign dash_in = (~button_in[0])	& 	(switch_in[0]);
	assign done_in = ~button_in[1];
	
	// using parameters added an extra bit that caused conflicts
	logic DOT, DASH;
	assign DOT = 1'b0;
	assign DASH = 1'b1;
	
	logic [4:0] buffer_in;			// input buffer to store dash and dots
	logic [2:0] counter;				// count how many dots and dashes were input
	logic [7:0] register [3:0];	// a register to be accessed by HPS
											// register[0] will act as ready flag
											// register[1] will store detected char
	
	// for debug
	//assign register[2] <= {3'd0,buffer_in};
	//assign register[3] <= {5'd0,counter};
	//register[2] <= {3'd0,buffer_in};
	//register[3] <= {5'd0,counter};
	
	logic [2:0] current_state;
	logic [2:0] next_state;
	
	parameter IDLE = 4'd0;
	parameter DOT_ST = 4'd1;
	parameter WAIT_DOT_RELEASE = 4'd2;
	parameter DASH_ST = 4'd3;
	parameter WAIT_DASH_RELEASE = 4'd4;
	parameter DONE_ST = 4'd5;
	parameter WAIT_DONE_RELEASE = 4'd6;
	
	
	always_ff @ (negedge rst_n or posedge clk) begin
		
		// reset logic
		if (!rst_n) begin 
			buffer_in <= 5'd0;
			counter <= 3'd0;
			current_state <= IDLE;
			register[0] <= 8'd0;			
			register[1] <= "#";
			register[2] <= 8'd0;
			register[3] <= 8'd0;
		end 
		// writes synchronous to clk
		else begin 
			current_state <= next_state;
			case (current_state) 
			IDLE:
				begin 
					if (write_enable) begin						// HPS will clear this register only on this state or WAIT_DONE_RELEASE
						register[address] <= write_data;
					end
					else begin 
						register[0] <= register[0];
						register[1] <= register[1];
						register[2] <= {3'd0,buffer_in};
						register[3] <= {5'd0,counter};
					end
					// avoid latches
					buffer_in <= buffer_in;
					counter <= counter;
				end
			DOT_ST:
				begin 
					buffer_in[counter] <= DOT;
					if (counter == 3'd4) begin 
						counter <= 3'd0;
					end
					else begin 
						counter <= counter + 3'd1;
					end
					// avoid latches 
					register[0] <= register[0];			
					register[1] <= register[1];
					register[2] <= {3'd0,buffer_in};
					register[3] <= {5'd0,counter};
				end
			DASH_ST:
				begin 
					buffer_in[counter] <= DASH;
					if (counter == 3'd4) begin 
						counter <= 3'd0;
					end
					else begin 
						counter <= counter + 3'd1;
					end
					// avoid latches 
					register[0] <= register[0];			
					register[1] <= register[1];
					register[2] <= {3'd0,buffer_in};
					register[3] <= {5'd0,counter};
				end
			DONE_ST:
				begin 
					case (counter)
						3'd0:
							begin
								case ({buffer_in[0],buffer_in[1],buffer_in[2],buffer_in[3],buffer_in[4]})		// if counter is back to 0, it means we filled the whole buffer
									{DASH,DASH,DASH,DASH,DASH}: 	register[1] <= "0";
									{DOT,DASH,DASH,DASH,DASH}: 	register[1] <= "1";
									{DOT,DOT,DASH,DASH,DASH}: 		register[1] <= "2";
									{DOT,DOT,DOT,DASH,DASH}: 		register[1] <= "3";
									{DOT,DOT,DOT,DOT,DASH}: 		register[1] <= "4";
									{DOT,DOT,DOT,DOT,DOT}: 			register[1] <= "5";
									{DASH,DOT,DOT,DOT,DOT}: 		register[1] <= "6";
									{DASH,DASH,DOT,DOT,DOT}: 		register[1] <= "7";
									{DASH,DASH,DASH,DOT,DOT}: 		register[1] <= "8";
									{DASH,DASH,DASH,DASH,DOT}: 	register[1] <= "9";
									default:								register[1] <= "#";
								endcase
							end
						3'd1:
							begin
								case (buffer_in[0])
									{DOT}:								register[1] <= "E";
									{DASH}:								register[1] <= "T";
									default:								register[1] <= "#";
								endcase
							end
						3'd2:
							begin
								case ({buffer_in[0],buffer_in[1]})
									{DOT,DASH}:							register[1] <= "A";
									{DOT,DOT}:							register[1] <= "I";
									{DASH,DASH}:						register[1] <= "M";
									{DASH,DOT}:							register[1] <= "N";
									default:								register[1] <= "#";
								endcase
							end
						3'd3:
							begin
								case ({buffer_in[0],buffer_in[1],buffer_in[2]})
									{DASH,DOT,DOT}:					register[1] <= "D";
									{DASH,DASH,DOT}:					register[1] <= "G";
									{DASH,DOT,DASH}:					register[1] <= "K";
									{DASH,DASH,DASH}:					register[1] <= "O";
									{DOT,DASH,DOT}:					register[1] <= "R";
									{DOT,DOT,DOT}:						register[1] <= "S";
									{DOT,DOT,DASH}:					register[1] <= "U";
									{DOT,DASH,DASH}:					register[1] <= "W";
									default:								register[1] <= "#";
								endcase
							end
						3'd4:
							begin
								case ({buffer_in[0],buffer_in[1],buffer_in[2],buffer_in[3]})
									{DASH,DOT,DOT,DOT}:				register[1] <= "B";
									{DASH,DOT,DASH,DOT}:				register[1] <= "C";
									{DOT,DOT,DASH,DOT}:				register[1] <= "F";
									{DOT,DOT,DOT,DOT}: 				register[1] <= "H";
									{DOT,DASH,DASH,DASH}: 			register[1] <= "J";
									{DOT,DASH,DOT,DOT}:				register[1] <= "L";
									{DOT,DASH,DASH,DOT}:				register[1] <= "P";
									{DASH,DASH,DOT,DASH}:			register[1] <= "Q";
									{DOT,DOT,DOT,DASH}:				register[1] <= "V";
									{DASH,DOT,DOT,DASH}:				register[1] <= "X";
									{DASH,DOT,DASH,DASH}:			register[1] <= "Y";
									{DASH,DASH,DOT,DOT}:				register[1] <= "Z";
									default:								register[1] <= "#";
								endcase
							end
						default:											register[1] <= "#";
					endcase
					counter <= 3'd0;			// reset counter
					buffer_in <= 5'd0;		// reset buffer
					register[0] <= 8'd1;		// set ready char flag
					register[2] <= {3'd0,buffer_in};
					register[3] <= {5'd0,counter};
				end
			WAIT_DOT_RELEASE:
				begin 
					// avoid latches
					buffer_in <= buffer_in;
					counter <= counter;
					register[0] <= register[0];			
					register[1] <= register[1];
					register[2] <= {3'd0,buffer_in};
					register[3] <= {5'd0,counter};
				end
			WAIT_DASH_RELEASE:
				begin
					// avoid latches
					buffer_in <= buffer_in;
					counter <= counter;
					register[0] <= register[0];			
					register[1] <= register[1];
					register[2] <= {3'd0,buffer_in};
					register[3] <= {5'd0,counter};
				end
			WAIT_DONE_RELEASE:
				begin 
					if (write_enable) begin						// HPS will clear this register only on this state or IDLE
						register[address] <= write_data;
					end
					else begin 
						register[0] <= register[0];
						register[1] <= register[1];
						register[2] <= {3'd0,buffer_in};
						register[3] <= {5'd0,counter};
					end
					// avoid latches
					buffer_in <= buffer_in;
					counter <= counter;
				end	
			endcase
		end // else (clk)

	end	//always_ff

	
	
	// asynchronous read
	assign read_data = register[address];
	
	
	
	always_comb begin 
		
		// next state logic
		case (current_state) 
			IDLE:
				begin 
					if (dot_in) begin
						next_state = DOT_ST;
					end
					else if (dash_in) begin 
						next_state = DASH_ST;
					end 
					else if (done_in) begin 
						next_state = DONE_ST;
					end
					else begin 
						next_state = IDLE;
					end
				end
			DOT_ST:
				begin 
					next_state = WAIT_DOT_RELEASE;
				end
			DASH_ST:
				begin 
					next_state = WAIT_DASH_RELEASE;
				end
			DONE_ST:
				begin 
					next_state = WAIT_DONE_RELEASE;
				end
			WAIT_DOT_RELEASE:
				begin 
					if (dot_in) begin 
						next_state = WAIT_DOT_RELEASE;
					end
					else begin 
						next_state = IDLE;
					end
				end
			WAIT_DASH_RELEASE:
				begin
					if (dash_in) begin
						next_state = WAIT_DASH_RELEASE;
					end
					else begin 
						next_state = IDLE;
					end
				end
			WAIT_DONE_RELEASE:
				begin 
					if (done_in) begin
						next_state = WAIT_DONE_RELEASE;
					end
					else begin 
						next_state = IDLE;
					end
				end	
		endcase
		
	end	// always_comb


	
endmodule
		
		
		
		//logic [7:0] detected_char;		// detected char after receiving dots and dashes
		//logic char_ready;					// char ready
		
		// clock logic: to update register 
		/*else if (clk) begin 
			if (char_ready) begin
				register[0] <= 8'd1;					// a flag HPS can read to know there is a new char ready
				register[1]	<= detected_char;		// store the char so HPS can read 
				char_ready <= 1'b0;					// clear ready bit to avoid double writes
			end 
			else if (write_enable) begin 
				register[address] <= write_data;
				char_ready <= char_ready;
			end 
			else begin
				register[0] <= register[0];
				register[1] <= register[1];
				char_ready <= char_ready;
			end
			// avoid latches
			buffer_in <= buffer_in;
			counter <= counter;
			detected_char <= detected_char;
		end
		
		// dot input 
		else if (dot_in) begin 
			buffer_in[counter] <= DOT;
			if (counter == 3'd4) begin 
			counter <= 3'd0;
			end
			else begin 
			counter <= counter + 3'd1;
			end
			//avoid latches
			register[0] <= register[0];
			register[1] <= register[1];
			char_ready <= char_ready;
			detected_char <= detected_char;
		end
		
		// dash input
		else if (dash_in) begin
			buffer_in[counter] <= DASH;
			if (counter == 3'd4) begin 
				counter <= 3'd0;
			end
			else begin 
				counter <= counter + 3'd1;
			end
			//avoid latches
			register[0] <= register[0];
			register[1] <= register[1];
			char_ready <= char_ready;
			detected_char <= detected_char;
		end
		
		// done logic
		else if (done_in) begin 
	
			counter <= 3'd0;			// reset counter 
			char_ready <= 1'b1;		// char is ready to be send to HPS
		
			//avoid latches
			register[0] <= register[0];
			register[1] <= register[1];
			buffer_in <= buffer_in;
			
			case (counter)
				3'd0:
					begin
						case (buffer_in[4:0])		// if counter is back to 0, it means we filled the whole buffer
							{DASH,DASH,DASH,DASH,DASH}: 	detected_char <= "0";
							{DOT,DASH,DASH,DASH,DASH}: 	detected_char <= "1";
							{DOT,DOT,DASH,DASH,DASH}: 		detected_char <= "2";
							{DOT,DOT,DOT,DASH,DASH}: 		detected_char <= "3";
							{DOT,DOT,DOT,DOT,DASH}: 		detected_char <= "4";
							{DOT,DOT,DOT,DOT,DOT}: 			detected_char <= "5";
							{DASH,DOT,DOT,DOT,DOT}: 		detected_char <= "6";
							{DASH,DASH,DOT,DOT,DOT}: 		detected_char <= "7";
							{DASH,DASH,DASH,DOT,DOT}: 		detected_char <= "8";
							{DASH,DASH,DASH,DASH,DOT}: 	detected_char <= "9";
							default:								detected_char <= "#";
						endcase
					end
				3'd1:
					begin
						case (buffer_in[0])
							{DOT}:								detected_char <= "E";
							{DASH}:								detected_char <= "T";
							default:								detected_char <= "#";
						endcase
					end
				3'd2:
					begin
						case (buffer_in[1:0])
							{DOT,DASH}:							detected_char <= "A";
							{DOT,DOT}:							detected_char <= "I";
							{DASH,DASH}:						detected_char <= "M";
							{DASH,DOT}:							detected_char <= "N";
							default:								detected_char <= "#";
						endcase
					end
				3'd3:
					begin
						case (buffer_in[2:0])
							{DASH,DOT,DOT}:					detected_char <= "D";
							{DASH,DASH,DOT}:					detected_char <= "G";
							{DASH,DOT,DASH}:					detected_char <= "K";
							{DASH,DASH,DASH}:					detected_char <= "O";
							{DOT,DASH,DOT}:					detected_char <= "R";
							{DOT,DOT,DOT}:						detected_char <= "S";
							{DOT,DOT,DASH}:					detected_char <= "U";
							{DOT,DASH,DASH}:					detected_char <= "W";
							default:								detected_char <= "#";
						endcase
					end
				3'd4:
					begin
						case (buffer_in[3:0])
							{DASH,DOT,DOT,DOT}:				detected_char <= "B";
							{DASH,DOT,DASH,DOT}:				detected_char <= "C";
							{DOT,DOT,DASH,DOT}:				detected_char <= "F";
							{DOT,DOT,DOT,DOT}: 				detected_char <= "H";
							{DOT,DASH,DASH,DASH}: 			detected_char <= "J";
							{DOT,DASH,DOT,DOT}:				detected_char <= "L";
							{DOT,DASH,DASH,DOT}:				detected_char <= "P";
							{DASH,DASH,DOT,DASH}:			detected_char <= "Q";
							{DOT,DOT,DOT,DASH}:				detected_char <= "V";
							{DASH,DOT,DOT,DASH}:				detected_char <= "X";
							{DASH,DOT,DASH,DASH}:			detected_char <= "Y";
							{DASH,DASH,DOT,DOT}:				detected_char <= "Z";
							default:								detected_char <= "#";
						endcase
					end
				default:											detected_char <= "#";
			endcase
		end
	end
	
	

	always_comb begin
	
		read_data = register[address];			// asynchronous read
		
	end

	
	
endmodule*/


/*register[2] <= "#";
			register[3] <= "#";
			register[4] <= "#";
			register[5] <= "#";
			register[6] <= "#";
			register[7] <= "#";
			register[8] <= "#";
			register[9] <= "#";
			register[10] <= "#";
			register[11] <= "#";
			register[12] <= "#";
			register[13] <= "#";
			register[14] <= "#";
			register[15] <= "#";*/


// input buffer logic
	/*always_ff @ (posedge dot_in or posedge dash_in) begin
	
		if (dot_in) begin 
			buffer_in[counter] <= DOT;
		end
		else if (dash_in) begin
			buffer_in[counter] <= DASH;
		end
		
		if (counter == 3'd4) begin 
			counter <= 3'd0;
		end
		else begin 
			counter <= counter + 3'd1;
		end
		
	end*/
	
	// detect char
	/*always_ff @ (posedge done_in) begin 
	
		counter <= 3'd0;			// reset counter 
		char_ready <= 1'b1;		// char is ready to be send to HPS
	
		case (counter)
			3'd0:
				begin
					case (buffer_in[4:0])		// if counter is back to 0, it means we filled the whole buffer
						{DASH,DASH,DASH,DASH,DASH}: 	detected_char <= "0";
						{DOT,DASH,DASH,DASH,DASH}: 	detected_char <= "1";
						{DOT,DOT,DASH,DASH,DASH}: 		detected_char <= "2";
						{DOT,DOT,DOT,DASH,DASH}: 		detected_char <= "3";
						{DOT,DOT,DOT,DOT,DASH}: 		detected_char <= "4";
						{DOT,DOT,DOT,DOT,DOT}: 			detected_char <= "5";
						{DASH,DOT,DOT,DOT,DOT}: 		detected_char <= "6";
						{DASH,DASH,DOT,DOT,DOT}: 		detected_char <= "7";
						{DASH,DASH,DASH,DOT,DOT}: 		detected_char <= "8";
						{DASH,DASH,DASH,DASH,DOT}: 	detected_char <= "9";
						default:								detected_char <= "#";
					endcase
				end
			3'd1:
				begin
					case (buffer_in[0])
						{DOT}:								detected_char <= "E";
						{DASH}:								detected_char <= "T";
						default:								detected_char <= "#";
					endcase
				end
			3'd2:
				begin
					case (buffer_in[1:0])
						{DOT,DASH}:							detected_char <= "A";
						{DOT,DOT}:							detected_char <= "I";
						{DASH,DASH}:						detected_char <= "M";
						{DASH,DOT}:							detected_char <= "N";
						default:								detected_char <= "#";
					endcase
				end
			3'd3:
				begin
					case (buffer_in[2:0])
						{DASH,DOT,DOT}:					detected_char <= "D";
						{DASH,DASH,DOT}:					detected_char <= "G";
						{DASH,DOT,DASH}:					detected_char <= "K";
						{DASH,DASH,DASH}:					detected_char <= "O";
						{DOT,DASH,DOT}:					detected_char <= "R";
						{DOT,DOT,DOT}:						detected_char <= "S";
						{DOT,DOT,DASH}:					detected_char <= "U";
						{DOT,DASH,DASH}:					detected_char <= "W";
						default:								detected_char <= "#";
					endcase
				end
			3'd4:
				begin
					case (buffer_in[3:0])
						{DASH,DOT,DOT,DOT}:				detected_char <= "B";
						{DASH,DOT,DASH,DOT}:				detected_char <= "C";
						{DOT,DOT,DASH,DOT}:				detected_char <= "F";
						{DOT,DOT,DOT,DOT}: 				detected_char <= "H";
						{DOT,DASH,DASH,DASH}: 			detected_char <= "J";
						{DOT,DASH,DOT,DOT}:				detected_char <= "L";
						{DOT,DASH,DASH,DOT}:				detected_char <= "P";
						{DASH,DASH,DOT,DASH}:			detected_char <= "Q";
						{DOT,DOT,DOT,DASH}:				detected_char <= "V";
						{DASH,DOT,DOT,DASH}:				detected_char <= "X";
						{DASH,DOT,DASH,DASH}:			detected_char <= "Y";
						{DASH,DASH,DOT,DOT}:				detected_char <= "Z";
						default:								detected_char <= "#";
					endcase
				end
			default:											detected_char <= "#";
		endcase
		
	end*/


