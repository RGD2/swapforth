`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

module SB_RAM2048x2(
	output [1:0] RDATA,
	input        RCLK, RCLKE, RE,
	input  [10:0] RADDR,
	input         WCLK, WCLKE, WE,
	input  [10:0] WADDR,
	input  [1:0] MASK, WDATA
);
	parameter INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;

  wire [15:0] rd;

  SB_RAM40_4K #(
    .WRITE_MODE(3),
    .READ_MODE(3),
    .INIT_0(INIT_0),
    .INIT_1(INIT_1),
    .INIT_2(INIT_2),
    .INIT_3(INIT_3),
    .INIT_4(INIT_4),
    .INIT_5(INIT_5),
    .INIT_6(INIT_6),
    .INIT_7(INIT_7),
    .INIT_8(INIT_8),
    .INIT_9(INIT_9),
    .INIT_A(INIT_A),
    .INIT_B(INIT_B),
    .INIT_C(INIT_C),
    .INIT_D(INIT_D),
    .INIT_E(INIT_E),
    .INIT_F(INIT_F)
  ) _ram (
    .RDATA(rd),
    .RADDR(RADDR),
    .RCLK(RCLK), .RCLKE(RCLKE), .RE(RE),
    .WCLK(WCLK), .WCLKE(WCLKE), .WE(WE),
    .WADDR(WADDR),
    .MASK(16'h0000), .WDATA({4'b0, WDATA[1], 7'b0, WDATA[0], 3'b0}));

  assign RDATA[0] = rd[3];
  assign RDATA[1] = rd[11];

endmodule

module ioport(
  input clk,
  inout [pbits-1:0] pins,
  input we,
  input [pbits-1:0] wd,
  output [pbits-1:0] rd,
  input [pbits-1:0] dir,
	input [pbits-1:0] mask);

  parameter pbits = 16;
  wire [pbits-1:0] din;
 genvar i;
 wire [pbits-1:0] dout;
  generate
    for (i = 0; i < pbits; i = i + 1) begin : io
	  // 1001	PIN_OUTPUT_REGISTERED_ENABLE
      //     01 PIN_INPUT
      SB_IO #(.PIN_TYPE(6'b1001_01)) _io (
        .PACKAGE_PIN(pins[i]),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(dout[i]),
        .D_IN_0(din[i]),
        .OUTPUT_ENABLE(dir[i]));
	assign dout[i] = (mask[i])? wd[i] : din[i];
    end
  endgenerate
	assign rd = din;
endmodule

module outpin(
  input clk,
  output pin,
  input we,
  input wd,
  output rd);

  SB_IO #(.PIN_TYPE(6'b0101_01)) _io (
        .PACKAGE_PIN(pin),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(wd),
        .D_IN_0(rd));
endmodule

module inpin(
  input clk,
  input pin,
  output rd);

  SB_IO #(.PIN_TYPE(6'b0000_00)) _io (
        .PACKAGE_PIN(pin),
        .INPUT_CLK(clk),
        .D_IN_0(rd));
endmodule

module top(input pclk,

           output [7:0] D,		// LED's

           output TXD,        // UART TX
           input RXD,         // UART RX

           output fSCK,    // flash SCK
           input fMISO,     // flash MISO
           output fMOSI,    // flash MOSI
           output fCS,    // flash CS

           inout [15:0] PA,

	   input MISO,
           output MOSI,
           output SCL,

	   input MISO2,
           output MOSI2,
           output SCL2,
	   input sCS,
	   input sSCL,
	   input sMOSI,
	   output [2:0] spower,

	   input hf,
	   input mf,
	   input lf,
	   output ef,

           input reset
);
  localparam MHZ = 12;

/*
  wire clk, pll_lock;

  wire pll_reset;
  assign pll_reset = !reset;
  wire resetq;  // note port changed, .pcf needs update too.
  assign resetq = reset & !pll_lock;

  SB_PLL40_CORE #(.FEEDBACK_PATH("PHASE_AND_DELAY"),
                  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
                  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
                  .PLLOUT_SELECT("SHIFTREG_0deg"),
                  .SHIFTREG_DIV_MODE(1'b0),
                  .FDA_FEEDBACK(4'b0000),
                  .FDA_RELATIVE(4'b0000),
                  .DIVR(4'b1111),
                  .DIVF(7'b0110001),
                  .DIVQ(3'b011), //  1..6
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(pclk),
                         //.PLLOUTCORE(clk),
                         .PLLOUTGLOBAL(clk),
                         .LOCK(pll_lock),
                         .RESETB(pll_reset),
                         .BYPASS(1'b0)
                        ); // 37.5 MHz, fout = [ fin * (DIVF+1) ] / [ DIVR+1 ], fout must be 16 ..275MHz, fVCO from 533..1066 MHz (!! we're 600 here I think), and phase detector / input clock from 10 .. 133 MH (ok, we're 75 because DIVQ divides by 2^DIVQ, but doesn't affect output otherwise, and input is 12 MHz)
                        // for some reason this crashes arachne-pnr now.

  */
  wire clk;
  wire uresetq,resetq;
 // assign resetq = reset; // now passed through PLL to keep design in reset until lock. note active low resets.

  SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'b0000),
                  .DIVF(7'd3),
                  .DIVQ(3'b000),
                  .FILTER_RANGE(3'b001)
                 ) uut (
                         .REFERENCECLK(pclk),
                         .PLLOUTCORE(clk),
                         //.PLLOUTGLOBAL(clk),
                         .LOCK(uresetq),
                         .RESETB(reset),
                         .BYPASS(1'b0)
                        );

  reg [1:0] syncreset; always @(posedge clk) {resetq, syncreset} <= {syncreset,uresetq};

  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  wire [12:0] code_addr;

  reg unlocked = 0;// ###### RAM WRITE LOCK


  wire [1:0] io_slot;
  wire [15:0] return_top;
  wire [3:0] kill_slot_rq;

`include "../build/ram.v"

  // always @(negedge resetq or posedge clk)  unlocked <= resetq ? unlocked | io_wr_ : 0;
  always @(posedge clk)  unlocked <= resetq & (unlocked | io_wr_);

  j4 _j4(
    .clk(clk),
    .resetq(resetq),
    .io_rd(io_rd),
    .io_wr(io_wr),
    .mem_wr(mem_wr),
    .dout(dout),
    .io_din(io_din),
    .mem_addr(mem_addr),
    .code_addr(code_addr),
    .insn(insn),
    .io_slot(io_slot),
    .return_top(return_top),
    .kill_slot_rq(kill_slot_rq));


  // ######   TICKS   #########################################

  reg [15:0] ticks;
  always @(posedge clk)
    ticks <= ticks + 16'd1;

  // ######   IO SIGNALS   ####################################

  // note that io_din has to be delayed one instruction, but it depends upon io_addr_, which is, so it does.
  // it doesn't hurt to run dout_ delayed too.
  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  reg [15:0] io_addr_;
  reg [1:0] io_slot_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    io_slot_ <= io_slot;
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
    else
      io_addr_ <= 0; // because we don't want to actuate things unless there really is a read or write.
  end

  // ######   GPIO (PMOD) ##########################################

  reg [15:0] pmod_dir;   // 1:output, 0:input
  wire [15:0] pmod_in;

  ioport _mod (.clk(clk),
               .pins(PA),
               .we(io_wr_ & io_addr_[0]),
               .wd(dout_),
               .rd(pmod_in),
               .dir(pmod_dir),
		.mask(iomask));


  wire [15:0] masked_pmod_dir;
  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin
      assign masked_pmod_dir[i] = (iomask[i])? dout_[i] : pmod_dir[i];
    end
  endgenerate

  always @(posedge clk) if (io_wr_ & io_addr_[1]) pmod_dir <= masked_pmod_dir;
  // This allows the direction pins to be set with an iomask'd write - very handy when sharing the port between multiple threads.

  // ######   SPI ACCELERATORS   ##########################################

