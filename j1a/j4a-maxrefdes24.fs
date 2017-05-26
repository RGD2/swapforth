#include j4a_utils.fs


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
$3f constant Csa \ all at once

$01 constant ERR

variable verror?

: b@ p@ dup %100000 and 0<> verror? ! ; \ see j4a.pcf, PA[5] connection. 

: ERR? b@ 1 and 0= ; \ checks if a conditioner chip saw a new error condition.

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
$2000 constant wC \ write config

\ config fields for rC and wC (combine with or)
\ $0800 constant Vm \ volt mode (current mode if not set)
\ or with one of the following three, else you're in standby mode (volts or not)
$0600 constant rup \ reduced unipolar mode (0.5V or 4..20mA)
\ $0400 constant up \ unipolar mode (0..10V or 0..20mA)
\ $0200 constant bp \ bipolar mode (-10..10V or -20..20mA)
\ next set of bits selects voltage brownout detection threshold.
\ 10V + 2V * X, where X is 0-7, giving a range 10V .. 24V in 2V steps.
\ $01C0 => X == 7. ie, +/-24V  threshold (most sensitive)
\ $0000 => X == 0, or +/- 10V threshold (least sensitive)
\ proper setting depends on what minimum overhead voltage
\ the connected load needs to function properly (assuming loop powered load)
$0180 constant vbot \ +/- 22V
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

create sdelay 597 , \ retune this if you play with runDAC or 2>DAC
variable fm
variable pos
create soffset -5350 , \ added to all C0 output, for offset correction: s/ Cs0 2>DAC / soffset @ + Cs0 2>DAC /g 

create shotcount 0. , , 
: UD.  <# #S #> TYPE ;
: shots shotcount 2@ ud. ;
\ preset idle C0 value to final value (ptv: pulse tail value)
ptv @ C0 !

: endshot 0 pos ! 0 fm ! sr@0 ;
: runDAC \ simple driver, updates at 2kHz
\ C0 will hold idle value only, rest will come from pulse.
ERR? verror? @ or 0<> if endshot then

fm @ if
\ pv pos @ cells + @ \ get next pv[pos] sample
sr@ \ now uses autoincrementing sample ram. 
  soffset @ + \ add soffset 
  $31 2>DAC \ send to channel 0.
pos @ 1+ 
  dup pl @ ( pulse length ) = if 
  drop 
endshot shotcount 2@ 1 m+ shotcount 2! 
else 
  pos ! 
then
else \ non firing mode.
C0 @ soffset @ + $31 2>DAC
1 us
then
C1 @ $32 2>DAC
C2 @ $34 2>DAC
C3 @ $38 2>DAC
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

$80 dup im! ERR? and leds \ set only the 8th led to reflect ERR?
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

variable firedelay \ set above 332 to start fire, below to stop. 1000 = ~one/sec
\ 3 Hz is the highest refire rate allowed == 333.
\ : inlet ( -- inletbar*100[+/-10] ) 0 8 io! 8 io@ 10922 - 328 / 33 * ;

\ all data channels from spislave module will run from 0 to 32767.
\ 32767 == 3.3V at the ADC input, 9929.394 counts per volt.
\ different sensors have different atmospheric pressure null values and sensitivities in counts per bar.
variable ip \ inlet pressure, 10922 null, 993 counts/bar. ~0.3 bar accurate
variable op \ outlet pressure, 9728 null, 99 counts/bar. ~3 bar accurate
variable hp \ high pressure seal oil pressure, 9929 null, 29 counts/bar.
variable lp \ low pressure seal oil pressure, 4965 null, 397 counts/bar.
\ updateps / sp@ needs to run on just one core - probably should be done just before using op value.

: m*/ ( d1 n2 u3 -- dquot ) \ double m-star-slash, dqout = d1 * n2 / u3
>r s>d >r abs rot rot s>d r> xor r> swap >r >r dabs rot tuck um* 2swap um* swap
>r 0 d+ r> rot rot r@ um/mod rot rot r> um/mod nip swap r> if dnegate then
; \ from GH://bewest/amforth's m-star-slash.frt. Who says forth isn't portable?
: inlet ip @ 10922 - 0 100 993  m*/ drop ; \ as below, but more accurate/slightly slower calc
\ : inlet ip @ 10922 - 328 / 33 * ; \ theadsafe
: hpso hp @ ;
: lpso lp @ ;
: outlet op @ ;

