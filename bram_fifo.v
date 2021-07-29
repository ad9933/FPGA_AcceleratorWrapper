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
	output	reg					ms_valid,
	input 						ms_ready

);

reg		[LOG_DEPTH-1:0]			data_num;

reg		[LOG_DEPTH-1:0]			write_addr;

reg 	[LOG_DEPTH-1:0]			read_addr;


//BRAM instance
dp_bram BRAM (
	.clk(clk),

	.addr1(write_addr),
	.rdata1(),
	.wdata1(ss_data),
	.write_en1(ss_ready && ss_valid),
	.output_en1(),

	.addr2(read_addr),
	.rdata2(ms_data),
	.wdata2(),
	.write_en2(1'b0),
	.output_en2(ms_ready && (write_addr != read_addr))
);

always @(*) begin
	ss_ready = ((data_num != 511) && resetn) ? 1 : 0;
	
end


//Read address counter
always @(posedge clk) begin
	if(~resetn) begin
		read_addr <= 0;
	end
	else begin
		if(ms_ready && (write_addr != read_addr))
			read_addr <= read_addr + 1;
	end		
end


//data_num counter & write address counter
wire writeonly;
wire readandwrite;
wire readonly;

assign writeonly = (ss_ready && ss_valid) && ~(ms_ready && ms_valid);
assign readandwrite = (ss_ready && ss_valid) && (ms_ready && ms_valid);
assign readonly = ~(ss_ready && ss_valid) && (ms_ready && ms_valid);

always @(posedge clk) begin
	if(~resetn) begin
		data_num <= 0;
		write_addr <= 0;
	end
	else begin

		if(writeonly) begin
			data_num <= data_num + 1;
			write_addr <= write_addr + 1;
		end
		else if (readandwrite) begin
			write_addr <= write_addr + 1;
		end
		else if (readonly) begin
			data_num <= data_num - 1;
		end


	end
end



//Valid control
always @(posedge clk) begin
	if(~resetn) begin
		ms_valid <= 0;
	end
	else begin
		if(ms_ready && (write_addr != read_addr) || (ms_ready && ms_valid))
			ms_valid <= (write_addr == read_addr) ? 0 : 1;
	end
	
end



endmodule
