#include j4a_utils.fs



\ this next is for the fluid level sensor peripheral
: exon $100 s! ; \ turns excitation square wave generator on.
: exoff $200 s! ; \ disables excitation square wave generator.
: ex@ s@ $7000 and ; \ these three bits are full hi low in decreasing index order.
: flag and 0<> ;

\ #include ../../j4a-code/mrc-profile.fs
\ defines pv pl ptv ptl
\ the last three were 'constants' accessed by name only and not name !
\ they have been changed to:
create pl 1 ,
create ptv $A774 dup ,
variable ptl \ created anyway, because it's expected by the sample file
 \ ptl wasn't used, and pv has been moved into the sample ram.
  sr!0 sr! \ preloads it with the value we know doesn't hurt anything.
\ these settings mean that if not loaded, it won't fire.
\ but the servo valve will be idle.
variable C0
variable C1
variable C2
variable C3

$31 constant Cs0
$32 constant Cs1
$34 constant Cs2
$38 constant Cs3
\ $3f constant Csa \ all at once

$01 constant ERR

variable

: verror? p@ %100000 and 0<> ; \ see j4a.pcf, PA[5] connection. 

: ERR? p@ 1 and 0= ; \ checks if a conditioner chip saw a new error condition.

: 2>DAC $06 $02 mp! B>SPI >SPI $06 dup mp! ; \ DAC chip wants 24 bit writes.

\ other code can talk to these:
variable D0!
variable D1!
variable D2!
variable D3!
\ with this stuff:
\ SPI command bits for conditioner chips (Dn[!@]) (use one of, zeros means nop.)
\ $a000 constant rC \ read config
$8000 constant rE \ read Errorflags
\ $2000 constant wC \ write config

\ config fields for rC and wC (combine with or)
\ $0800 constant Vm \ volt mode (current mode if not set)
\ or with one of the following three, else you're in standby mode (volts or not)
\ $0600 constant rup \ reduced unipolar mode (0.5V or 4..20mA)
\ $0400 constant up \ unipolar mode (0..10V or 0..20mA)
\ $0200 constant bp \ bipolar mode (-10..10V or -20..20mA)
\ next set of bits selects voltage brownout detection threshold.
\ 10V + 2V * X, where X is 0-7, giving a range 10V .. 24V in 2V steps.
\ $01C0 => X == 7. ie, +/-24V  threshold (most sensitive)
\ $0000 => X == 0, or +/- 10V threshold (least sensitive)
\ proper setting depends on what minimum overhead voltage
\ the connected load needs to function properly (assuming loop powered load)
\ $0180 constant vbot \ +/- 22V
\ $0020 constant tsd \ thermal shutdown protection
\ remainder of bits should be zeros

\ pre-set defaults: no tsd, current mode, standby.
\ error bitfields for rE
\ $0400 constant eI \ intermittent error flag - fault cleared itself.
\ $0200 constant eSC \ short circuit detect, Iout > 30 mA
\ $0100 constant eOC \ open circuit detect, V within 30 mV of supply
\ $0080 constant eOH \ internal overtemperature. >150&deg;C Doesn't do intermittent.
\ $0040 constant eSB \ supply brownout. Either supply went into brownout limits.
\ performing rE resets the output error signal (ERR on p@), which is edge sensitive to new error conditions.
\ rE will clear the error flags when the error condition is no longer present.
\ if the error condition resolved before rE, then eI will be set to indicate the error was intermittent.

\ other code will read results of reads from these
variable D0@
variable D1@
variable D2@
variable D3@
create reqCom 1 , \ set to request CONS

: bootdac $0200 $05 2>DAC 10 ms 0 $05 2>DAC ;

create sdelay 594 , \ retune this if you play with runDAC or 2>DAC
variable fm
variable pos
create soffset -5350 , \ added to all C0 output, for offset correction: s/ Cs0 2>DAC / soffset @ + Cs0 2>DAC /g 

create sc 0. , , \ shotcount
: UD.  <# #S #> TYPE ;
: shots sc 2@ ud. ;
\ preset idle C0 value to final value (ptv: pulse tail value)
ptv @ C0 !

: endshot 0 pos ! 0 fm ! sr@0 ;
: runDAC \ simple driver, updates at 2kHz
\ C0 will hold idle value only, rest will come from pulse.
ERR? verror? or 0<> if endshot then

fm @ if
\ pv pos @ cells + @ \ get next pv[pos] sample
sr@ \ now uses autoincrementing sample ram. 
  soffset @ + \ add soffset 
  Cs0 2>DAC \ send to channel 0.
pos @ 1+ 
  dup pl @ ( pulse length ) = if 
  drop 
endshot sc 2@ 1 m+ sc 2! 
else 
  pos ! 
