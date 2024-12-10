module counter(
	input clk,
	input areset,
	input ready_in,
	output reg valid,
	output reg [127:0] count
	);
	
	// Internals
	reg [127:0] ctr;
	
	
	// Combinational block
	always@ (posedge clk) begin		
		if (~areset) begin
			ctr<=0;
			
		end else begin
			if(ready_in) begin
				ctr <= ctr + 1;
				valid <=1'b1;
		end
			else begin
				ctr <= 0;
				valid <=0;
			end
	end
end	
	// Assignments 
	assign count = ctr;
	
endmodule

