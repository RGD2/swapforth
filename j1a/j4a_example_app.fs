\ j4a_example_app.fs
\ #include me on a 'sudo make clean bootstrap j4a connect'
#include j4a_utils.fs

create b1leds %00000010 ,
create b2leds %00110000 ,
create b3leds %01001000 ,
create b1on 200 ,
create b2on 300 ,
create b3on 700 ,
create b1off 200 ,
create b2off 300 ,
create b3off 700 ,
: ledson dup im! leds ;
: ledsoff im! 0 leds ;
: b1 b1leds @ ledson  b1on @ ms  b1leds @ ledsoff  b1off @ ms ;
: b2 b2leds @ ledson  b2on @ ms  b2leds @ ledsoff  b2off @ ms ;
: b3 b3leds @ ledson  b3on @ ms  b3leds @ ledsoff  b3off @ ms ;
: start ['] b1 x1!  ['] b2 x2!  ['] b3 x3! ;
' start init !
#flash build/nuc.hex
#bye \ does not work - do a ^C
\ now do:
\ make
\ sudo make j4a connect