then
else \ non firing mode.
C0 @ soffset @ + Cs0 2>DAC
1 us
then
C1 @ Cs1 2>DAC
C2 @ Cs2 2>DAC
C3 @ Cs3 2>DAC
reqCom @ if 
$06 $04 mp!
\ must access all conditioner chips in the one SPI access.
\ so, can't skip any in case a later one needs an access.
\ ok to send zeros though, as those are no-ops.
\ Dx@ need to be manually cleared by the receiving code.
\ will update Dn@ only on reads, and only to set bits.
D0! @ dup rE and if >SPI> D0@ @ or D0@ ! else >SPI 2 us then
D1! @ dup rE and if >SPI> D1@ @ or D1@ ! else >SPI 2 us then
D2! @ dup rE and if >SPI> D2@ @ or D2@ ! else >SPI 2 us then
D3! @ dup rE and if >SPI> D3@ @ or D3@ ! else >SPI 2 us then
$06 dup mp! 
0 reqCom ! else 8 us then

ERR? verror? or $80 and dup im! leds \ set only the 8th led to reflect ERR?
sdelay @ us

;


: 0ERR!
rE D0! !
rE D1! !
rE D2! !
rE D3! !
0 D0@ !
0 D1@ !
0 D2@ !
0 D3@ !
1 reqCom !
sdelay @ 2* us
1 reqCom !
0 D0! !
0 D1! !
0 D2! !
0 D3! !
;

: enableservo %10000 ps! ; \ enable servovalve (see PA[4] in j4a.pcf)
: disableservo %10000 pc! ; \ disable servovalve, now defaults to enabled, 
\ possibly shouldn't ever be disabled, since that seems to default to 'full on', and not full off.
\ latter might be due to intentional reversal of valve control characteristic compared to the docs.
\ possibly so as to remove fuel from the pump, and hold it emptied.
\ in any case, it's violent at full pressure, and we usually fire manually on flush to clear old fuel
\ after a long run in any case.

: purge %1000 pc! ; \ note purge no longer disables the servovalve
: load %1000 ps! ; \ purge ctl (see PA[3] in .pcf)

: hpsopon %1000000 ps! ;
: hpsopoff %1000000 pc! ; \ controls the high pressure seal oil pump, defaults to off.

variable FIREDELAY \ set above 332 to start fire, below to stop. 1000 = ~one/sec
\ 3 Hz is the highest refire rate allowed == 333.
\ : inlet ( -- inletbar*100[+/-10] ) 0 8 io! 8 io@ 10922 - 328 / 33 * ;

\ all data channels from spislave module will run from 0 to 32767.
\ 32767 == 3.3V at the ADC input, 9929.394 counts per volt.
\ different sensors have different atmospheric pressure null values and sensitivities in counts per bar.
variable ip
variable op
variable hp
variable lp
\ updateps / sp@ needs to run on just one core - probably should be done just before using op value.

: m*/ ( d1 n2 u3 -- dquot ) \ double m-star-slash, dqout = d1 * n2 / u3
>r s>d >r abs rot rot s>d r> xor r> swap >r >r dabs rot tuck um* 2swap um* swap
>r 0 d+ r> rot rot r@ um/mod rot rot r> um/mod nip swap r> if dnegate then
; \ from GH://bewest/amforth's m-star-slash.frt. Who says forth isn't portable?

: inlet  ip @ 10280 - 0 100 993 m*/ drop ; \ inlet pressure, 10922 null, 993 counts/bar. ~0.3 bar accurate
: hpso   hp @  9929 - 0 10  29  m*/ drop ; \ high pressure seal oil pressure, 9929 null, 29 counts/bar.
: lpso   lp @  4965 - 0 100 397 m*/ drop ; \ low pressure seal oil pressure, 4965 null, 397 counts/bar.
: outlet op @  9728 - 0 100 99  m*/ drop ; \ outlet pressure, 9728 null, 99 counts/bar. ~3 bar accurate

: h. 0 <# # # [CHAR] . HOLD #S #> TYPE ;
: t. 0 <# # [CHAR] . HOLD #S #> TYPE ;

create ih 2500 , \ 25.00 bar def max - above range actually, max would be about 24, so just disables it, safe with new inlet pump system.
\ it was being used previously to detect inlet overpressure due to inlet valve failure, but the new pumps will prevent it.
create il 1600 , \ 16 bar def min - allows accumulator to fill, may need tuning.
\ these next are not scaled, see /plant/experimental/SprayBench in dicewiki.
create hl 6900 , \  bar/10 min HPSO, about 690 bar
create ll 2000 , \ bar/100 min LPSO, about 20 bar, one more than the max that inlet pump ought to be able to reach. 
create oo 11000 , \ outlet Overload (~230 bar is max. visible)
create oh 11000 , \ outlet high max
create ol 11000 , \ outlet low min
create ou 11000 , \ outlet underpressure