create ih 2500 , \ 25.00 bar def max - above range actually, max would be about 24, so just disables it, safe with new inlet pump system.
create il 1800 , \ 18 bar def min - allows accumulator to fill, may need tuning.
\ these next are not scaled, see /plant/experimental/SprayBench in dicewiki.
create hl 29800 , \ min HPSO, about 690 bar
create ll 14894 , \ min LPSO, about 25 bar, one more than the max that inlet pump ought to be able to reach. 
create oo 24879 , \ outlet Overload, 150 bar (~230 bar is max. visible)
create oh 20919 , \ outlet high max, 110 bar
create ot 19929 , \ outlet target pressure 100 bar
create ol 18166 , \ outlet low min, 90 bar
create ou 17949 , \ outlet underpressure, 80 bar

: rundac rundac 
0 sp@ ip !
1 sp@ hp !
2 sp@ lp !
fm @ 0= if 3 sp@ op ! then \ only update op if not actually firing right now -- deletes glitches 
;

create lov 0. , , \ last open valve time, d
create ctc 0. , , \ closed duration time, d 
: ct ctc 2@ ;
create lcv 0. , , \ last closed valve time, d
variable oc \ open count -- counts how many 'ct' durations the valve has been open for -- reset when valve closes.
: open %10000000 dup p@ and swap pc! if 
\ here we have just opened the manifold valve.
dwc \ get the current time
        2dup lov 2! \ update lov to the current time
        lcv 2@ \ get the time the valve last closed
                dnegate d+ \ gets the difference -- the duration the valve was last closed for
        \ now should just make sure it isn't too big or too small
        ctc 2! \ save it as the 'closed time' duration, ct
then ;
variable sud \ speed up delta (ms / ct slower than 3)
: close %10000000 dup p@ and swap ps! 0= if
\ here we have just closed the manifold valve.
dwc lcv 2!
oc @
    \ conditions to close valve have happened (or have been overridden). 
    dup 3 < if \ if open duty cycle is <75%, we're going too slow.
    3 swap - \ now 1,2 or 3.
    sud @ * \ scales to 'speed up multiplier' ms
    firedelay @ 
        dup 0<> if 
        swap - 
    500 max firedelay ! 
else
        drop drop 
then
else 
    drop
then
0 oc ! \ reset open count to zero
then ;

: ddelta ( oldd newd -- durationd ) 2swap dnegate d+ ; \ like 'swap -' but for two ud 's 

: co \ control outlet valve -- state updating loop, critical timing not necessary.
wct
outlet
    ( outletrawp )
    \ controls outlet valve based on pressure and fill level
    dup 
        oh @ > high? or \ manifold pressure over normal upper limit or level reaches high limit
        if 
    open drop \ open manifold outlet valve
else \ valve opening triggers override valve closing triggers
    ol @ < low? or \ manifold pressure low or level low
    if close then \ close manifold outlet valve
then

%10000000 p@ and 0= \ what's the valve's state?
    \ true if open, but we also need ct to make sense
    ct d0= invert and \ abort if ct is zero
    ct -960000000. d+ nip 0< and \ ct should be less than 20 seconds
    ct nip 0< invert and \ also ct is positive - above test fails for ct > $b9000000. 
    if \ while valve is open ( and ct relatively short )
\ how many 'close time' durations have we been open for so far this time?
lov 2@ dwc ddelta \ this is the current time since last opened the valve
        \ this smoothly increasing delay is bigger or less than ct (the last 'closed time' duration)
        ct dnegate d+ 
        dup 0< invert if \ not negative, we've waited a ct into a apparent length of the open-time
        dwc 2swap dnegate d+ lov 2! \ update - make lov look only as far ago as the currently positive difference.
