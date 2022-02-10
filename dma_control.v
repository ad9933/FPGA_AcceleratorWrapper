module axi_dma_impl_ex (
    //Global Signals
	input m_axi_aclk,
	input s_axi_lite_aclk,
	
	//Reset
	input axi_resetnn,

    //DMA control signals
    output read_active,
    output [31:0] read_address,
    input read_idle,

    output write_active,
    output [31:0] write_address,
    input write_idle,

    input rw_resp,

    ////////////////////////////////////
	//AXI Lite
	////////////////////////////////////
	//S_AXI_LITE Write Address (AW) Channel
	input s_axi_lite_awaddr,
	output s_axi_lite_awready,
	input s_axi_lite_awvalid,
	
	//S_AXI_LITE Write Channel
	input [31:0] s_axi_lite_wdata,
	output s_axi_lite_wready,
	input s_axi_lite_wvalid,
	
	//S_AXI_LITE Write Response Channel
	input s_axi_lite_bready,
	output [1:0] s_axi_lite_bresp,
	output s_axi_lite_bvalid,
	
	//S_AXI_LITE Read Address (AR) Channel
	input s_axi_lite_araddr,
	output s_axi_lite_arready,
	input s_axi_lite_arvalid,
	
	//S_AXI_LITE Read Channel
	output [31:0] s_axi_lite_rdata,
	input s_axi_lite_rready,
	output s_axi_lite_rvalid
	
);
	//0 -> Target address
    //1 -> Command[31:16] / Status[15:0]
    //Command(Write only) - R/W [31], assert [30]
    //Status(Read only) - Read busy [15], write busy[14] 
    localparam READ = 1'b0;
    localparam WRITE = 1'b1;


	reg [31:0] data_reg [1:0];

	
	reg write_addr_buffer;
	reg has_write_addr;
	reg write_successful;

    reg read_addr_buffer;
	reg has_read_addr;
	
	//Get Write Address
	assign s_axi_lite_awready = ~has_write_addr;
	always @(posedge s_axi_lite_aclk) begin
		//reset
		if(~axi_resetnn) begin
			has_write_addr <= 0;
		end
		
		else begin
		//Transaction Happened
			if(s_axi_lite_awready & s_axi_lite_awvalid) begin
				has_write_addr <= 1;
				write_addr_buffer <= s_axi_lite_awaddr;
			end
		//Write Happened
			else if (s_axi_lite_wready & s_axi_lite_wvalid) begin
				has_write_addr <= 0;
			end
		end
	end
	
	//Get Data to Write
	assign s_axi_lite_wready = has_write_addr;
	always @(posedge s_axi_lite_aclk) begin
		if(s_axi_lite_wready & s_axi_lite_wvalid) begin
            if(write_addr_buffer)
			    data_reg[write_addr_buffer] <= s_axi_lite_wdata;
            else
                data_reg[write_addr_buffer][31:16] <= s_axi_lite_wdata[31:16];
		end
	end
	
	//Send Write response
	assign s_axi_lite_bvalid = write_successful;
	assign s_axi_lite_bresp = 2'b00;
	always @(posedge s_axi_lite_aclk) begin
		if(~axi_resetnn) begin
			write_successful <= 0;
		end
		else begin
		//write and write response happens simultaneously
			if (s_axi_lite_wready & s_axi_lite_wvalid & s_axi_lite_bvalid & s_axi_lite_bready) begin
				write_successful <= 1;
			end
			else if(s_axi_lite_wready & s_axi_lite_wvalid) begin
				write_successful <= 1;
			end
			else if(s_axi_lite_bvalid & s_axi_lite_bready) begin
				write_successful <= 0;
			end
		end
		
	end



    ////////////////////////////////////    
	//AXI Lite - Read
	////////////////////////////////////

    //Get Read Address
	assign s_axi_lite_arready = ~has_read_addr;
	always @(posedge s_axi_lite_aclk) begin
		//reset
		if(~axi_resetnn) begin
			has_read_addr <= 0;
		end
		
		else begin
		//Transaction Happened
			if(s_axi_lite_arready & s_axi_lite_arvalid) begin
				has_read_addr <= 1;
				read_addr_buffer <= s_axi_lite_araddr;
			end
		//Read Happened
			else if (s_axi_lite_rready & s_axi_lite_rvalid) begin
				has_write_addr <= 0;
			end
		end
	end
	
	//Get Data to Read
	assign s_axi_lite_rvalid = has_read_addr;
	always @(posedge s_axi_lite_aclk) begin
		if(s_axi_lite_wready & s_axi_lite_wvalid) begin
            if(write_addr_buffer)
			    data_reg[write_addr_buffer] <= s_axi_lite_wdata;
            else
                data_reg[write_addr_buffer][31:16] <= s_axi_lite_wdata[31:16];
		end
	end
	
	//Send Write response
	assign s_axi_lite_bvalid = write_successful;
	assign s_axi_lite_bresp = 2'b00;
	always @(posedge s_axi_lite_aclk) begin
		if(~axi_resetnn) begin
			write_successful <= 0;
		end
		else begin
		//write and write response happens simultaneously
			if (s_axi_lite_wready & s_axi_lite_wvalid & s_axi_lite_bvalid & s_axi_lite_bready) begin
				write_successful <= 1;
			end
			else if(s_axi_lite_wready & s_axi_lite_wvalid) begin
				write_successful <= 1;
			end
			else if(s_axi_lite_bvalid & s_axi_lite_bready) begin
				write_successful <= 0;
			end
		end
		
	end


endmodule