: rundac rundac 
0 sp@ ip !
1 sp@ hp !
2 sp@ lp !
fm @ 0= if 3 sp@ op ! then \ only update op if not actually firing right now -- deletes glitches 
;


: open %10000000 pc! ;
: close %10000000 ps! ;

: openfire 1000 FIREDELAY ! ;
: rapidfire 500 FIREDELAY ! ;
: ceasefire 0 FIREDELAY ! hpsopoff ;

: full? ex@ $4000 flag ;
: high? ex@ $2000 flag invert 2 dl invert fm @ 0= and ; \ coerced off if during a shot -- to try to ignore splashes
\ leds will light on 'good' conditions.
: low? ex@ $1000 flag 1 dl invert ; \ true if 'low', ie, no longer in contact with bottom probe
 
: i? ( -- f )  \ nonzero (true) means ok to fire 
\ this is very important: The refil can be late / inlet valve can be still open, and we must not fire if so, because it WILL BREAK.
\ under that condition usually it's because of insufficient pressure at the inlet
inlet dup ih @ < swap il @ > $40 dl and \ (inlet pressure within range -- probably inlet valve has shut already.)
    hpso hl @ > $20 dl and  \ hpso > hpso low level
    lpso ll @ > $10 dl and
    outlet dup ou @ > swap oo @ < and 8 dl and \ outlet pressure within hard limits
    full? invert 4 dl and \ don't fire if outlet manifold is completely full.
;

: shoot i? if 1 fm ! then ; \ use this to override / fire manually.
create ventms 400 , \ ms to open outlet valve for each time.
create vpshot 143 , \ ms time per shot (vary as needed)
: vpshot! ( n -- ) \ saves to vps, with limits 
    140 max \ no less than this
    ventms @ 51 - min \ but no more than whatever ventms-51 is.
    vpshot !
;
variable ventacc \ holds accumulated vent time
variable vm \ vent 'mode'
: vc \ valve control
vm @ 0<> if 
\ there's a request, should we open or wait?
low? invert inlet 
0 vm ! open ventms @ ms close 50 ms 

then ;
: fc \ firecontrol 
FIREDELAY @ 
    dup
        332 - 0< if \ won't go faster than about 180 RPM, also used to park.
    drop \ park / ceasefire state
else \ hesitate or shoot and wait
    i? if hpsopon 1 fm !  \ shoot now
    ventacc @ vpshot @ + 
        \ incremented total, is it big enough yet?
        dup ventms @ > if ( it is ) ventms @ - ventacc ! 1 vm ! else ( it isn't ) ventacc ! then
    ms \ waits here firedelay ms between shot starts
hpsopoff \ turn off hpso pump automatically after firedelay -- but will be back here with it on if ready to fire again immediately.
\ this is so if we never fire again, we don't overfill the injector while waiting.
else 
    drop \ hesitate state, fc hammers at i? until it's true (or the thread is stopped), then immediately fires the next waiting shot.
    \ this allows hesitation until conditions are acceptable, which analysis will detect as some kind of problem in the fuel system.
    \ because it will cause an isolated 'late' shot. 
then
then ;
: startfc ['] fc x3! ;
: stopfc x3k ;

\ ==== initialisation here (ini) at end of file.
: ini
\ /------------------- nCS for CAN BUS module
\ |       /----------- outlet manifold vent solenoid, off==vent
\ |       |/---------- HPSO pump
\ |       ||/--------- input, valve error
\ |       |||/-------- servo valve enable
\ |       ||||/------- inlet fuel bleed valve, off=bleed
\ |       |||||/------ nCS2 maxrefdes24
\ |       ||||||/----- nCS1 maxrefdes24
\ |       |||||||/---- input, ERR maxrefdes24
 %1000000010010110 p!  \ port initial outputs
 %1000000011011110 pd! \ initialise output chip select pins high (chip selects are active low.)
$2000 ( wC ) dup dup dup D0! ! D1! ! D2! ! D3! !
\ note, doesn't do anything until the driver starts.
bootdac
$2780 ( wc rup or vbot or ) d0! ! \ tell channel 0 conditioner chip to activate 4..20mA output mode.
-1 reqCom ! \ request communications to conditioner chips.
['] runDAC x1! \ start maxrefdes24 driver running.
50 ms
ERR? if 0ERR! then \ clear error conditions.
exon \ start excitation for level detection
startfc
['] vc x2! \ start valve controller
;
marker |
: sr!v sr! sr@ ."    " .x cr cr ;

