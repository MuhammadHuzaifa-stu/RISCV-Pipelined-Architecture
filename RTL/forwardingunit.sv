module forwardingunit (
    input  logic [31:0] in1,
    input  logic [31:0] in2, 
    input  logic        reg_write,
    input  logic        br_taken,

    output logic       out1,
    output logic       out2,
    output logic       flush
);
    
    // in1 => instruction in 2nd stage
    // in2 => instruction in 3rd stage
    // out1=> For_A
    // out2=> For_B
    
    always_comb 
    begin
        // This block is for forwarding signals
        if (((in2[6:0] != 7'b0000011) & (in2[6:0] != 7'b1100011) & 
             (in2[6:0] != 7'b1101111) & (in2[6:0] != 7'b1100111)) & reg_write) 
        begin
            if ((in1[19:15] == in2[11:7]) & (in2[11:7] != 5'd0)) 
            begin // rs1 data
                flush = 0; 
                out1  = 1; 
                out2  = 0; 
            end
            else if ((in1[24:20] == in2[11:7]) & (in2[11:7] != 5'd0)) 
            begin // rs2 data
                flush = 0; 
                out1  = 0; 
                out2  = 1;
            end
            else 
            begin
                flush = 0; 
                out1  = 0; 
                out2  = 0;
            end
        end
        // This block is for flushing signal
        else if (br_taken) 
        begin
            flush = 1; 
            out1  = 0; 
            out2  = 0;
        end
        // This block acts as by_default
        else 
        begin
            out1  = 0; 
            out2  = 0; 
            flush = 0;
        end    
    end

endmodule: forwardingunit
