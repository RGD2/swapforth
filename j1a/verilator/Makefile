SUBDIRS=..

all: obj_dir/Vj1a ../build/nuc.hex build/lib/python/vsimj1a.so

VERILOGS=j1a.v ../verilog/j1.v ../verilog/stack2.v

obj_dir/Vj1a obj_dir/Vj1a__ALL.a: $(VERILOGS) sim_main.cpp Makefile
	verilator -Wall --cc -DVERILATOR=1 $(VERILOGS) --top-module j1a --exe sim_main.cpp
	$(MAKE) -C obj_dir CXXFLAGS="-fPIC" OPT_FAST="-O2" -f Vj1a.mk Vj1a

../build/nuc.hex:
	$(MAKE) -C ..

build/lib/python/vsimj1a.so: setup.py obj_dir/Vj1a__ALL.a vsim.cpp
	python setup.py install --home build

sim_connect: build/lib/python/vsimj1a.so ../build/nuc.hex
	python shell.py -p ../ -p ../../common

clean:
	rm -rf build
	rm -rf obj_dir
	rm -f newmem.dat

.PHONY: all

j4a: obj_dir/Vj4a ../build/nuc.hex build/lib/python/vsimj4a.so

VERILOGS4=j4a.v ../verilog/*.v

obj_dir/Vj4a obj_dir/Vj4a__ALL.a: $(VERILOGS4) sim_main4.cpp Makefile
	verilator -Wall -Wno-fatal --cc -DVERILATOR=1 $(VERILOGS4) --top-module j4a --exe sim_main4.cpp
	$(MAKE) -C obj_dir CXXFLAGS="-fPIC" OPT_FAST="-O2" -f Vj4a.mk Vj4a

build/lib/python/vsimj4a.so: setup4.py obj_dir/Vj4a__ALL.a vsim4.cpp
	python setup4.py install --home build

j4a_sim_connect: j4a
	python simshell4.py -p ../ -p ../../common

.PHONY: j4a
.PHONY: j4a_sim_connect
