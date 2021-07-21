module dma_module #(
	//Data size which DMA is trying to receive in byte / bus width
	parameter DATA_SIZE = 1280*720*3 / 8;
	
	//log2(DATA_SIZE / bus width)
	parameter DATA_SIZE_LOG = 19;
	
	//Burst per transaction
	parameter BURST_SIZE = 16;
	
	
	
	
)
(
	
	///////////////////////////
	//AXI 3 Master interface
	///////////////////////////
	
	//global signal
	input			m_axi_acp_aclk,
	input			axi_resetn,
	
	
	//read address channel
	output	[2:0]	m_axi_acp_arid,		//OK
	output	[31:0]	m_axi_acp_araddr,	//TODO : Zynq ignores last 2 bits(assumes that data is aligned every time)
	output	[3:0]	m_axi_acp_arlen,	//OK
	output	[2:0]	m_axi_acp_arsize,	//OK
	output	[1:0]	m_axi_acp_arburst,	//OK
	output	[1:0]	m_axi_acp_arlock,	//OK
	output 	[3:0]	m_axi_acp_arcache,	//OK?
	output	[2:0]	m_axi_acp_arprot,	//OK
	output	[3:0]	m_axi_acp_arqos,	//OK
	output	[4:0]	m_axi_acp_aruser,	//OK
	output	reg		m_axi_acp_arvalid,	//OK
	input			m_axi_acp_arready,	//OK
	
	
	//read data channel
	input	[2:0]	m_axi_acp_rid,
	input	[63:0]	m_axi_acp_rdata,
	input	[1:0]	m_axi_acp_rresp,
	input			m_axi_acp_rlast,
	//input			m_axi_acp_ruser,
	input			m_axi_acp_rvalid,
	output			m_axi_acp_rready,
	
	
	//write address channel
	output	[2:0]	m_axi_acp_awid,
	output	[31:0]	m_axi_acp_awaddr,
	output	[3:0]	m_axi_acp_awlen,
	output	[2:0]	m_axi_acp_awsize,
	output	[1:0]	m_axi_acp_awburst,
	output	[1:0]	m_axi_acp_awlock,	
	output	[3:0]	m_axi_acp_awcache,
	output	[2:0]	m_axi_acp_awprot,
	output	[3:0]	m_axi_acp_awqos,
	output	[4:0]	m_axi_acp_awuser,
	output			m_axi_acp_awvalid,
	input			m_axi_acp_awready,
	
	
	//write data channel
	output	[2:0]	m_axi_acp_wid,
	output	[63:0]	m_axi_acp_wdata,
	output	[7:0]	m_axi_acp_wstrb,
	output			m_axi_acp_wlast,
	output	[4:0]	m_axi_acp_wuser,
	output			m_axi_acp_wvalid,
	input			m_axi_acp_wready,
	
	
	//write response
	input	[2:0]		m_axi_acp_bid,
	input	[1:0]		m_axi_acp_bresp,
	input	[4:0]		m_axi_acp_buser,
	input				m_axi_acp_bvalid,
	output				m_axi_acp_bready,
	
	
	
	
	
	////////////////////////////////////
	//Stream Interface (Output)
	////////////////////////////////////
	
	output	[63:0]		mm2s_data,
	output				mm2s_valid,
	input				mm2s_ready
	
	
	
);


	//Number of transaction need to get data
	localparam TRANS_NUM = DATA_SIZE / BURST_SIZE ;
	
	
	//Pass ready signal to AXI 3 interface
	assign m_axi_acp_rready = mm2s_ready;

	//Fixed transaction ID
	assign m_axi_acp_arid = 3'b100;
	assign m_axi_acp_awid = 3'b100;
	assign m_axi_acp_wid = 3'b100;
	
	//Fixed burst size
	assign m_axi_acp_arlen = BURST_SIZE - 1;
	
	//INCR type burst
	assign m_axi_acp_arburst = 2'b01;
	assign m_axi_acp_awburst = 2'b01;
	
	//Normal access
	assign m_axi_acp_arlock = 2'b00;
	assign m_axi_acp_awlock = 2'b00;
	
	//Device bufferable
	assign m_axi_acp_arcache = 4'b0001;
	assign m_axi_acp_awcache = 4'b0001;
	
	//Protection(last bit ignored by zynq)
	assign m_axi_acp_arprot = 3'b01x;
	assign m_axi_acp_awprot = 3'b01x;

	//Does not participate in qos scheme
	assign m_axi_acp_arqos = 4'b0000;
	assign m_axi_acp_awqos = 4'b0000;

	//Does not use user signals
	assign m_axi_acp_aruser = 5'bxxxxx;
	assign m_axi_acp_awuser = 5'bxxxxx;
	
	
	////////////////////////
	//Register assignment
	////////////////////////
	
	//DMA target read address
	reg [31:0]							target_addr;
	//Number of data read from one burst
	reg [3:0]							rdata_bnum;
	
	
	//Number of data read from DMA
	reg [DATA_SIZE_LOG-1:0] 			rdata_num;
	//number of burst happened
	wire [DATA_SIZE_LOG-1-4:0]				rburst_num;
	assign rburst_num = rdata_num[DATA_SIZE_LOG-1:5];
	
	
	
	
	////////////////////////
	//Read address channel
	////////////////////////
	
	//arvalid signal control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			m_axi_acp_arvalid <= 0;
		end
		else begin
			if(rdata_bnum == 0 && ~m_axi_acp_arvalid && (rdata_num < DATA_SIZE)) begin
				target_addr <= target_addr + rburst_num*8;
				m_axi_acp_arvalid <= 1;
			end
			else if(m_axi_acp_arvalid && m_axi_acp_arready) begin
				m_axi_acp_arvalid <= 0;
			end
		end
	end
	
	
	
	////////////////////////
	//Read data channel
	////////////////////////
	
	//Receive data & count data
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			rdata_bnum <= 0;
			rdata_num <= 0;
		end
		else begin
			if(m_axi_acp_rready && m_axi_acp_rvalid) begin
				//DATA_BUFFER <= m_axi_acp_rdata;
				rdata_bnum <= rdata_bnum + 1;
				rdata_num <= rdata_num + 1;
				
			end
			
		end
		
	end




endmodule