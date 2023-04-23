module controll(input logic a,b,c,input logic [1:0] d,input logic cs,clk,rst, 
				output logic e,f,g,cso, output logic [1:0] h);
	
	always_ff @(posedge clk)
	
	begin

		if (rst) begin
			e <= 1'b0; f <= 1'b0; g <= 1'b0; h <= 2'b0; cso <= 1'b0;
		end

		else begin
			e <= a; f <= b; g <= c; h <= d; cso <= cs;
		end

	end

endmodule