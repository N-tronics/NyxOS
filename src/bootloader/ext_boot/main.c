#include "stdlib/int.h"
#include "stdlib/io.h"

void _cdecl cstart_(uint16_t bootDrive) {
    puts("Hello, world from NyxOS!\r\n");

    printf("%% %c %s\r\n", 'a', "string");
    printf("%d %i %x %p %o %hd %hi %hhu %hhd\r\n", 1234, -5678, 0xdead, 0xbeef,
           012345, (short)27, (short)-42, (unsigned char)20, (signed char)-10);
    printf("%ld %lx %lld %llx\r\n", -100000000l, 0xdeadbeeful, 10200300400ll,
           0xdeadbeeffeebdaedull);

    for (;;)
        ;
}
