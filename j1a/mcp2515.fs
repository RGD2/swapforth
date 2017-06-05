\ This is for a Microchip MCP2515 connected to the SPI2 peripheral module, with it's nCS on the MSb of the io port.

\ it assumes #include j4a_util.fs
\ containing words: B>SPI2 B>SPI2> >SPI2 >SPI2> pmo pmd
: cp $8000 ;

: <\ cp pc! ;
: /> cp ps! ;
: cbd <\ B>SPI2 /> ;
: cbw <\ B>SPI2 0 >SPI2> /> ;

: creset  $c0 cbd ;
: cstat  $a0 cbw ;
: crstat $b0 cbw ;
: c@ ( caddrbyte -- cdata ) <\ 3 B>SPI2 B>SPI2 0 B>SPI2> /> ;
: c! ( data caddrbyte -- ) <\ 2 B>SPI2 B>SPI2 B>SPI2 /> ;

\ there's a little more refactoring that can be done, but its a case of diminishing returns at this point..
\ maybe next time...