wire [15:0] spirx;
wire spirunning;
spimaster _spi (	.clk(clk),
   				.we(io_wr_ & io_addr_[6]),
				.both(io_addr_[7]),
				.tx(dout_),
				.rx(spirx),
				.running(spirunning),
				.MOSI(MOSI),
				.SCL(SCL),
				.MISO(MISO));

wire [15:0] spirx2;
wire spirunning2;
spimaster_le _spi2 (	.clk(clk),
   				.we(io_wr_ & io_addr_[4]),
				.both(io_addr_[5]),
				.tx(dout_),
				.rx(spirx2),
				.running(spirunning2),
				.MOSI(MOSI2),
				.SCL(SCL2),
				.MISO(MISO2));

wire [15:0] spislaverxd;
spislaverxpkt _spi3 ( .clk(clk), .pktwrd(spislaverxd), .setaddr(io_wr_ & io_addr_[3]), .paddr(dout_[5:0]), .CS(sCS), .SCL(sSCL), .MOSI(sMOSI));

outpin spowerpin0(.clk(clk), .we(1'b1), .pin(spower[0]), .wd(1'b1), .rd());
outpin spowerpin1(.clk(clk), .we(1'b1), .pin(spower[1]), .wd(1'b1), .rd());
outpin spowerpin2(.clk(clk), .we(1'b1), .pin(spower[2]), .wd(1'b1), .rd());
// nasty hack for ice40hx8k breakout board: Not enough nearby Vio pins!
// these are actually just powering nearby LVDS RX chips, so just need to be always on.

  // ######  HW MULTIPLIER    ################################
