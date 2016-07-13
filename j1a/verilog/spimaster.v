module spimaster (
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
assign running = sdelay[15];

reg [15:0] dataout;
wire MOSI_ = dataout[15];

reg SCL_;
wire MISO_;
wire ince = ~SCL_;

SB_IO #(.PIN_TYPE(6'b0000_00)) _miso (
    .PACKAGE_PIN(MISO),
    .CLOCK_ENABLE(ince),
    .INPUT_CLK(clk),
    .D_IN_0(MISO_));

reg [15:0] datain;
assign rx = datain;

always @(posedge clk)
begin
    if (running) begin
        sdelay <= SCL_ ? sdelay : {sdelay[14:0], 1'b0};
        dataout <= SCL_ ? dataout : {dataout[14:0],1'b0};
        datain <= SCL_ ? {datain[14:0], MISO_} : datain;
        SCL_ <= ~SCL_;
    end else begin
        SCL_ <= 1'b1;
        datain <= datain;
        if (we) begin
            sdelay <= both ? 16'hffff :  16'hff00 ;
            dataout <= both ? tx :  {tx[7:0],8'b0};
        end else begin
            sdelay <= sdelay;
            dataout <= dataout;
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
