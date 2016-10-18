module spislaverx (
    input wire clk,
    output reg [15:0] rx,
    input wire CS,
    input wire SCL,
    input wire MOSI);


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
reg [17:0] datain; //18 bits for capturing longer CS packets.
reg write, dCS_;
always @(posedge SCL_) begin
	write <= 1'b0;
	dCS_ <= CS_;
	if (CS_) datain <= {datain[16:0], MOSI_} ;
	if (dCS_) begin
		if (bitcount == 4'hf) begin
			write <= 1'b1;
			dcap <= (CS_) ? datain[17:2] : datain[16:1]; // supports contiguous writes.
		end 
		bitcount <= bitcount + 4'h1;
	end else begin
		bitcount <= 4'h0;
	end
end
//fixme: read http://www.sunburst-design.com/papers/CummingsSNUG2002SJ_FIFO1.pdf
// should have such a CDC fifo between clock domains just to keep data from glitching, and it
// may as well allow for burst-written data too.
// data channel burst length will be a power of two 16 bit words, and the fifo ought to self-freshen on full. (ie, lap itself, reverting to an empty state when actually overfull -> want to get the latest data, and only get old data if only within one buffer lap, not have to read a whole buffer of stale data first.For this application, it's important that the data be not too old.
// this dual port dual clk ram is 256x16.
// SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) _ram ( .RDATA(), .RADDR(), .WADDR(), .MASK(), .WDATA(datain), .RCLKE(), .RCLK(), .RE(), .WCLKE(1'b1), .WCLK(SCL_), .WE(write));
reg [1:0] syncw;
reg gotd;
reg [15:0] sync, syncd;
always @(posedge clk) begin
	{syncd, sync} <= {sync, dcap}; // standard double-registered frozen data CDC
	{gotd,syncw} <= {syncw,write}; // note, three clk delay - to give data time to settle.
	if (gotd) rx <= syncd; // so rx is always certainly valid.
end
endmodule