/* currently disabled - experimental, and takes quite a bit of resources.
wire [31:0] muld;
wire mulready;
wire [1:0] absel = {2{io_wr_}} & io_addr_[5:4];
mult16x16 _mul (.clk(clk),
                .resetq(resetq),
			    .we(absel),
			    .din(dout_),
			    .dout(muld),
			    .ready(mulready));
*/ // this multiplier could probably keep up with the main j1a core - but needs to read and write two stack items in a cpu cycle (both 16 bit operands giving a 32 bit result).
// it would be more useful integrated into the actual j4a core, with retimed pipelining inserted.

  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  wire uart_RXD;
  async_in_filter  _rcxd(.clk(clk), .pin(RXD), .rd(uart_RXD));
  buart _uart0 (
     .clk(clk),
     .resetq(1'b1),
     .rx(uart_RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  wire [7:0] LEDS;


   // ######   LEDS   ##########################################

  ioport #(.pbits(8)) _leds (.clk(clk),
               .pins(D),
               .we(io_wr_ & io_addr_[2]),
               .wd(dout_),
               .rd(LEDS),
               .dir(8'hff),
	       .mask(iomask[7:0]));

  wire [2:0] PIOS;
  wire writeflags = io_wr_ & io_addr_[13];

  outpin pio2(.clk(clk), .we(writeflags), .pin(fSCK), .wd(dout_[14]), .rd(PIOS[2]));
  outpin pio1(.clk(clk), .we(writeflags), .pin(fMOSI), .wd(dout_[13]), .rd(PIOS[1]));
  outpin pio0(.clk(clk), .we(writeflags), .pin(fCS), .wd(dout_[12]), .rd(PIOS[0]));
 
// ###### J4a coherent I/O Mask preset mechanism
  reg [15:0] iomask_preset[3:0];
  always@(posedge clk) if(io_wr_ | io_rd_) iomask_preset[io_slot_] <= (io_addr_[15] & io_wr_) ? dout_ : 16'hFFFF;
  wire [15:0] iomask;
  assign iomask = iomask_preset[io_slot_];

// ###### J4a task assignment system.
// necessary to allow more than one actual thread to be run.
  reg [47:0] taskexecn;

  always@( posedge clk) begin
    if (!resetq)
      taskexecn <= 48'b0; // this is so CTRL-C will stop all slots - otherwise they'll just restart themselves after a warm reset.
    else if (io_wr_ ) begin // any slot can change any other's schedule, except none can mess with slot 0
      if (io_addr_[8]) taskexecn[15:0] <= dout_;
      if (io_addr_[9]) taskexecn[31:16] <= dout_;
      if (io_addr_[10]) taskexecn[47:32] <= dout_;
      kill_slot_rq <= io_addr_[14] ? dout_[3:0] : 4'b0;
    end  // it is even possible to assign the same task to multiple slots, although this isn't recommended.
    else
	case ({io_rd_ , io_addr_[14], io_slot_}) // if the assigned XT has bit 0 set ( 1 or ) then it will be cleared after being read once.
	   4'b1101:  taskexecn[15:0] <= taskexecn[0] ? 16'b0 : taskexecn[15:0];
	   4'b1110:  taskexecn[31:16] <= taskexecn[16] ? 16'b0 : taskexecn[31:16];
	   4'b1111:  taskexecn[47:32] <= taskexecn[32] ? 16'b0 : taskexecn[47:32];
        endcase // we use the task xt lsb to determine whether to run only once.
  end
 
  reg [15:0] taskexec;
  always @* begin
    case (io_slot_)
      2'b00: taskexec = 16'b0;// 0 is safe -- will cause all non-zero ID cores to spinlock asking for a nonzero task
      2'b01: taskexec = {taskexecn[15:1], 1'b0}; // note *valid* XT's must be even, we use the bit above.
      2'b10: taskexec = {taskexecn[31:17], 1'b0};
      2'b11: taskexec = {taskexecn[47:33], 1'b0};
    endcase
  end

  // ###### SAMPLE RAM : 256x16 bit data storage with independant autoincrementing pointers ####

  reg [7:0] sreadaddr, sreadaddr_;
  reg [7:0] swriteaddr, swriteaddr_;
  wire [7:0] sampleAddr = dout_[7:0]; // used to preset (or clear) the pointers.
  wire setWriteAddr = writeflags & dout_[11]; // $800 $2000 io!
  wire setReadAddr = writeflags & dout_[10]; // $400 $2000 io!
  // reset both at once with $c00 $2000 io!
  // note, bits 15:12 and 9  of dout are used by other things on $2000 io!
  // specifically, $8000 $2000 io! will reboot the FPGA!
  wire haveRead = io_rd_ & io_addr_[11];
  wire haveWrite = io_wr_ & io_addr_[11];
  wire [15:0] readsample;
  // reg [15:0] writesample;
  always@(posedge clk) begin
    sreadaddr <= setReadAddr ? sampleAddr : (haveRead ? sreadaddr+1 : sreadaddr);
    swriteaddr <= setWriteAddr ? sampleAddr : (haveWrite ? swriteaddr+1 : swriteaddr);
   // writesample <= haveWrite ? dout_ : writesample;
    {swriteaddr_, sreadaddr_} <= {swriteaddr,sreadaddr}; // otherwise it's the incremented addresses
    // that get used. 
  end
  // actual read/write will occur a clk later - have to buffer both read and write data!
  // see the lattice technology docs for the EBR timing info.
  SB_RAM40_4K #(.READ_MODE(0),.WRITE_MODE(0)) sampleram (
