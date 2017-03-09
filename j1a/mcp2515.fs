\ This is for a Microchip MCP2515 connected to the SPI2 peripheral module, with it's nCS on the MSb of the io port.

\ it assumes #include j4a_util.fs
\ containing words: B>SPI2 B>SPI2> >SPI2 >SPI2> pmo pmd

: cIdle $8000 dup dup pmd dup pmo ;
: cSel $8000 0 pmo ;
: creset cSel $c0 B>SPI2 cIdle ;
: cstat cSel $a0 B>SPI2 0 >SPI2> cIdle ;
: crstat cSel $b0 B>SPI2 0 >SPI2> cIdle ;
: c@ ( caddrbyte -- cdata ) cSel 3 B>SPI2 B>SPI2 0 B>SPI2> cIdle ;
: c! ( data caddrbyte -- ) cSel 2 B>SPI2 B>SPI2 B>SPI2 cIdle ;

