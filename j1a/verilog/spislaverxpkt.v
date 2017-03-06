module spislaverxpkt (
    input wire clk,
    output reg [15:0] pktwrd,
    input wire setaddr,
    input wire [5:0] paddr,
    input wire CS,
    input wire SCL,
    input wire MOSI);

// receive a auto-refreshed packet of up to 64, 16 bit words, and cross clock domains with quadruple buffering.
// triple would have been good enough, but we'll use one Embedded Block Ram (in 256x16 mode), and double might not have been okay
// this is intended to run with 'quietSPI' LVDS receivers, ~15 cm twisted pair wiring on wirewrapped 0.1" headers between FPGA boards, at 100 MHz.

// it will currently interface to the 'one hot' j1a/j4a IO interface, so will have to include an additional writable IO register for read address.
// packet address (except for page bits) will reset when CS line relaxes, and whole page (written or not) will 'flip'.

// This is not intended to be a CDC FIFO - just a 'packet memory' which the SPI slave interface keeps refreshed asynchronously to the j1a/j4a clock.
// Page flips happen with each new packet reception, replacing the 'current' read packet when the slow side clock comes.
// paddr simply chooses the word within the 64-word 'packet' space, whether all or none have been written or not, and stays set to whatever it was last 
// set to between reads. It must be preset with a write before each read, but will function as for the old 'spislaverx' one-register design if never set.

// So, it is fairly likely to be lossy, in the sense that many packets will be ignored, as there is no planned way to access it other than via polling.
// any non-lossy DSP ought to be done on the other FPGA anyway, as that one is responsible for data capture, signals processing and storage, and so is 
// fully given over to fixed-function pipeline hardware.

// this module ultimately ought to be integrated in some way with a memory-interception design, with auto-defined 'static' target addresses recognised by 
// pre-scannning the forth system image's dictionary for the appropriate named variables in some manner.
// the same ought to be true of the planned 'spislavepktio' subsystem, which ought to similarly use another 

// it should eventually also include a 'packet serial counter' appended to the packet so it would be possible to determine whether fresh data had arrived.
// or maybe as a separate 'autoclear on read' 'freshpacket' bit which could be wired into one of the other misc i registers.

wire CS_;
SB_IO #(.PIN_TYPE(6'b0000_00)) sb_io_cs ( 
    .PACKAGE_PIN(CS),
    .CLOCK_ENABLE(1'b1),
    .INPUT_CLK(SCL_),
    .D_IN_0(CS_));
wire SCL_;
SB_GB_IO #(.PIN_TYPE(6'b000000))  sb_io_scl (
    .PACKAGE_PIN(SCL),
    .GLOBAL_BUFFER_OUTPUT(SCL_));
wire MOSI_;
SB_IO #(.PIN_TYPE(6'b0000_00)) sb_io_mosi (
    .PACKAGE_PIN(MOSI),
    .CLOCK_ENABLE(1'b1),
    .INPUT_CLK(SCL_),
    .D_IN_0(MOSI_));

reg [3:0] bitcount;
reg [15:0] dcap;
reg [15:0] datain;
reg write, dCS_;
reg [1:0] wpage;
reg [1:0] rpage;
reg [5:0] wctr;
reg [7:0] waddr;
reg [5:0] rpaddr;
wire [7:0] raddr = {rpage-1,rpaddr}; // raddr will update to always one less than the write page.

//SB_RAM256x16 spislavequadbuffer ( // yosys doesn't know about this one.
SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) spislavequadbuffer (
.RDATA(pktwrd),
.RADDR(raddr),
.WADDR(waddr),
.MASK(16'b0),
.WDATA(dcap),
.RCLKE(1'b1),
.RCLK(clk),
.RE(1'b1),
.WCLKE(1'b1),
.WCLK(SCL_),
.WE(write)
);

always @(posedge SCL_) begin
	write <= 1'b0;
	if (CS_) begin
		datain <= {datain[14:0], MOSI_} ;
		bitcount <= bitcount + 4'h1;
	end else begin
		bitcount <= 4'h0;
		wctr <= 6'b0;
	end
	if (dCS_) begin
		if (bitcount == 4'h0) begin
			write <= 1'b1;
			waddr <= {wpage,wctr}; // note, write happens one cycle after 'write' strobes, so we must buffer the address and data ourselves.
			dcap <= datain;
			wctr <= wctr + 1;
		end 
		if(!CS_) begin
			wpage <= wpage + 1; // at end of packet
		end
	end
	dCS_ <= CS_;
end
// SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) _ram ( .RDATA(), .RADDR(), .WADDR(), .MASK(), .WDATA(datain), .RCLKE(), .RCLK(), .RE(), .WCLKE(1'b1), .WCLK(SCL_), .WE(write));
reg [3:0] syncpaddr;
always @(posedge clk) begin
	if(setaddr) rpaddr<=paddr; // FIXME: make safe for 4 cores - should be quadruplicated and 'rolled' like other 'thread' state.
	// so more than one core can safely read from different parts of the packet, if they want.
	// at the moment, only one thread should read from this packet
	// ideally, this whole IO device ought to be wound into a 'memory intercepter' system so declared variables magically refresh, and magically transmit, all without involving the j4a core at all. 
	// and that ought to work also for getting variable content out without interfering with the j4a's timing, for UI indication purposes.
	{rpage,syncpaddr}<={syncpaddr,wpage}; // rpage registered thrice over in clk domain.
end
endmodule
