module spimaster (
    input wire clk,
    input wire we,
    input wire both,
    input wire [15:0] tx,
    output reg [15:0] rx,
    output wire running,
    output  MOSI,
    output  SCL,
    input  MISO);

reg [15:0] sdelay;
assign running = sdelay[15];

reg [15:0] dataout;
wire MOSI_ = dataout[15];

reg SCL_;
wire MISO_;

always @(posedge clk)
begin
    if (running) begin
        sdelay <= SCL_ ? sdelay : {sdelay[14:0], 1'b0};
        dataout <= SCL_ ? dataout : {dataout[14:0],1'b0};
        rx <= SCL_ ? {rx[14:0], MISO_} : rx;
        SCL_ <= ~SCL_;
    end else begin
        SCL_ <= 1'b1;
        rx <= rx;
        if (we) begin
            sdelay <= both ? 16'hffff :  16'hff00 ;
            dataout <= both ? tx :  {tx[7:0],8'b0};
        end else begin
            sdelay <= sdelay;
            dataout <= dataout;
        end
    end
end

  SB_IO #(.PIN_TYPE(6'b0101_01), .PULLUP(1'b1)) _scl (
        .PACKAGE_PIN(SCL),
        .CLOCK_ENABLE(),
        .OUTPUT_CLK(clk),
        .D_OUT_0(SCL_),
        .OUTPUT_ENABLE(1'b1));

  SB_IO #(.PIN_TYPE(6'b0101_01)) _mosi (
        .PACKAGE_PIN(MOSI),
        .CLOCK_ENABLE(),
        .OUTPUT_CLK(clk),
        .D_OUT_0(MOSI_),
        .OUTPUT_ENABLE(1'b1));

  SB_IO #(.PIN_TYPE(6'b0000_00)) _miso (
        .PACKAGE_PIN(MISO),
        .INPUT_CLK(clk),
        .D_IN_0(MISO_));

endmodule
