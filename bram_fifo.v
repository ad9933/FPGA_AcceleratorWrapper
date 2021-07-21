module bram_fifo #(
	parameter	WIDTH = 72,
	parameter	DEPTH = 512,
	parameter	LOG_DEPTH = 9
)
(
	input						clk,
	input						resetn,

	input		[WIDTH-1:0]		ss_data,
	input						ss_valid,
	output	reg 				ss_ready,

	output		[WIDTH-1:0]		ms_data,
	output						ms_valid,
	input 						ms_ready

);

reg		[LOG_DEPTH-1:0]			data_num;
reg		[LOG_DEPTH-1:0]			current;

reg		[1:0]					address_pipeline;

reg		[1:0]					ready_reg;


//BRAM instance
dp_bram BRAM (
	.clk(clk),

	.addr1(current),
	.rdata1(),
	.wdata1(ss_data),
	.write_en1(ss_ready && ss_valid),

	.addr2(current - data_num),
	.rdata2(ms_data),
	.wdata2(),
	.write_en2(1'b0)
);

always @(*) begin
	ss_ready = (data_num != 511) ? 1 : 0;
	
end



wire writeonly;
wire readandwrite;
wire readonly;

assign writeonly = (ss_ready && ss_valid) && ~(ms_ready && ms_valid);
assign readandwrite = (ss_ready && ss_valid) && (ms_ready && ms_valid);
assign writeonly = ~(ss_ready && ss_valid) && (ms_ready && ms_valid);

assign ms_valid = ready_reg[1];


always @(posedge clk) begin
	
end

always @(posedge clk) begin
	if(~resetn) begin
		ready_reg <= 0;
	end
	else begin
		if(ss_ready && ss_valid) begin
			ready_reg[0] <= 1;
		end
		else begin
			ready_reg[0] <= 0;
		end

		ready_reg[1] <= ready_reg[0];
	end
end



always @(posedge clk) begin
	if(~resetn) begin
		data_num <= 0;
		current <= 0;
	end
	else begin

		if(writeonly) begin
			data_num <= data_num + 1;
			current <= current + 1;
		end
		else if (readandwrite) begin
			current <= current + 1;
		end
		else if (readonly) begin
			data_num <= data_num - 1;
		end


	end
end



endmodule
