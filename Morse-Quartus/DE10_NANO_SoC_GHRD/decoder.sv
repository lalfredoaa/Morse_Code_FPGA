


module decoder(	
	
	// Avalon interface
	input logic clk, 		
	input logic rst_n,
	input logic[3:0] address,
	output logic [7:0] read_data, 
	
	// FPGA input
	input logic button_in
	
	);
	
	logic [7:0] register [15:0];
	
	logic [3:0] local_address;
	
	always_comb begin
	
		read_data = register[address];
		
	end
	
	
	always_ff @ (posedge button_in or negedge rst_n)  begin
	
		if(!rst_n) begin 
			register[0] <= "a";
			register[1] <= "b";
			register[2] <= "c";
			register[3] <= "d";
			register[4] <= "e";
			register[5] <= "f";
			register[6] <= "g";
			register[7] <= "h";
			register[8] <= "i";
			register[9] <= "j";
			register[10] <= "k";
			register[11] <= "l";
			register[12] <= "m";
			register[13] <= "n";
			register[14] <= "o";
			register[15] <= "p";
			local_address <= 4'd0;
		end
		else begin 
			register[local_address] <= "z";
			local_address <= local_address + 4'd1;
		end
		
	end
	
	
endmodule





