test_stack2pipe4.v: stack2pipe4_tb.v ../verilog/stack2pipe4.v
	iverilog -o top ../verilog/stack2pipe4.v stack2pipe4_tb.v && vvp top && rm top

spi_le.vcd: a.out
	./a.out && rm a.out

a.out:	spimaster_le_tb.v SB_IO.v ../verilog/spimaster_le.v
	iverilog spimaster_le_tb.v

spi_le.stems: spimaster_le_tb.v SB_IO.v ../verilog/spimaster_le.v
	vermin spimaster_le_tb.v -emitstems >spi_le.stems

gtkwave: spi_le.vcd spi_le.stems
	gtkwave -o -t spi_le.stems spi_le.vcd spi_le.sav

.PHONY: gtkwave test_stack2pipe4.v



