module mult16x16 (
    input wire clk,
    input wire resetq,
    input wire [1:0] we,
    input wire [15:0] din,
    output reg [31:0] dout,
    output reg ready);

    reg signed [15:0] A;
    reg signed [15:0] B;

    reg running;
    wire done;

    reg [1:0] loaded;
    wire start = &loaded;
    wire [31:0] dout_;

    always @ (posedge clk) begin
        {A, loaded[0]} <= (we[0]==1'b1) ? {din, 1'b1} : {A, (loaded[0] & !start)} ;
        {B, loaded[1]} <= (we[1]==1'b1) ? {din, 1'b1} : {B, (loaded[1] & !start)} ;
        running <= start ? 1'b1 : running & !done;
        dout <= (done) ? dout_ : dout;
        ready <= !running;
    end

    // 16x16 piplined mulitplier from LGPL pid_controller opencores.org, curtesy Zhu Xu m99a1@yahoo.cn
    multiplier_16x16bit_pipelined _multi(
        .i_clk(clk),
        .i_rst(resetq),
        .i_start(start),
        .i_md(A),
        .i_mr(B),
        .o_product(dout_),
        .o_ready(done));

endmodule
