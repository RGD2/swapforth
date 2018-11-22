VERILOGS = j1a.v uart.v ../verilog/j1.v ../verilog/stack2.v

VERILOGS8k = j1a8k.v uart.v ../verilog/j1.v ../verilog/stack2.v

VERILOGS8k4 = j4a.v uart.v ../verilog/*.v


SUBDIRS = ..

all: $(SUBDIRS) j1a.bin

j1a.bin: $(VERILOGS) j1a.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j1a.blif" $(VERILOGS)
	arachne-pnr -p j1a.pcf j1a.blif -o j1a.asc
	#skipped:# icebox_explain j1a.asc > j1a.ex
	icepack j1a.asc j1a0.bin
	icemulti -p0 j1a0.bin > j1a.bin && rm j1a0.bin

j1a8k.bin: $(VERILOGS8k) j1a8k.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j1a8k.blif" $(VERILOGS8k)
	arachne-pnr -d 8k -P ct256 -p j1a8k.pcf j1a8k.blif -o j1a8k.asc
	#skipped:# icebox_explain j1a8k.asc > j1a8k.ex
	icepack j1a8k.asc j1a8k0.bin
	icemulti -p0 j1a8k0.bin > j1a8k.bin && rm j1a8k0.bin

j4a.bin: $(VERILOGS8k4) j4a.pcf Makefile ../build/ram.v
	yosys  -q -p "synth_ice40 -top top -abc2 -blif j4a.blif -json j4a.json" $(VERILOGS8k4)
	#arachne-pnr -r -m 500 -d 8k -P ct256 -p j4a.pcf j4a.blif -o j4a.asc
	nextpnr-ice40 --hx8k --package ct256 --pcf j4a.pcf --json j4a.json --asc j4a.asc	
	#skipped:# icebox_explain j4a.asc > j4a.ex
	icepack j4a.asc j4a0.bin
	icemulti -p0 j4a0.bin > j4a.bin && rm j4a0.bin

j1a8k: j1a8k.bin
	sudo iceprog j1a8k.bin

j1a: j1a.bin
	sudo iceprog j1a.bin

j4a: j4a.bin
	sudo iceprog j4a.bin

j1a_timing: j1a.bin
	icetime -tmd hx1k j1a.asc

j4a_timing: j4a.bin
	icetime -tmd hx8k j4a.asc


$(SUBDIRS):
	$(MAKE) -C $@

clean:
	rm -f j1a.blif j1a.asc j1a.bin
	rm -f j1a8k.blif j1a8k.asc j1a8k.bin
	rm -f j1a.blif j4a.asc j4a.bin

.PHONY: subdirs
.PHONY: subdirs $(SUBDIRS)
.PHONY: clean
.PHONY: j1a8k
.PHONY: j1a
.PHONY: j4a
.PHONY: j1a_timing
.PHONY: j4a_timing
