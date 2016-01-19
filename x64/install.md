# Requirements 

## Ubuntu 14.04.3 LTS

    nasm libc6-dev-i386

This last package is 32bit, but without it compilation fails at

``` 
In file included from /usr/include/stdio.h:27:0,
                 from main.c:1:
/usr/include/features.h:374:25: fatal error: sys/cdefs.h: No such file or directory
 #  include <sys/cdefs.h>
                         ^
```
