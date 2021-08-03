module dma_module #(
	//Data size which DMA is trying to receive in byte / bus width
	parameter DATA_SIZE = 1280 * 720 * 3 / 8,
	
	//log2(DATA_SIZE / bus width)
	parameter DATA_SIZE_LOG = 19,
	
	//Burst per transaction
	parameter BURST_SIZE = 16,
	
	//Number of burst needed
	parameter BURST_NUM = DATA_SIZE / BURST_SIZE
	
	
)
(
	
	///////////////////////////
	//Control signals
	///////////////////////////

	//Read channel control
	input					read_active,
	input		[31:0]		read_address,

	output	reg				read_idle,


	//Write channel control
	input					write_active,
	input		[31:0]		write_address,

	output 	reg 			write_idle,


	//Read, write response data - {read response, write response}
	output		[3:0]			rw_resp,



	///////////////////////////
	//AXI 3 Master interface
	///////////////////////////
	
	//global signal
	input					m_axi_acp_aclk,
	input					axi_resetn,
	
	
	//read address channel
	output		[2:0]		m_axi_acp_arid,		//OK
	output	reg	[31:0]		m_axi_acp_araddr,	//TODO : Zynq ignores last 2 bits(assumes that data is aligned every time)
	output		[3:0]		m_axi_acp_arlen,	//OK
	output		[2:0]		m_axi_acp_arsize,	//OK
	output		[1:0]		m_axi_acp_arburst,	//OK
	output		[1:0]		m_axi_acp_arlock,	//OK
	output 		[3:0]		m_axi_acp_arcache,	//OK?
	output		[2:0]		m_axi_acp_arprot,	//OK
	output		[3:0]		m_axi_acp_arqos,	//OK
	output		[4:0]		m_axi_acp_aruser,	//OK
	output	reg				m_axi_acp_arvalid,	//OK
	input					m_axi_acp_arready,	//OK
	
	
	//read data channel
	input		[2:0]		m_axi_acp_rid,
	input		[63:0]		m_axi_acp_rdata,
	input		[1:0]		m_axi_acp_rresp,
	input					m_axi_acp_rlast,
	//input					m_axi_acp_ruser,
	input					m_axi_acp_rvalid,
	output					m_axi_acp_rready,
	
	
	//write address channel
	output		[2:0]		m_axi_acp_awid,
	output	reg	[31:0]		m_axi_acp_awaddr,
	output		[3:0]		m_axi_acp_awlen,
	output		[2:0]		m_axi_acp_awsize,
	output		[1:0]		m_axi_acp_awburst,
	output		[1:0]		m_axi_acp_awlock,	
	output		[3:0]		m_axi_acp_awcache,
	output		[2:0]		m_axi_acp_awprot,
	output		[3:0]		m_axi_acp_awqos,
	output		[4:0]		m_axi_acp_awuser,
	output	reg				m_axi_acp_awvalid,
	input					m_axi_acp_awready,
	
	
	//write data channel
	output		[2:0]		m_axi_acp_wid,
	output		[63:0]		m_axi_acp_wdata,
	output		[7:0]		m_axi_acp_wstrb,
	output	reg				m_axi_acp_wlast,
	output		[4:0]		m_axi_acp_wuser,
	output					m_axi_acp_wvalid,
	input					m_axi_acp_wready,
	
	
	//write response
	input		[2:0]		m_axi_acp_bid,
	input		[1:0]		m_axi_acp_bresp,
	input		[4:0]		m_axi_acp_buser,
	input					m_axi_acp_bvalid,
	output	reg				m_axi_acp_bready,
	
	
	
	
	
	////////////////////////////////////
	//Stream Interface (Output)
	////////////////////////////////////
	
	output		[63:0]	mm2s_data,
	output				mm2s_valid,
	input				mm2s_ready,
	
	//////////////////////////////////// 
	//Stream Interface (Input)
	////////////////////////////////////
	
	input	[63:0]		s2mm_data,
	input				s2mm_valid,
	output				s2mm_ready
	
);

	//Number of transaction need to get data
	localparam TRANS_NUM = DATA_SIZE / BURST_SIZE ;
	

	//Fixed transaction ID
	assign m_axi_acp_arid = 3'b100;
	assign m_axi_acp_awid = 3'b100;
	assign m_axi_acp_wid = 3'b100;
	
	//Fixed burst size
	assign m_axi_acp_arlen = BURST_SIZE - 1;
	assign m_axi_acp_awlen = BURST_SIZE - 1;
	
	//2 bytes per transfer
	assign m_axi_acp_arsize = 3'b011;
	assign m_axi_acp_awsize = 3'b011;
	assign m_axi_acp_wstrb = 8'b1111_1111;
	
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
	assign m_axi_acp_arprot = 3'b010;
	assign m_axi_acp_awprot = 3'b010;

	//Does not participate in qos scheme
	assign m_axi_acp_arqos = 4'b0000;
	assign m_axi_acp_awqos = 4'b0000;

	//Does not use user signals
	assign m_axi_acp_aruser = 5'b00000;
	assign m_axi_acp_awuser = 5'b00000;
	
	

	////////////////////////////////////
	//Register assignment
	////////////////////////////////////
	
	//Read address channel
	reg	[DATA_SIZE_LOG-1:0]			rdata_count;
	reg 							rdata_ch_active;

	//Write address channel
	reg	[DATA_SIZE_LOG-1:0]			wdata_count;
	reg 							wdata_ch_active;

	//Write response channel
	reg [1:0]						bresp;
	
	
	//Response concat
	assign rw_resp = {m_axi_acp_rresp, bresp};

	////////////////////////////////////
	//Read address channel
	////////////////////////////////////
	
	//Set read address
	always @(posedge m_axi_acp_aclk) begin
		if(read_active)
			m_axi_acp_araddr <= read_address;
		else if(m_axi_acp_arvalid && m_axi_acp_arready)
			m_axi_acp_araddr <= m_axi_acp_araddr + 32'h400;
	
	end
	
	//Valid signal control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			m_axi_acp_arvalid <= 0;
		end
		else if(m_axi_acp_arvalid && m_axi_acp_arready) begin
			m_axi_acp_arvalid <= 0;
		end
		else begin
			m_axi_acp_arvalid <= ~rdata_ch_active && ((rdata_count[3:0] == 0) || read_active) && ~read_idle;
		end
		
	end

	//Read data channel activate control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			rdata_ch_active <= 0;
		end
		else begin
			if(m_axi_acp_arvalid && m_axi_acp_arready  ||  rdata_count[3:0] == 4'b1111) begin
				rdata_ch_active <= (rdata_count[3:0] == 4'b1111) ? 0 : 1;
			end
		end
		
	end

	//Idle signal control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			read_idle <= 1;
		end
		else begin
			if(rdata_count[DATA_SIZE_LOG-1:4] == BURST_NUM)
				read_idle <= (rdata_count[DATA_SIZE_LOG-1:4] == BURST_NUM) ? 1 : 0;
			else if(read_active)
				read_idle <= 0;
			
		end
	end

	//Data counter
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin 
			rdata_count <= 0;
		end
		else begin
			if(m_axi_acp_rready && m_axi_acp_rvalid)
				rdata_count <= rdata_count + 1;
		end
	end
	


	////////////////////////////////////
	//Read data channel
	////////////////////////////////////
	
	assign mm2s_data = m_axi_acp_rdata;

	assign m_axi_acp_rready = mm2s_ready && rdata_ch_active;
	assign mm2s_valid = m_axi_acp_rvalid && rdata_ch_active;



	////////////////////////////////////
	//Write address channel
	////////////////////////////////////
	
	//Set write address
	always @(posedge m_axi_acp_aclk) begin
		if(write_active)
			m_axi_acp_awaddr <= write_address;
		else if(m_axi_acp_awvalid && m_axi_acp_awready)
			m_axi_acp_awaddr <= m_axi_acp_awaddr + 32'h400;
	
	end

	//Valid signal control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			m_axi_acp_awvalid <= 0;
		end
		else if(m_axi_acp_awvalid && m_axi_acp_awready) begin
			m_axi_acp_awvalid <= 0;
		end
		else begin
			m_axi_acp_awvalid <= ~wdata_ch_active && ((wdata_count[3:0] == 0) || write_active) && ~write_idle;
		end
		
	end

	//Write data channel activate control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			wdata_ch_active <= 0;
		end
		else begin
			if(m_axi_acp_awvalid && m_axi_acp_awready) begin
				wdata_ch_active <= 1;
			end
			else if(m_axi_acp_wvalid && m_axi_acp_wready) begin
				wdata_ch_active <= (wdata_count[3:0] == 4'b1111) ? 0 : 1;
			end
		end
		
	end

	//Idle signal control
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			write_idle <= 1;
		end
		else begin
			if(wdata_count[DATA_SIZE_LOG-1:4] == BURST_NUM)
				write_idle <= (wdata_count[DATA_SIZE_LOG-1:4] == BURST_NUM) ? 1 : 0;
			else if(write_active)
				write_idle <= 0;
			
		end
	end

	//wlast signal
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			m_axi_acp_wlast <= 0;
		end
		else begin
			if(m_axi_acp_wvalid && m_axi_acp_wready)
				m_axi_acp_wlast <= (wdata_count[3:0] == 14) ? 1 : 0;
		end
	end

	//Data counter
	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			wdata_count <= 0;
		end
		else begin
			if(m_axi_acp_wready && m_axi_acp_wvalid)
				wdata_count <= wdata_count + 1;
		end
	end


	////////////////////////////////////
	//Write data channel
	////////////////////////////////////

	assign m_axi_acp_wdata = s2mm_data;

	assign m_axi_acp_wvalid = s2mm_valid && wdata_ch_active;
	assign s2mm_ready = m_axi_acp_wready && wdata_ch_active;


	////////////////////////////////////
	//Write response channel
	////////////////////////////////////

	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			m_axi_acp_bready <= 0;
		end
		else begin
			m_axi_acp_bready <= m_axi_acp_wready && m_axi_acp_wvalid && m_axi_acp_wlast;
		end
	end

	always @(posedge m_axi_acp_aclk) begin
		if(~axi_resetn) begin
			bresp <= 0;
		end
		else begin
			if(m_axi_acp_wready && m_axi_acp_wvalid)
				bresp <= m_axi_acp_bresp;
		end
	end


endmodule