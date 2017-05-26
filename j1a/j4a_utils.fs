
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

: x1! ( xt -- ) $100 io! ; \ make core 1 run an XT. eg: ' someword x1!
: x2! ( xt -- ) $200 io! ;
: x3! ( xt -- ) $400 io! ;
: xn. io@ .xt ;
: x1. $100 xn. ; \ prints back what word is assigned to core 1
: x2. $200 xn. ;
: x3. $400 xn. ;
\ : once ( standard/loop@g xt -- runonce xt ) 1+ ; \ eg: ' someword once x2! 
: x1k 0 x1! 2 $4000 io! ; \ interrupt and reset core 1
: x2k 0 x2! 4 $4000 io! ;
: x3k 0 x3! 8 $4000 io! ;
: xas 0 x1! 0 x2! 0 x3! ; \ tell the cores to do nothing next
: xak x1k x2k x3k ; \ stop and reset all cores.


: us ( n -- ) dup if begin 1- dup 0= until then drop ; \ threadsafe delay for j4a, 
\ actually about .75us/count with the 48MHz clk, plus overhead
: ms dup if begin 1- dup 0= 1332 us until then drop ;
\ overwrites j1a's ms definition so ms works as expected, ie, 1 ms per count.
\ note that do .. loop isn't threadsafe, because rO (the loop index offset) is a global.
: s! $2000 io! ;
: s@ $2000 io@ ; \ reads status flags
: reboot $8000 s! ; \ forces cold reboot (including FPGA reconfiguration)
\ actually also selects FPGA image number 0. (can be 0 to 3).
\ eg: load image3: $8003 $2000 io!

\ threadsafe IO port manipulation next: im! also works with leds to control specific leds.

: p! ( pmoddata -- ) 1 io! ; \ writes to GPIO register, turns actual pins on or off.
: pd! ( pmod-drive-pins-mask -- ) 2 io! ; \ sets which pins are driven (outputs)
: p@ ( -- pmoddata ) 1 io@ ; \ reads from actual pins

: im! ( io-mask-preset -- ) $8000 io! ; \ call before next io! or io@, 
\ to write only selected bits of leds, GPIO or GPIO Direction register in a threadsafe way
\ only masks io! to the leds or pmod (16 bit bidirectional io port), and it's direction register.
\ doesn't work for write to other io! peripherals. 
\ resets to all set after next io operation by same core, regardless of what the io address is.
\ use ' ioa io@ mask and ' to select out bits as usual.

: dl ( f mask -- f ) \ display a flag on a particular led, without consuming the flag
        im! dup leds
;
: mp! ( mask pmoddata -- ) swap im! p! ;
: md! ( mask pmoddir -- ) swap im! pd! ;
: ps! ( pins-to-write -- ) dup mp! ; \ pin set write, sets particular pins, leaves others alone.
: pc! ( pins-to-clear -- ) im! 0 p! ; \ pin clear write -- eg, 1 pc! sets the first pin only to off,
\ ... not on - leaves others alone..
\ don't do a read-modify-write anywhere in io space, since it's not thread-safe.


\ this next is for the fluid level sensor peripheral
: exon $100 s! ; \ turns excitation square wave generator on.
: exoff $200 s! ; \ disables excitation square wave generator.
: ex@ s@ $7000 and ; \ these three bits are full hi low in decreasing index order.
: flag and 0<> ;
: full? ex@ $4000 flag ;
: high? ex@ $2000 flag invert 2 dl invert ; \ leds will light on 'good' conditions.
: low? ex@ $1000 flag 1 dl invert ; \ true if 'low'

: xid ( -- coreId ) $2000 io@ $8000 and ; \ was : $8000 io@ ; \ this IO bit is set if not core0

: B>SPI $40 io! ; \ goes at 20 Mbits/s, no need to poll for one byte with the 10MHz j4a.
: >SPI $c0 io! begin $80 io@ 1 and 0<> until ; 
\ but you could miss a word if you don't poll for a word-write.
: >SPI> >SPI $40 io@ 2* ; \ note, last bit is lost, but this doesn't matter for our purposes.

: S2RC begin $20 io@ 0<> until ;
: B>SPI2 S2RC $10 io! ;
: B>SPI2> B>SPI2 begin $20 io@ 0<> until $10 io@ ; \ nb. byte will be in high side
: >SPI2 S2RC $30 io! ;
: >SPI2> >SPI2 S2RC $10 io@ ; 

: sp@ ( pktoffset -- pktdata ) 8 io! 8 io@ ; \ reads from slave SPI depacketizer. pktoffset is (0-63)

: sr@ $800 io@ ;
: sr! $800 io! ;
: sr@A! $1ff and $400 or $2000 io! ;
: sr!A! $1ff and $800 or $2000 io! ; 
: sr!0 0 sr!A! ;
: sr@0 0 sr@A! ;
: fillsr sr!0 256 0 do i sr! loop ;
: 0sr sr!0 512 0 do 0 sr! loop ;
: sr. sr@0 512 0 do sr@ .x cr loop ;
\ sample ram is supposed to be 512x16 bits, and that's how it's connected, but it's only doing byte addresses?

\ Wall clock peripheral, uses hardware tick clock
\ ----- 32 bit wall clock in ram
create wcd 0. , , \ wall clock, double.
variable lhc \ last hardware clk
: dwc ( -- wcl wch ) wcd 2@ ; \ call this to get the time, may be inaccurate by +/- tt @ ticks.
\ dwc ...... dwc ddelta d. \ will print number of clk ticks elapsed between each dwc call. Works at least upto ~44 seconds.
\ may be inaccurate due to wall clock tick unsteadiness
variable tt \ use to see wct update time in ticks.
: wct \ wall clock tick - update at least every couple ms to avoid HW clock overflow, but does not need to be updated smoothly.
dwc 
        lhc @ 
            $8000 io@ \ get HW clk
                dup lhc ! \ update lhc
                swap - \ new minus old
            dup tt ! \ update wct update time -- good for estimating 32 bit wall clock inaccuracy, but might not be steady.
            0  \ make into a ud
                d+   \ add onto wall clk
( : wc!)  wcd 2! ( ; wc! ) \ wall clock updated
\ to stay threadsafe, only one core should ever write.
;

