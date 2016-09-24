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

reg [32:0] sdelay;
assign running = sdelay[31];
wire capturing;
assign capturing = sdelay[32];

reg [15:0] dataout;
wire MOSI_ = dataout[15];

reg SCL_;
wire MISO_;
wire ince = SCL_;

SB_IO #(.PIN_TYPE(6'b0000_00)) _miso (
    .PACKAGE_PIN(MISO),
    .CLOCK_ENABLE(ince),
    .INPUT_CLK(clk),
    .D_IN_0(MISO_));

reg [15:0] datain;
assign rx = {datain[7:0],datain[15:8]};

reg SCLd;

always @(posedge clk) begin
    if (capturing) begin
        datain <= (~SCL_) ? {datain[14:0], MISO_} : datain;
        SCL_ <= ~SCL_;
    end else begin
        SCL_ <= 1'b0;
        datain <= datain;
    end
    SCLd <= SCL_;
end

always @(posedge clk) begin
    if (running) begin
        sdelay <= {sdelay[31:0], 1'b0};
        dataout <= (SCLd) ? {dataout[15:0],1'b0} : dataout ;
    end else begin
        if (we) begin
            sdelay <= both ? 33'h1ffffffff :  33'h1ffff0000 ;
            dataout <= both ? {tx[7:0],tx[15:8]} :  {tx[7:0],8'b0};
        end else begin
            sdelay <=  (capturing) ? {sdelay[31:0], 1'b0} : sdelay ;
            dataout <= dataout;
        end
    end
end

wire SCL__;
assign SCL__ = SCL_ & running;

SB_IO #(.PIN_TYPE(6'b0101_01)) _scl (
    .PACKAGE_PIN(SCL),
    .OUTPUT_CLK(clk),
    .D_OUT_0(SCL__));

SB_IO #(.PIN_TYPE(6'b0101_01)) _mosi (
    .PACKAGE_PIN(MOSI),
    .OUTPUT_CLK(clk),
    .D_OUT_0(MOSI_));



endmodule
