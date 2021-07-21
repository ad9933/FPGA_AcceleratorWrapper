module dp_bram #(
	parameter WIDTH = 72,
	parameter DEPTH = 512,
	parameter LOG_DEPTH = 9
)
(
	input				clk,
	
	input		[8:0]			addr1,
	output	reg	[WIDTH-1:0]		rdata1,
	input		[WIDTH-1:0]		wdata1,
	input				write_en1,


	input		[8:0]			addr2,
	input		[WIDTH-1:0]		wdata2,
	output	reg	[WIDTH-1:0]		rdata2,
	input				write_en2
);

(* ram_style = "block" *)
reg [WIDTH-1:0]		bram	[DEPTH-1:0];


always @(posedge clk) begin
	if(write_en1)
		bram[addr1] <= wdata1;
	else
		rdata1		<= bram[addr1];
end


always @(posedge clk) begin
	if(write_en2)
		bram[addr2] <= wdata2;
	else
		rdata2		<= bram[addr2];

end

endmodule