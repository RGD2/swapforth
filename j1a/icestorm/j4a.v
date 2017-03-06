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

           output [15:0] D,		// LED's

           output TXD,        // UART TX
           input RXD,         // UART RX

           output PIOS_00,    // flash SCK
           input PIOS_01,     // flash MISO
           output PIOS_02,    // flash MOSI
           output PIOS_03,    // flash CS

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
  wire resetq;
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
                         .LOCK(resetq),
                         .RESETB(reset),
                         .BYPASS(1'b0)
                        );


  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  wire [12:0] code_addr;
  reg unlocked = 0;

  wire [1:0] io_slot;
  wire [15:0] return_top;
  wire [3:0] kill_slot_rq;

`include "../build/ram.v"


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



  /*


  // ######   TICKS   #########################################

  reg [15:0] ticks;
  always @(posedge clk)
    ticks <= ticks + 16'd1;
  */

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

  // ######   PMOD   ##########################################

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
  // This allows the direction pins to be set with an iomask'd write - very handy when sharing the port between multiple threads.

  // ######   SPI   ##########################################

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
/* disabled beacuse second SPI peripheral was needed instead.
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

  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  wire uart_RXD;
  inpin _rcxd(.clk(clk), .pin(RXD), .rd(uart_RXD));
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

  wire [15:0] LEDS;


   // ######   LEDS   ##########################################



  ioport _leds (.clk(clk),
               .pins(D),
               .we(io_wr_ & io_addr_[2]),
               .wd(dout_),
               .rd(LEDS),
               .dir(16'hffff),
	       .mask(iomask));

  wire [2:0] PIOS;
  wire w8 = io_wr_ & io_addr_[13];

  outpin pio0(.clk(clk), .we(w8), .pin(PIOS_03), .wd(dout_[0]), .rd(PIOS[0]));
  outpin pio1(.clk(clk), .we(w8), .pin(PIOS_02), .wd(dout_[1]), .rd(PIOS[1]));
  outpin pio2(.clk(clk), .we(w8), .pin(PIOS_00), .wd(dout_[2]), .rd(PIOS[2]));

  // ######   RING OSCILLATOR   ###############################

  // wire [1:0] buffers_in, buffers_out;
  // assign buffers_in = {buffers_out[0:0], ~buffers_out[1]};
  // SB_LUT4 #(
  //         .LUT_INIT(16'd2)
  // ) buffers [1:0] (
  //         .O(buffers_out),
  //         .I0(buffers_in),
  //         .I1(1'b0),
  //         .I2(1'b0),
  //         .I3(1'b0)
  // );
  // wire random = ~buffers_out[1];
  wire random = 1'b0; // random disabled: async loops play poorly with icetime

  // ######   IO PORTS   ######################################

/* io_addr_[ ]
      bit   mode    device
0001  0     r/w     PMOD GPIO
0002  1     r/w     PMOD direction
0004  2     r/w     LEDS
0008  3       w     third SPI slave set packet address (to read from next)
0008  3     r       third SPI slave read from preset packet address
0010  4     r/w     second SPI byte write/word read (was multiplier)
0030  4&5     w     second SPI 16 bit write: this one is little endian, the other big endian.
0020  5     r       second SPI ready poll, same as below

0040  6       w     SPI 8 bit write (low byte only)
00c0  6&7     w     SPI 16 bit write. Handle CS pins yourself - use GPIO
0040  6     r       SPI word read (after a word write)
0080  7     r       SPI ready (poll with `begin $80 io@ until ` to wait for completion)

0100  8     r/w     slot 1 task XT
0200  9     r/w     slot 2 task XT
0400  10    r/w     slot 3 task XT
                    - If bit 0 in an XT is set with ` 1 or `, then the task will auto-clear to zero after being read and run once.

0800  11      w     sb_warmboot
1000  12    r/w     UART RX, UART TX
2000  13    r/w     misc.in and misc.out

4000  14    r/w     slot task fetch, handled by tasksel in nuc.fs. 
                    - Write here to selectively reset one or more slots, controlled by setting the low nibble.

8000  15    r       slot ID (depends only on which slot accesses it) - used by tasksel in nuc.fs. Can be used in parallel tasks to differentiate slots
8000  15      w     Mask set
                    - very next io@ or io! by *the same* core will use this as a mask
                    - After that next access, will reset to all true 
                    - Cleared bits in mask on next io read from anything will read as zero
                    - Only set bits in mask on a write to ioport or ioport direction will be *changed*
                    - This makes it easy to only set or read particular bits in a port from multiple thread.
*/

  reg [15:0] iomask_preset[3:0];
  wire [15:0] iomask;
  assign iomask = iomask_preset[io_slot_];

  always@(posedge clk) begin
	if(io_wr_ | io_rd_)
		iomask_preset[io_slot_] <= (io_addr_[15] & io_wr_) ? dout_ : 16'hFFFF;
  end

  reg [15:0] taskexec;
  reg [47:0] taskexecn;

  always @* begin
    case (io_slot_)
      2'b00: taskexec = 16'b0;// all tasks start with taskexec zeroed, and all tasks will try to run all code from zero.
      2'b01: taskexec = {taskexecn[15:1], 1'b0}; // note *valid* XT's must be even, we set that bit to make tasks run once only.
      2'b10: taskexec = {taskexecn[31:17], 1'b0};
      2'b11: taskexec = {taskexecn[47:33], 1'b0};
    endcase
  end


  assign io_din =
   ((io_addr_[ 0] ? {pmod_in}                                                 : 16'd0)|
    (io_addr_[ 1] ? {pmod_dir}                                                : 16'd0)|
    (io_addr_[ 2] ? {LEDS}                                                    : 16'd0)|
    (io_addr_[ 3] ? {spislaverxd}                                             : 16'd0)|
    (io_addr_[ 4] ? {spirx2}                                                  : 16'd0)|
    (io_addr_[ 5] ? {15'd0, ~spirunning2}                                     : 16'd0)|
    (io_addr_[ 6] ? {spirx}                                                   : 16'd0)|
    (io_addr_[ 7] ? {15'd0,  ~spirunning}                                     : 16'd0)|
    (io_addr_[ 8] ? taskexecn[15:0]                                           : 16'd0)|
    (io_addr_[ 9] ? taskexecn[31:16]                                          : 16'd0)|
    (io_addr_[10] ? taskexecn[47:32]                                          : 16'd0)|
    (io_addr_[12] ? {8'd0, uart0_data}                                        : 16'd0)|
    (io_addr_[13] ? {10'd0, PIOS, PIOS_01, uart0_valid, !uart0_busy}          : 16'd0)|
    (io_addr_[14] ? {taskexec}                                                : 16'd0)|
    (io_addr_[15] ? {14'd0, io_slot_}                                         : 16'd0))&iomask;

  reg boot, s0, s1;

  SB_WARMBOOT _sb_warmboot (
    .BOOT(boot),
    .S0(s0),
    .S1(s1)
    );


  always@( posedge clk) begin

    if (!resetq)
      taskexecn <= 0; // this is so CTRL-C will stop all slots - otherwise they'll just restart themselves after a warm reset.
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
    endcase

    if (io_wr_ & io_addr_[1])
      pmod_dir <= masked_pmod_dir;

    if (io_wr_ & io_addr_[11])
      {boot, s1, s0} <= dout_[2:0];

  end

  always @(negedge resetq or posedge clk)
    if (!resetq)
      unlocked <= 0; // ram write clock enable
    else
      unlocked <= unlocked | io_wr_;

endmodule // top
