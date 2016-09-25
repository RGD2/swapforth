module SB_IO (
	inout wire PACKAGE_PIN,
	input wire CLOCK_ENABLE,
	input wire INPUT_CLK,
	input wire OUTPUT_CLK,
	input wire OUTPUT_ENABLE,
	input wire D_OUT_0,
	input wire D_OUT_1,
	output wire D_IN_0,
	output wire D_IN_1);

parameter PIN_TYPE=6'b0000_00;

// Note, this is a not a complete SB_IO implementation, just enough for simulation of modules using PIN_TYPE 010101 and 000000.
// in particular, doesn't implement LATCH_INPUT_VALUE or repsect PIN_TYPE[1].
reg oe,dout,ndout,din,ndin;
wire inclk, outclk;
assign inclk = INPUT_CLK & CLOCK_ENABLE;
assign outclk = OUTPUT_CLK & CLOCK_ENABLE;

always@(posedge inclk)
	din <= PACKAGE_PIN;

always@(negedge inclk)
	ndin <= PACKAGE_PIN;

assign D_IN_1 = ndin;
assign D_IN_0 = (PIN_TYPE[0]) ? din : ndin ;

always@(posedge outclk) begin
	dout <= D_OUT_0;
	oe <= OUTPUT_ENABLE;
end

always@(negedge outclk) begin
	ndout <= D_OUT_1;
end

reg outen; // note, this isn't a FF, just something set in the always block.
always @(PIN_TYPE[5:4] or OUTPUT_ENABLE or oe)  begin
	casex (PIN_TYPE[5:4])
		2'b00	:	outen = 1'b0;
		2'b01	:	outen = 1'b1;
		2'b10	:	outen = OUTPUT_ENABLE;
		2'b11	:	outen = oe;
		2'bXX	:	outen = 1'b0;
	endcase
end

wire a,b,out;
assign a = (PIN_TYPE[2]) ? ~dout : D_OUT_0;
assign b = (~(PIN_TYPE[2]|outclk)) ? ndout : dout;
assign out = (PIN_TYPE[3]) ? a : b;

assign PACKAGE_PIN = (outen) ? out : 1'bz;

endmodule

  
