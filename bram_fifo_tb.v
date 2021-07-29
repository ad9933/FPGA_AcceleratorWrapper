`timescale 1ns/1ps

module bram_fifo_tb ();

	reg             clk = 0;
	reg             resetn;
	
	reg     [71:0]  ss_data = 0;
	reg				ss_valid;
	wire 			ss_ready;

	wire	[71:0]	ms_data;
	wire			ms_valid;
	reg 			ms_ready; 			

	bram_fifo FIFO(
		.clk(clk),
		.resetn(resetn),

		.ss_data(ss_data),
		.ss_valid(ss_valid),
		.ss_ready(ss_ready),

		.ms_data(ms_data),
		.ms_valid(ms_valid),
		.ms_ready(ms_ready)
	);
	
	initial begin
		resetn = 0;
		#30;
		resetn = 1;
	end
	

	always begin
		#6 clk = ~clk;
	end

	always @(posedge clk) begin
		#2 ss_valid	= $random() % 2;
		ms_ready = $random() % 2;
	
	end

	always @(posedge clk) begin
		if(ss_valid && ss_ready) begin
			#1 ss_data = ss_data + 1;
		end
	end
	
	always @(posedge clk) begin
		if(ms_valid && ms_ready) begin
			$display("[*]Output : %d", ms_data);
		end
	end

endmodule