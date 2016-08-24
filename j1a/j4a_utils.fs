
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

: on1 ( xt -- ) $100 io! ; \ make core 1 run an XT.
: on2 ( xt -- ) $200 io! ;
: on3 ( xt -- ) $400 io! ;
: once ( standard/looping xt -- runonce xt ) 1+ ;
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