.RDATA(readsample),
.RADDR(sreadaddr_),
.WADDR(swriteaddr_),
.MASK(16'b0),
.WDATA(dout_),
.RCLKE(1'b1),
.RCLK(clk),
.RE(1'b1),
.WCLKE(1'b1),
.WCLK(clk),
.WE(haveWrite) // needs to be a clk earlier than the actual data+address. 
);

// ######   3-level AC fluid sensor with excitation source #######

reg enableexcitation; always @(posedge clk) enableexcitation <= (writeflags & |dout_[8:9]) ? dout_[8] : enableexcitation ;
reg [10:0] ec = 0; always @(posedge clk) ec <= enableexcitation ? ec + 1 : 0;
assign ef = ec[10]; // 48MHz / 2^11; 23.4375 kHz maximum.
wire fluidfull, fluidhigh, fluidlow;
async_in_filter_pullup_inverted #(.FILTERBITS(11)) apin1(.clk(clk),.pin(hf),.rd(fluidfull));
async_in_filter_pullup_inverted #(.FILTERBITS(11)) apin2(.clk(clk),.pin(mf),.rd(fluidhigh));
async_in_filter_pullup_inverted #(.FILTERBITS(11)) apin3(.clk(clk),.pin(lf),.rd(fluidlow));
// .FILTERBITS(11) here means each input will register as 'off' a full exitation clk period after the pin does
// This timeout gets reset when the input goes high, so when the excitation signal makes it to an input pin,
// the input pin just registers as 'on' continually, rather than oscillating, which might have caused it to appear
// 'off' half the time.


    // ######   IO SUBSYSTEM ADDRESSING DOCUMENTATION  ######################################

/* io_addr_[ ]
      bit   mode    device
0001  0     r/w     PMOD GPIO
0002  1     r/w     PMOD direction
0004  2     r/w     LEDS - also good for use as semaphores with the iomask to coherently set/flip individual bits.
                \ only the top three can be written to with iomask
                 \ everything under here will ignore the iomask when writing.
                   \ SPI slave pkt rx: runs at 100 MHz, receives up to 64x16bit word packets, quadbuffered.
0008  3       w     third SPI slave set word address in packet (to read from next, 0 to 63)
0008  3     r       third SPI slave read from preset packet, word address, autoincrements address
                   \ 'second' SPI Master accelerator: Use GPIO to control your client chips' nCS lines.
0010  4     r/w     second SPI byte write/word read. Write to send data, then read when ready to receive the result.
0030  4&5     w     second SPI 16 bit write: Little Endian byte order auto byteswapped for your convenience.
0020  5     r       second SPI ready poll, same as below

0040  6       w     SPI 8 bit write (low byte only)
00c0  6&7     w     SPI 16 bit write. Handle CS pins yourself - use GPIO
0040  6     r       SPI word read (after a word write). Big Endian byte order.
0080  7     r       SPI ready (poll with `begin $80 io@ until ` to wait for completion)

0100  8     r/w     slot 1 task XT
0200  9     r/w     slot 2 task XT
0400  10    r/w     slot 3 task XT
                    - If bit 0 in an XT is set with ` 1 or `, then the task will auto-clear to zero after being read and run once.
                   \ Sample RAM. Uses a 256x16 BRAM. Pointers can both be cleared with %11000 $2000 io@
0800  11    r       - read data from sample RAM. Autoincrements read addr pointer.
0800  11      w     - write data to sample RAM, Autoincements write addr pointer.
                    - was sb_warmboot, has since been moved to 13.
1000  12    r/w     UART RX, UART TX
2000  13    r       misc.in and misc.out inherited from j1a, also sundry status bits.
                    - msb is the 'not core0' slotID. moved from $8000 io@ because only tasksel in nuc.fs was using it.
                       - used by tasksel in nuc.fs, so 'exit' runs on core0 only
              w     - also connected to warmboot module and sample ram address pointer resets.
                    - { Boot,  fSCK, fMOSI, fCS,  SetWriteAddr, SetReadAddr, disableexcitation,  enableexcitation, sampleAddr[7:0] }
4000  14    r/w     slot task fetch, handled by tasksel in nuc.fs. 
                    - Write here to selectively reset one or more slots, controlled by setting the low nibble.

8000  15    r       wall clock (counts clock ticks, wraps)
8000  15      w     Mask set
                    - very next io@ or io! by *the same* core will use this as a mask
                    - After that next access, will reset to all true 
                    - Cleared bits in mask on next io read from anything will read as zero
                    - Only set bits in mask on a write to ioport or ioport direction will be *changed*
                    - This makes it easy to only set or read particular bits in a port from multiple thread.
*/

// ###### ALL IO READ ADDRESS DECODING ######
   wire [15:0] statusbits = { (|io_slot_), fluidfull, fluidhigh, fluidlow, 6'd0, PIOS[2:0], fMISO, uart0_valid, !uart0_busy};
   assign io_din =
   ((io_addr_[ 0] ? {pmod_in}             : 16'd0)|
    (io_addr_[ 1] ? {pmod_dir}            : 16'd0)|
    (io_addr_[ 2] ? {8'd0,LEDS}           : 16'd0)|
    (io_addr_[ 3] ? {spislaverxd}         : 16'd0)|
    (io_addr_[ 4] ? {spirx2}              : 16'd0)|
    (io_addr_[ 5] ? {15'd0, ~spirunning2} : 16'd0)|
    (io_addr_[ 6] ? {spirx}               : 16'd0)|
    (io_addr_[ 7] ? {15'd0,  ~spirunning} : 16'd0)|
    (io_addr_[ 8] ? taskexecn[15:0]       : 16'd0)|
    (io_addr_[ 9] ? taskexecn[31:16]      : 16'd0)|
    (io_addr_[10] ? taskexecn[47:32]      : 16'd0)|
    (io_addr_[11] ? readsample            : 16'd0)|
    (io_addr_[12] ? {8'd0, uart0_data}    : 16'd0)|
    (io_addr_[13] ? statusbits            : 16'd0)|
    (io_addr_[14] ? {taskexec}            : 16'd0)|
    (io_addr_[15] ? ticks                 : 16'd0))&iomask;

// ###### WARMBOOT MODULE
  reg boot, s0, s1;
  always@(posedge clk) if (writeflags) {boot, s1, s0} <= {dout_[15], dout_[1:0]};
  SB_WARMBOOT _sb_warmboot (
    .BOOT(boot),
    .S0(s0),
    .S1(s1)
    );
endmodule // top
