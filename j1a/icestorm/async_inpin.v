module lpbitfilter (
    input wire clk,
    input wire in,
    output reg out);

    parameter FILTERBITS = 5;
    // This is somewhat of a digital moving average glitch filter, with a symmetrical digital Schmidt trigger output.
    // this one takes 24 ticks to set rd on. (in general 3/4 of 2^FILTERBITS ticks)
    // saturates after 31 sequential highs.
    // Then will take 24 sequential lows to turn off.
    // Saturating back on zero after the 31st.
    // change the above to change the timing.
    reg [FILTERBITS-1:0] fltr;
    //  (increase fltr size for slower signals,
    // decrease for faster. should be no less than three bits.)
    wire notallon = ~&fltr;
    wire notalloff = |fltr;
    wire incr = notallon & in;
    wire decr = notalloff & ~in;

    wire mostlyon = &{fltr[FILTERBITS-1],fltr[FILTERBITS-2]};
    wire mostlyoff = ~|{fltr[FILTERBITS-1],fltr[FILTERBITS-2]};
    //wire [1:0] tops = fltr[FILTERBITS-1:FILTERBITS-2]; // top two bits are used to decide whether to change output state.
    //wire setr = &tops;
    //wire clrr = ~|tops;

    always @(posedge clk)
    begin
        case({incr,decr})
            2'b10: fltr <= fltr + 1;
            2'b01: fltr <= fltr - 1;
            default: fltr <= fltr;
        endcase
        case({mostlyon,mostlyoff})
            2'b10: out <= 1'b1;
            2'b01: out <= 1'b0;
            default: out <= out;
        endcase
    end
endmodule

module acdetectfilter (
    input wire clk,
    input wire in,
    output reg out);

    // simply expiry filter - output goes low 2^FILTERBITS clk ticks after
    // input goes low. No need to preserve edge symmetry.
    // pick a time equal to excitation period, and the output won't oscillate
    // with the excitation signal.
    
    parameter FILTERBITS = 12;
    reg [FILTERBITS-1:0] fltr;

    wire any = |fltr;
    wire decr = any & ~in;

    always @(posedge clk)
    begin
        case({in,decr})
            2'b1?: fltr <= -1;
            2'b01: fltr <= fltr - 1;
            default: fltr <= fltr;
        endcase
        out <= any | in;
    end
endmodule

module async_inpin (
    input wire clk,
    input wire pin,
    output reg rd);

    wire onereg;
    parameter PULLUP = 1'b0;
    SB_IO #(.PIN_TYPE(6'b0000_00), .PULLUP(PULLUP)) inpin (
            .PACKAGE_PIN(pin),
            .CLOCK_ENABLE(1'b1),
            .INPUT_CLK(clk),
            .D_IN_0(onereg));
    reg tworeg; always @(posedge clk) {rd,tworeg} <= {tworeg,onereg};
    // triple registering helps prevent metastability when synchronising an undefined signal into a clock domain.
endmodule


module async_in_filter (
    input wire clk,
    input wire pin,
    output reg rd);
    // This module is intended to accept up to a maximum 750 kHz async signal,
    // and synchronise it safely to a 48 MHz clock. 
    // It will add at least 27 clks of latency, and may not respond reliably to a 1MHz signal.
    wire threereg;
    parameter PULLUP = 1'b0;
    async_inpin #(.PULLUP(PULLUP)) _ain (.clk(clk), .pin(pin), .rd(threereg));
    parameter FILTERBITS = 5;
    lpbitfilter #(.FILTERBITS(FILTERBITS)) _filter (.clk(clk), .in(threereg), .out(rd));
endmodule

module async_in_filter_pullup_inverted(input clk, input pin, output rd);
    wire a;
    wire threereg;
    async_inpin #(.PULLUP(1'b1)) _ain (.clk(clk), .pin(pin), .rd(threereg));
    parameter FILTERBITS = 13; // assuming we're using a excitation source at clk*2^-11 rate
    acdetectfilter #(.FILTERBITS(FILTERBITS)) _filt (.clk(clk), .in(~threereg), .out(rd)); // note the inversion!
endmodule
 
