`timescale 1ps/1ps
module tb_RISCV;

	logic clk; 
	logic reset;

	RISCV DUT (
		.clk  (clk  ), 
		.reset(reset)
	);
	
	initial 
	begin
		clk = 0;
		forever #5 clk = ~clk;
	end
	
	initial 
	begin
		reset = 1;

		@(posedge clk);
		reset = 0;
	
		repeat(1000) @(posedge clk);
		//$display("y = %d",DUT.r1.Reg[1]);
		
		@(posedge clk);
		reset = 1;
		
		@(posedge clk);
		reset = 0;
		
		@(posedge clk);
		
		$stop;
	end

endmodule: tb_RISCV