oc @ 1+ dup oc ! \ increment oc and keep on stack
    \ now we have updated oc, how big is it?
    dup 4 - ( if 4 or more ) 0< invert if
    \ >4x as much open as closed means duty cycle > 80%, so we should start slowing down.
    \ want to slow down faster the longer this goes on -- ulimately stopping if we reach firedelay>2000 or so, since that's too long.
    \ this section only runs for each 'ct' delay that the valve is open for beyond the first 4, so the duty cycle is changing like:
    \ > 4/5 (80%), 5/6, 6/7, 7/8, 8/9, and 9/10..
    \ but on the next cycle, with a longer firedelay, the ct will also be longer -- number of shots to fill should be about constant, 
    \ so it will take proportionally longer with longer firedelay.
    \ we want to be around 3/5 ~ 60%-79.9%, but we want to slow down gradually.
    \ we need to slow down just enough that with no other changes, we land on about 79% duty cycle...
    case
    4 of 10 endof
    5 of 40 endof
    6 of 160 endof
    7 of 640 endof
    8 of 650 endof
    >R -5000 R> \ default which should just stop - already going slower than 30 RPM, so give up.
    endcase
    firedelay @ +
    0 max 2000 min \ coerce to zero if giving up, or no slower than 30 RPM otherwise.
    firedelay !
else 
    drop \ oc < 4, means duty cycle this time hasn't reached 80% open yet.
then
else 
        drop drop \ delay was negative -- haven't waited another ct yet, so drop the duration and do nothing.
then 
else \ valve is closed anyway
then
;
\ bang/bang control works fairly well.
\ the signal is on until oh is exceeded, then off until outlet is below ol.
\ it runs continually, and incidentally also updates ip/op/hp/lp for firecontrol thread.

: openfire 1000 firedelay ! ;
: rapidfire 500 firedelay ! ;
: ceasefire 0 firedelay ! hpsopoff ;

: i? ( -- f )  \ nonzero (true) means ok to fire 
\ this is very important: The refil can be late / inlet valve can be still open, and we must not fire if so, because it WILL BREAK.
\ under that condition usually it's because of insufficient pressure at the inlet
inlet dup ih @ < swap il @ > and \ (inlet pressure within range -- probably inlet valve has shut already.)
    hpso hl @ > and  \ hpso > hpso low level
    lpso ll @ > and
    outlet dup ou @ > swap oo @ < and and \ outlet pressure within hard limits
    full? invert and \ don't fire if outlet manifold is completely full.
;

: shoot i? if 1 fm ! then ; \ use this to override / fire manually.

: fc \ firecontrol 
inlet ih @ > if ceasefire purge then  \ overpressure means stop, cease and purge.
					\ disabled because max inlet reading is about 24, and we go higher currently.
firedelay @ 
    dup
        332 - 0< if \ won't go faster than about 180 RPM, also used to park.
    drop \ park / ceasefire state
else \ hesitate or shoot and wait
    i? if hpsopon 1 fm !  \ shoot now
    ms \ waits here firedelay ms between shot starts
hpsopoff \ turn off hpso pump automaticall after firedelay -- but will be back here with it on if ready to fire again immediately.
\ this is so if we never fire again, we don't overfill the injector while waiting.
else 
    drop \ hesitate state, fc hammers at i? until it's true, then immediately fires the next waiting shot.
    \ this allows hesitation until conditions are acceptable, which analysis will detect as some kind of problem in the fuel system.
    \ because it will cause an isolated 'late' shot. 
then
then ;
: startfc ['] fc x2! ;
: stopfc x2k ;

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
wC dup dup dup D0! ! D1! ! D2! ! D3! !
\ note, doesn't do anything until the driver starts.
bootdac
wc rup or vbot or d0! ! \ tell channel 0 conditioner chip to activate 4..20mA output mode.
-1 reqCom ! \ request communications to conditioner chips.
['] runDAC x1! \ start maxrefdes24 driver running.
50 ms
ERR? if 0ERR! then \ clear error conditions.
['] co x3!
startfc
;
: sr!v sr! sr@ ."    " .x cr cr ;

