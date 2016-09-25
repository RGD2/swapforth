module spimaster_le (
    input wire clk,
    input wire we,
    input wire both,
    input wire [15:0] tx,
    output wire [15:0] rx,
    output wire running,
    output wire MOSI,
    output wire SCL,
    input wire MISO);

reg [15:0] sdelay;
wire go = sdelay[15];
reg capturing;
always@(posedge clk) capturing <= go; 
assign running = capturing | go;

reg [15:0] dataout;
wire MOSI_ = dataout[15];

reg SCL_;
reg slower;
wire sample = SCL_& slower;
wire MISO_;

SB_IO #(.PIN_TYPE(6'b0000_00)) _miso (
    .PACKAGE_PIN(MISO),
    .CLOCK_ENABLE(1'b1),
    .INPUT_CLK(clk),
    .D_IN_0(MISO_));

reg [15:0] datain;
always @(posedge clk) begin
	if (running) begin
        	datain <= (sample) ? {datain[14:0], MISO_} : datain;
	end else begin
       		datain <= datain;
	end
end

assign rx = {datain[7:0],datain[15:8]};

always @(posedge clk) begin
    if (go) begin
        sdelay <= (sample) ? {sdelay[14:0], 1'b0} : sdelay;
        dataout <= (sample) ? {dataout[14:0],1'b0} : dataout;
        SCL_ <= (slower) ? ~SCL_ : SCL_ ;
        slower <= ~slower;
    end else begin
        SCL_ <= 1'b0;
        slower <= 1'b0;
        if (we) begin
            sdelay <= both ? 16'hFFFF : 16'hFF00;
            dataout <= both ? {tx[7:0],tx[15:8]} :  {tx[7:0],8'h00};
        end
    end
end


SB_IO #(.PIN_TYPE(6'b0101_01)) _scl (
    .PACKAGE_PIN(SCL),
    .OUTPUT_CLK(clk),
    .D_OUT_0(SCL_));

SB_IO #(.PIN_TYPE(6'b0101_01)) _mosi (
    .PACKAGE_PIN(MOSI),
    .OUTPUT_CLK(clk),
    .D_OUT_0(MOSI_));

endmodule
