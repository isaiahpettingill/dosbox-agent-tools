#include <conio.h>
#include <ctype.h>
#include <dos.h>
#include <stdio.h>
#include <string.h>

#define COM_PORTS 4
#define UART_DATA 0
#define UART_IER 1
#define UART_LCR 3
#define UART_LSR 5
#define UART_MCR 4
#define UART_TIMEOUT 60000U

static unsigned int ports[COM_PORTS];

static int parse_hex_byte(const char *text, unsigned char *value)
{
    unsigned int result;
    int digit;

    result = 0;
    if (*text == '\0') {
        return 0;
    }
    while (*text != '\0') {
        if (*text >= '0' && *text <= '9') {
            digit = *text - '0';
        } else if (*text >= 'a' && *text <= 'f') {
            digit = *text - 'a' + 10;
        } else if (*text >= 'A' && *text <= 'F') {
            digit = *text - 'A' + 10;
        } else {
            return 0;
        }
        result = (result << 4) | (unsigned int)digit;
        if (result > 0xff) {
            return 0;
        }
        ++text;
    }
    *value = (unsigned char)result;
    return 1;
}

static void initialize_uart(unsigned int base)
{
    /* 9600 baud, 8 data bits, no parity, one stop bit, FIFO enabled. */
    outp(base + UART_IER, 0);
    outp(base + UART_LCR, 0x80);
    outp(base + UART_DATA, 12);
    outp(base + UART_IER, 0);
    outp(base + UART_LCR, 0x03);
    outp(base + 2, 0xc7);
    outp(base + UART_MCR, 0x0b);
}

static int write_byte(unsigned int base, unsigned char value)
{
    unsigned int count;

    for (count = 0; count < UART_TIMEOUT; ++count) {
        if (inp(base + UART_LSR) & 0x20) {
            outp(base + UART_DATA, value);
            return 1;
        }
    }
    return 0;
}

static void show_status(unsigned int base)
{
    unsigned int lsr;
    unsigned int msr;

    lsr = inp(base + UART_LSR);
    msr = inp(base + 6);
    printf("LSR=%02Xh MSR=%02Xh", lsr, msr);
    if (lsr & 0x01) {
        printf(" data-ready");
    }
    if (lsr & 0x20) {
        printf(" transmitter-empty");
    }
    if (lsr & 0x1e) {
        printf(" receive-error");
    }
    printf("\r\n");
}

static void drain_input(unsigned int base)
{
    unsigned int count;
    unsigned char value;

    count = 0;
    while ((inp(base + UART_LSR) & 0x01) != 0) {
        value = (unsigned char)inp(base + UART_DATA);
        printf("%02X ", value);
        ++count;
        if ((count % 16) == 0) {
            printf("\r\n");
        }
    }
    if (count == 0) {
        printf("No received bytes.\r\n");
    } else if ((count % 16) != 0) {
        printf("\r\n");
    }
}

static void send_line(unsigned int base, char *line)
{
    char *token;
    unsigned char value;
    unsigned int count;

    count = 0;
    token = strtok(line, " \t\r\n");
    while (token != NULL) {
        if (!parse_hex_byte(token, &value)) {
            printf("Invalid byte: %s\r\n", token);
            return;
        }
        if (!write_byte(base, value)) {
            printf("UART transmit timeout after %u byte(s).\r\n", count);
            return;
        }
        ++count;
        token = strtok(NULL, " \t\r\n");
    }
    printf("Sent %u byte(s).\r\n", count);
}

int main(void)
{
    unsigned int index;
    unsigned int base;
    int selected;
    char line[160];

    printf("SERMON 1.0 - serial monitor (9600 8N1)\r\n\r\n");
    for (index = 0; index < COM_PORTS; ++index) {
        ports[index] = *(unsigned int far *)MK_FP(0x40, index * 2);
        if (ports[index] == 0) {
            printf("COM%u: unavailable\r\n", index + 1);
        } else {
            printf("COM%u: %04Xh\r\n", index + 1, ports[index]);
        }
    }
    printf("Select COM port (1-4, Q quits): ");
    if (fgets(line, sizeof(line), stdin) == NULL ||
        toupper((unsigned char)line[0]) == 'Q') {
        return 0;
    }
    selected = line[0] - '1';
    if (selected < 0 || selected >= COM_PORTS || ports[selected] == 0) {
        printf("That COM port is unavailable.\r\n");
        return 1;
    }
    base = ports[selected];
    initialize_uart(base);
    printf("COM%d initialized. I=status R=read S=send hex bytes Q=quit\r\n", selected + 1);
    for (;;) {
        printf("SERMON> ");
        if (fgets(line, sizeof(line), stdin) == NULL) {
            break;
        }
        switch (toupper((unsigned char)line[0])) {
        case 'I':
            show_status(base);
            break;
        case 'R':
            drain_input(base);
            break;
        case 'S':
            send_line(base, line + 1);
            break;
        case 'Q':
            return 0;
        default:
            printf("Commands: I, R, S hex bytes, Q\r\n");
            break;
        }
    }
    return 0;
}
