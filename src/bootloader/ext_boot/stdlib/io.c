#include "io.h"
#include "int.h"
#include "types.h"
#include "x86.h"

void putc(char c) { x86_Video_WriteCharTTY(c, 0); }

void puts(const char *str) {
    while (*str) {
        putc(*str);
        str++;
    }
}

enum PRINTF_STATE { NORMAL, LENGTH, S_LONG, S_SHORT, SPECIFER };
enum PRINTF_LENGTH { DEFAULT, SHORT, SHORT_SHORT, LONG, LONG_LONG };

const char HEXCHARS[] = "0123456789abcdef";

int *printf_number(int *argp, enum PRINTF_LENGTH length, bool sign, int radix) {
    char buffer[32];
    int8_t pos = 0;
    uint64_t number;
    int8_t number_sign = 1;

    switch (length) {
    case SHORT_SHORT:
    case SHORT:
    case DEFAULT:
        if (sign) {
            int n = *argp;
            if (n < 0) {
                n = -n;
                number_sign = -1;
            }
            number = (uint64_t)n;
        } else
            number = *(unsigned int *)argp;
        argp++;
        break;
    case LONG:
        if (sign) {
            long int n = *(long int *)argp;
            if (n < 0) {
                n = -n;
                number_sign = -1;
            }
            number = (uint64_t)n;
        } else
            number = *(unsigned long int *)argp;
        argp += 2;
        break;
    case LONG_LONG:
        if (sign) {
            long long int n = *(long long int *)argp;
            if (n < 0) {
                n = -n;
                number_sign = -1;
            }
            number = (uint64_t)n;
        } else
            number = *(uint64_t *)argp;
        argp += 4;
        break;
    }

    do {
        uint32_t rem;
        x86_div64_32(number, radix, &number, &rem);
        buffer[pos++] = HEXCHARS[rem];
    } while (number > 0);
    if (sign && number_sign < 0)
        buffer[pos++] = '-';

    while (--pos >= 0)
        putc(buffer[pos]);

    return argp;
}

void _cdecl printf(const char *fmt, ...) {
    int *argp = (int *)&fmt;
    enum PRINTF_STATE state = NORMAL;
    enum PRINTF_LENGTH length = DEFAULT;

    // TODO: replace with argp += sizeof(fmt)/sizeof(int)
    argp++;
    while (*fmt) {
        switch (state) {
        case NORMAL:
            switch (*fmt) {
            case '%':
                state = LENGTH;
                break;
            default:
                putc(*fmt);
                break;
            }
            break;
        case LENGTH:
            switch (*fmt) {
            case 'l':
                length = LONG;
                state = S_LONG;
                break;
            case 'h':
                state = S_SHORT;
                length = SHORT;
                break;
            default:
                goto SPECIFER_;
            }
            break;
        case S_LONG:
            if (*fmt == 'l') {
                length = LONG_LONG;
                state = SPECIFER;
            } else
                goto SPECIFER_;
            break;
        case S_SHORT:
            if (*fmt == 'h') {
                length = SHORT_SHORT;
                state = SPECIFER;
            } else
                goto SPECIFER_;
            break;
        case SPECIFER:
        SPECIFER_:
            switch (*fmt) {
            case 'c':
                putc((char)*argp);
                argp++;
                break;
            case '%':
                putc('%');
                break;
            case 's':
                puts(*(char **)argp);
                argp++;
                break;
            case 'd':
            case 'i':
                argp = printf_number(argp, length, true, 10);
                break;
            case 'u':
                argp = printf_number(argp, length, false, 10);
                break;
            case 'X':
            case 'x':
            case 'p':
                argp = printf_number(argp, length, false, 16);
                break;
            case 'o':
                argp = printf_number(argp, length, false, 8);
                break;
            default:
                break;
            }

            state = NORMAL;
            length = DEFAULT;
            break;
        }

        fmt++;
    }
}
