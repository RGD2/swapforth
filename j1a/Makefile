build/ram.v: build/nuc.hex mkrom.py
	python mkrom.py

build/nuc.hex: cross.fs basewords.fs nuc.fs
	gforth cross.fs basewords.fs nuc.fs

bootstrap: build/nuc.hex mkrom.py verilator/bootstrap
	make -C verilator
	(cd ./verilator/; sudo ./bootstrap)
	python mkrom.py

clean:
	rm -f build/nuc.hex
	make -C icestorm clean
	make -C verilator clean

sim_connect:
	make -C verilator sim_connect

j4a_sim_connect:
	make -C verilator j4a_sim_connect

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)

/dev/ttyUSB1: linmodload

connect: /dev/ttyUSB1
	sudo python shell.py -h /dev/ttyUSB1 -p ../common/


j4a:
	make -C icestorm j4a

j1a8k:
	make -C icestorm j1a8k

j1a:
	make -C icestorm j1a

linmodload:
	$(info Ensure ice40hx8k breakout board or iceStick is plugged in.)
	sudo modprobe ftdi_sio

endif

ifeq ($(UNAME_S),Darwin)

/dev/tty.usbserial-*B: mackextload

connect: /dev/tty.usbserial-*B
	sudo python shell.py -h /dev/tty.usbserial-*B -p ../common/

j4a: mackextunload
	make -C icestorm j4a

j1a8k: mackextunload
	make -C icestorm j1a8k

j1a: mackextunload
	make -C icestorm j1a

mackextunload:
	echo "Unloading com.apple.driver.AppleUSBFTDI for iceprog"
	sudo kextunload -bundle-id com.apple.driver.AppleUSBFTDI

mackextload:
	echo "Loading com.apple.driver.AppleUSBFTDI for shell.py"
	sudo kextload -bundle-id com.apple.driver.AppleUSBFTDI

endif

.PHONY: connect sim_connect j4a_sim_connect clean bootstrap mackextload mackextunload macconnect linmodload
