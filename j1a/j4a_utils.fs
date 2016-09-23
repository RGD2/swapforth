
\ Driver words for j4a's core management
\ j4a is a quad-barrel processor
\ you should #include j4a_utils.fs
\ Cores 1 2 and 3 have pigeonholes attached via the IO subsystem.
\ These pigeonholes are all *read* from $4000, by code already in swapforth.
\ but which one is read depends on which core is doing the reading.
\ Core zero has no pigeonhole - it always gets 0. Manage it as you would a j1a,
\ (ie, save a startup word in init, etc.) or just leave it idle for you to talk to.
\ Memory (and actually the ALU too) is shared, but each 'core' gets it's own private stacks.
\ Each core runs at the same speed regardless of what the others are doing, 1/4 as fast as a j1a would run.

: on1 ( xt -- ) $100 io! ; \ make core 1 run an XT. eg: ' someword on1
: on2 ( xt -- ) $200 io! ;
: on3 ( xt -- ) $400 io! ;
: once ( standard/looping xt -- runonce xt ) 1+ ; \ eg: ' someword once on2 
: kill1 0 on1 2 $4000 io! ; \ interrupt and reset core 1
: kill2 0 on2 4 $4000 io! ;
: kill3 0 on3 8 $4000 io! ;
: stopall 0 on1 0 on2 0 on3 ; \ tell the cores to do nothing next
: killall kill1 kill2 kill3 ; \ stop and reset all cores.
: coreId ( -- coreId ) $8000 io@ ; \ this IO register looks different to each core.


: delay750ns* ( n -- ) dup if begin 1- dup 0= until then drop ; \ threadsafe delay, no use of do..loop
: ms dup if begin 1- dup 0= 1332 delay750ns* until then drop ;
\ overwrites j1a's ms definition so ms works as expected.
\ note that do .. loop isn't threadsafe, because rO (the loop index offset) is a global.

: reboot 4 $0800 io! ; \ forces cold reboot (including FPGA reconfiguration)

\ threadsafe IO port manipulation next: pm also works with leds to control specific leds.
: pm ( io-mask-preset -- ) $8000 io! ; \ call before next io! or io@, to touch only selected bits of leds or pmod in a threadsafe way
\ resets to all set after next io operation by same core. 
\ only masks io! to the leds or pmod (16 bit bidirectional io port), and it's direction register.
\ also works to mask bits of any io@ read
: pout ( pmoddata -- ) 1 io! ;
: pdir ( pmod-drive-pins-mask -- ) 2 io! ; \ sets which bits are driven (outputs)
: pin ( -- pmoddata ) 1 io@ ; 
: pmo ( mask pmoddata -- ) swap pm pout ;
: pmd ( mask pmoddir -- ) swap pm pdir ;

: done? 1 pm $80 io@ 0<> ;
: B>SPI $40 io! ; \ goes at 20 Mbits/s, no need to poll for one byte with the 10MHz j4a.
: >SPI $c0 io! begin done? until ; \ but you could miss a word if you don't poll for a word-write.
: >SPI> >SPI $40 io@ 2* ; \ note, last bit is lost, but this doesn't matter for our purposes.

: B>SPI2 $10 io! ;
: >SPI2 $30 io! begin 1 pm $20 io@ 0<> until ;
: >SPI2> >SPI2 $10 io@ 2* ; \ still loses last bit.
