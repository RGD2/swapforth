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
  input [pbits-1:0] dir);

  parameter pbits = 16;
  genvar i;
  generate
    for (i = 0; i < pbits; i = i + 1) begin : io
      // 1001   PIN_OUTPUT_REGISTERED_ENABLE
      //     01 PIN_INPUT
      SB_IO #(.PIN_TYPE(6'b1001_01)) _io (
        .PACKAGE_PIN(pins[i]),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(wd[i]),
        .D_IN_0(rd[i]),
        .OUTPUT_ENABLE(dir[i]));
    end
  endgenerate

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
		   inout [7:0] PB,

           input MISO,
           output MOSI,
           output SCL,

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
               .dir(pmod_dir));


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

  // ######   GPIO near SPI   ##########################################

reg [7:0] extra_dir;   // 1:output, 0:input
wire [7:0] extra_in;

ioport #(.pbits(8)) _extraio (.clk(clk),
               .pins(PB),
               .we(io_wr_ & io_addr_[4]),
               .wd(dout_[7:0]),
               .rd(extra_in),
               .dir(extra_dir));

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
               .dir(16'hffff));

  wire [2:0] PIOS;
  wire w8 = io_wr_ & io_addr_[3];

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

  /*        bit   mode    device
      0001  0     r/w     PMOD GPIO
      0002  1     r/w     PMOD direction
      0004  2     r/w     LEDS
      0008  3     r/w     misc.out
	  0010  4     r/w     extra GPIO (byte only)
	  0020  5     r/w     extra GPIO direction
      0040  6     w       SPI 8 bit write (low byte only)
      00c0  6+7   w       SPI 16 bit write. Handle CS pins yourself - use GPIO
	  0040  6     r       SPI word read (after a word write)
	  0080  7     r       SPI ready (poll with `begin $80 io@ until ` to wait for completion)

      0100  8     r/w*    slot 1 task XT
      0200  9     r/w*    slot 2 task XT
      0400  10    r/w*    slot 3 task XT
      - If bit 0 in an XT is set with ` 1 or `, then the task will auto-clear to zero after being read and run once.
      - All slots are reset at once on a CTRL-C from the shell, which also clears all tasks.


      0800  11      w     sb_warmboot
      1000  12    r/w     UART RX, UART TX
      2000  13    r       misc.in

      4000  14    r/w    slot task fetch, handled by tasksel in nuc.fs. Write here to selectively reset one or more slots, controlled by setting the low nibble.

      8000  15    r       slot ID (depends only on which slot accesses it) - used by tasksel in nuc.fs. Can be used in parallel tasks to differentiate slots.

      This IO should only be used right after boot, and swapforth must be modified so that only slot ID 0, which is slot 0, will continue to execute main and ultimately quit, which should be modified to initialise and run itself and others via execution tokens stored in a set of eight variables which should be included in swapforth. The inital slot 0 task should start the three initial tasks, then waiting for just long enough for all to have started, before setting the main tasks and exiting to the programmer's serial interface. It is not necessary to wait until a task has completed before assigning a new task, only to wait for the initially assigned task to begin.

      The practical upshot of all this is that the j1a will initially behave to the programmer like a (one quarter speed until pipelining optimisation is added - then possibly exactly as fast) j1a. When the programmer is happy with the operation of a task, (s)he manually writes the execution token for the compiled init and runtime words into the exec slots for concurrent task testing.

      During concurrent testing/debug, task0 may continue to be used as if a j1a, except that memory changes made by running task will be visible. The timing of operation running this way for development from compiled code will be the same regardless of what other tasks are running, unless the operation depends upon some handshaking between tasks. In this way timing critical code can be developed and left running for the remainder of development and modification/debug without ever changing it's timing and operation, yet enabling the programmer to continue to modify the running system.

      When happy with the entire system including one to three concurrently running tasks, (s)he manually writes the init and exec tokens into those six variables, then tests reboot start up with a CTRL-C, which always reboots all slots. If all is well, (s)he does a `#flash build/nuc.hex`, exits, and rebuilds the system with `make -C icestorm j4a.bin`. When the rebuilt system is booted, it will run as per it's operation after the CTRL-C, but will still be able to be connected to and developed further or debugged, or left standalone for embedded application.

      It may be worth changing this to reserve slot 0 entirely for the developer, whilst allowing say slot 3 to start and kill the other two.
      So of those two time critical things could be done in one, and less-time-critical multitasking in the other. It would even be possible then to have the managing task implement a soft-realtime OS with or without preemption on the one slot, whilst handling the io hardware by running a hard-real time scheduler on the other.
  */

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
    (io_addr_[ 0] ? {pmod_in}                                                 : 16'd0)|
    (io_addr_[ 1] ? {pmod_dir}                                                : 16'd0)|
    (io_addr_[ 2] ? {LEDS}                                                    : 16'd0)|
    (io_addr_[ 3] ? {13'd0, PIOS}                                             : 16'd0)|
	(io_addr_[ 4] ? {extra_in}                                                 : 16'd0)|
    (io_addr_[ 5] ? {extra_dir}                                                : 16'd0)|
    (io_addr_[ 6] ? {spirx}                                                   : 16'd0)|
    (io_addr_[ 7] ? {15'd0, ~spirunning}                                      : 16'd0)|
    (io_addr_[ 8] ? taskexecn[15:0]                                           : 16'd0)|
    (io_addr_[ 9] ? taskexecn[31:16]                                          : 16'd0)|
    (io_addr_[10] ? taskexecn[47:32]                                          : 16'd0)|
    (io_addr_[12] ? {8'd0, uart0_data}                                        : 16'd0)|
    (io_addr_[13] ? {11'd0, random, 1'b0, PIOS_01, uart0_valid, !uart0_busy}  : 16'd0)|
    (io_addr_[14] ? {taskexec}                                                : 16'd0)|
    (io_addr_[15] ? {14'd0, io_slot_}                                         : 16'd0);
// so init code can stop all but one slot, or alternatively, restart their task by reading taskexec then executing it, or else going into a reboot poll loop until given something to do.


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
    else case ({io_rd_ , io_addr_[14], io_slot_}) // if the assigned XT has bit 0 set ( 1 or ) then it will be cleared after being read once.
        4'b1101:  taskexecn[15:0] <= taskexecn[0] ? 16'b0 : taskexecn[15:0];
        4'b1110:  taskexecn[31:16] <= taskexecn[16] ? 16'b0 : taskexecn[31:16];
        4'b1111:  taskexecn[47:32] <= taskexecn[32] ? 16'b0 : taskexecn[47:32];
    endcase

    if (io_wr_ & io_addr_[1])
      pmod_dir <= dout_;

	if (io_wr_ & io_addr_[5])
	  extra_dir <= dout_[7:0];

    if (io_wr_ & io_addr_[11])
      {boot, s1, s0} <= dout_[2:0];

  end

  always @(negedge resetq or posedge clk)
    if (!resetq)
      unlocked <= 0; // ram write clock enable
    else
      unlocked <= unlocked | io_wr_;

endmodule // top
