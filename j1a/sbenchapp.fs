\ This file does a clean full build,
\ assumes you started with (starting out in a shell in this repository)
\   cd ../swapforth/j1a
\   sudo make clean sim_connect
\ and then ran (in the emulated j1a)
\   #include ../../j4a-code/sbenchapp.fs
\   #bye
\ and then (back in bash)
\   make
\   sudo make j4a connect
\ The hardware will have the full application image written to it's eeprom.

\ if working on the FPGA code, you can do
\   sudo make clean j4a_sim_connect
\   #include swapforth.fs
\   ... do tests here. Note that j4a_sim_connect will run much more slowly than sim_connect,
\ as the full j4a (including the hardware multiplier) will be emulated.

\ if just working live on the app, for a much more rapid turnout, instead do:
\   cd ../swapforth/j1a
\   sudo make clean bootstrap j4a connect
\ This will set up the chip with a 'clean' swapforth, and connect you to it
\ and then
\   #include ../../j4a-code/j4a-maxrefdes24.fs
\   ini
\ ... interact with system here ...

\ ... and merely repeat ...
\   4 $800 io!
\ (which will reload the FPGA with the clean image, also disconnecting you )
\   make connect
\   #include ../../j4a-code/j4a-maxrefdes24.fs
\   ini
\ ... to evaluate changes to j4a-maxrefdes24.fs, and test the hardware.
\ this way is quicker, and doesn't wear the eeprom out as the hardware is only written the once.

#include swapforth.fs
#include ../../j4a-code/j4a-maxrefdes24.fs
:noname ini quit ; init !


 \ init is a variable containing the word to execute first on boot. This could contain code to load a never-ending app. This noname word in that case would be required to be something like:
\ :noname ['] quit init ! ini neverendingapp ; \ ini and neverendingapp run once on the first boot after FPGA autoconfig (ie, after every cold boot).
\ init ! \ this runs now, putting the above unnamed word into init. Note that the code replaces init again when it runs, so quit is run instead: This allows the UI core to be used to run an app, whilst still allowing a
\  programmer-link driven reset to be able to connect to quit (which actually runs the CLI) after the *warm* reboot. The code that runs in this file is just presetting the memory image prior to baking it into the FPGA initial config. Dumping it into swapforth/j1a/build/nuc.hex so a subsequent 'make' call will regenerate the verilog containing the initial ram image.
\ After this, run 'make; time sudo make j4a; make connect' 
\ This will build the preloaded image, write it into FPGA board eeprom, and connect to it.
\ Afterwards, only 'make connect' will be necessary to talk to the system.
#flash ../build/nuc.hex
