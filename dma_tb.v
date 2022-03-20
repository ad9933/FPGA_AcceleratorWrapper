module dma_tb();

    reg clk;
    reg resetn;

    wire FIXED_IO_ps_clk;
    wire FIXED_IO_ps_porb;
    wire FIXED_IO_ps_srstb;

    assign FIXED_IO_ps_clk = clk;
    assign FIXED_IO_ps_porb = resetn;
    assign FIXED_IO_ps_srstb = resetn;

    design_1_wrapper u_design_1_wrapper(
    .DDR_addr         (          ),
    .DDR_ba           (            ),
    .DDR_cas_n        (         ),
    .DDR_ck_n         (          ),
    .DDR_ck_p         (          ),
    .DDR_cke          (           ),
    .DDR_cs_n         (          ),
    .DDR_dm           (            ),
    .DDR_dq           (            ),
    .DDR_dqs_n        (         ),
    .DDR_dqs_p        (         ),
    .DDR_odt          (           ),
    .DDR_ras_n        (         ),
    .DDR_reset_n      (       ),
    .DDR_we_n         (          ),
    .FIXED_IO_ddr_vrn (  ),
    .FIXED_IO_ddr_vrp (  ),
    .FIXED_IO_mio     (      ),
    .FIXED_IO_ps_clk  ( FIXED_IO_ps_clk  ),
    .FIXED_IO_ps_porb ( FIXED_IO_ps_porb ),
    .FIXED_IO_ps_srstb ( FIXED_IO_ps_srstb )
);

    initial begin
       clk = 1'b0;
    end

    always #10 clk = !clk;


    initial
    begin
    
        $display ("running the tb");
        
        resetn = 1'b0;
        repeat(2)@(posedge clk);        
        resetn = 1'b1;
        @(posedge clk);
        
        repeat(5) @(posedge clk);
          
        //Reset the PL
        dma_tb.u_design_1_wrapper.design_1_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        dma_tb.u_design_1_wrapper.design_1_i.processing_system7_0.inst.fpga_soft_reset(32'h0);

        //Random memory set
        //dma_tb.u_design_1_wrapper.design_1_i.processing_system7_0.inst.pre_load_mem(2'b00, 32'h)
        

        $display ("Simulation completed");
        $stop;
    end


endmodule