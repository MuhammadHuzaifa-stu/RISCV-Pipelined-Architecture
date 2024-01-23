module RISCV (
	input logic clk, 
	input logic reset
);

	// Declared all the necessary variables	
	logic [31:0] inst;
	logic [31:0] inst_out_1;
	logic [31:0] rdata1;
	logic [31:0] rdata2;
	logic [31:0] ALU_out;
	logic [31:0] ALU_out2;
	logic [31:0] wdata2;
	logic [31:0] imme_out;
	logic [31:0] inst_out_2;
	logic [31:0] rdata1_or_ALU_out2;
	logic [31:0] rdata2_or_ALU_out2;
	logic [31:0] rs2_or_imme;
	logic [31:0] read_data_out;
	logic [31:0] rdata2_out;
	logic [31:0] rs1_or_pc;
	logic [31:0] adder_out;
	logic [31:0] pc_out;
	logic [31:0] pc_out2;
	logic [31:0] pc_out3;
	logic [31:0] pc_input;
	logic [31:0] jump;
	
	logic        reg_write;
	logic        reg_write_MW;
	logic        sel_B;
	logic        sel_A;
	logic        rd_en;
	logic        rd_enMW;
	logic        wr_en;
	logic        wr_enMW;
	logic        cs;
	logic        cs_out;
	logic        br_taken;
	logic        br_tak;
	logic        For_A;
	logic        For_B;
	logic        flush;
	
	logic [3:0]  aluop;
	logic [3:0]  mask;
	logic [2:0]  br_type;
	logic [1:0]  wb_sel;
	logic [1:0]  wb_selMW;
	
	// adder
	adder add1 (
		.pc_in    (pc_out   ), 
		.adder_out(adder_out)
	);
	
	//mux for pc and branch/jump
	mux2x1 m1 (
		.a(adder_out),
		.b(ALU_out2 ),
		.s(br_taken ),
		.y(pc_input )
	);
	
	//PC
	pc_reg pcreg (
		.clk   (clk     ),
		.reset (reset   ),
		.in    (pc_input),
		.pc_out(pc_out  )
	);
	
	//Intruction memory
	Instmem Inst_mem (
		.Address    (pc_out), 
		.Instruction(inst  )
	);
	
	//REGISTER Separating Fetch and Decode phase
	reg_IR Reg_IR (
		.clk  (clk       ),
		.rst  (reset     ),
		.flush(flush     ),
		.a    (inst      ),
		.b    (inst_out_1)
	);

	register Reg_PC_1 (
		.clk(clk    ),
		.rst(reset  ),
		.a  (pc_out ),
		.b  (pc_out2)
	);
	
	//register file
	regfile r1 (
		.Clk     (clk              ),
		.RegWrite(reg_write_MW     ),
		.raddr1  (inst_out_1[19:15]),
		.raddr2  (inst_out_1[24:20]),
		.waddr   (inst_out_2[11:7] ), 
		.wdata   (wdata2           ),
		.rdata1  (rdata1           ),
		.rdata2  (rdata2           )
	);
	
	//Immediate generator
	imme_gen im1 (
		.in (inst_out_1),
		.out(imme_out  )
	);
	
	//mus for forwarding rs1 or ALU_out
	mux21 m2 (
		.a(rdata1            ),
		.b(ALU_out2          ),
		.s(For_A             ),
		.y(rdata1_or_ALU_out2)
	);

	//mux for rs1 and pc
	mux21 m3 (
		.a(rdata1_or_ALU_out2),
		.b(pc_out2           ),
		.s(sel_A             ),
		.y(rs1_or_pc         )
	);
	
	//mus for forwarding rs2 or ALU_out
	mux21 m4 (
		.a(rdata2            ),
		.b(ALU_out2          ),
		.s(For_B             ),
		.y(rdata2_or_ALU_out2)
	);

	//mux for rs2 and immediate 12'
	mux21 m5 (
		.a(rdata2_or_ALU_out2),
		.b(imme_out          ),
		.s(sel_B             ),
		.y(rs2_or_imme       )
	);
	
	//ALU
	ALU A1 (
		.a     (rs1_or_pc  ),
		.b     (rs2_or_imme),
		.alu   (aluop      ),
		.result(ALU_out    )
	);
	
	// Branch Condition
	branchcond br1 (
		.rs1     (rdata1_or_ALU_out2),
		.rs2     (rdata2_or_ALU_out2),
		.opcode  (inst_out_1        ),
		.br_type (br_type           ),
		.br_taken(br_tak            )
	);
	
	// REGISTER for Branch
	register_1bit Reg_BR_1 (
		.clk  (clk     ),
		.rst  (reset   ),
		.flush(flush   ),
		.a    (br_tak  ),
		.b    (br_taken)
	);
	
	// REGISTER for LSU and wdata_addr of register file
	reg_IR Reg_IR_1 (
		.clk  (clk       ),
		.rst  (reset     ),
		.flush(flush     ),
		.a    (inst_out_1),
		.b    (inst_out_2)
	);
	
	//Forwarding unit
	forwardingunit For1 (
		.in1      (inst_out_1  ),
		.in2      (inst_out_2  ),
		.reg_write(reg_write_MW),
		.br_taken (br_taken    ),
	    .out1     (For_A       ),
		.out2     (For_B       ),
		.flush    (flush       )
	);

	// LSU
	LSU L1 (
		.inst(inst_out_2),
		.mask(mask      )
	);

	// Separating Decode and Execute phase from DM and WB
	register Reg_PC_2 (
		.clk(clk    ),
		.rst(reset  ),
		.a  (pc_out2),
		.b  (pc_out3)
	);
	
	register Reg_ALU_1 (
		.clk(clk     ),
		.rst(reset   ),
		.a  (ALU_out ),
		.b  (ALU_out2)
	);
	
	register Reg_WD (
		.clk(clk               ),
		.rst(reset             ),
		.a  (rdata2_or_ALU_out2),
		.b  (rdata2_out        )
	);
	
	// data memory
	data_memory dm1 (
		.clk       (clk          ),
		.reset     (reset        ),
		.rd_en     (rd_enMW      ),
		.wr_en     (wr_enMW      ),
		.addr      (ALU_out2     ),
		.write_data(rdata2_out   ),
		.mask      (mask         ),
		.cs        (cs_out       ),
		.read_data (read_data_out)
	);
	
	// adder for jump
	adder add2 (
		.pc_in    (pc_out3), 
		.adder_out(jump   )
	);

	// mux for ALU and Data_memory and jump 32'
	mux4x1 m6 (
		.a(ALU_out2     ),
		.b(read_data_out),
		.c(jump         ),
		.s(wb_selMW     ),
		.y(wdata2       )
	);
	
	// controller
	controller controller_1 (
		.func7           (inst_out_1[31:25]),
		.func3           (inst_out_1[14:12]),
		.opcode          (inst_out_1[6:0]  ),
		.alu_control     (aluop            ),
		.regwrite_control(reg_write        ),
		.sel_B           (sel_B            ),
		.rd_en           (rd_en            ),
		.wr_en           (wr_en            ),
		.wb_sel          (wb_sel           ),
		.cs              (cs               ),
		.sel_A           (sel_A            ),
		.br_type         (br_type          )
	);
					
	// REGISTER for controller
	controll controll_1 (
		.clk(clk         ),
		.rst(reset       ),
		.a  (reg_write   ),
		.b  (wr_en       ),
		.c  (rd_en       ),
		.d  (wb_sel      ),
		.cs (cs          ),
		.e  (reg_write_MW),
		.f  (wr_enMW     ),
		.g  (rd_enMW     ),
		.cso(cs_out      ),
		.h  (wb_selMW    )
	);
	
endmodule: RISCV