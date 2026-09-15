#include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#define DEFAULT_MINIMUM 4
#define MAXIMUM_STRING 160
#define PAGE_LINES 22

static void usage(void)
{
    printf("Usage: STRINGS file [minimum]\r\n");
}

int main(int argc, char *argv[])
{
    FILE *input;
    unsigned int minimum;
    unsigned int length;
    unsigned int lines;
    int value;
    int key;
    char text[MAXIMUM_STRING + 1];

    if (argc < 2 || argc > 3) {
        usage();
        return 0;
    }
    minimum = argc == 3 ? (unsigned int)atoi(argv[2]) : DEFAULT_MINIMUM;
    if (minimum == 0 || minimum > MAXIMUM_STRING) {
        printf("Minimum must be from 1 to %u.\r\n", MAXIMUM_STRING);
        return 1;
    }
    input = fopen(argv[1], "rb");
    if (input == NULL) {
        printf("Cannot open %s.\r\n", argv[1]);
        return 1;
    }
    length = 0;
    lines = 0;
    while ((value = fgetc(input)) != EOF) {
        if (value >= 32 && value <= 126) {
            if (length < MAXIMUM_STRING) {
                text[length++] = (char)value;
            }
            continue;
        }
        if (length >= minimum) {
            text[length] = '\0';
            puts(text);
            ++lines;
            if (lines == PAGE_LINES) {
                cprintf("-- more: any key, Q quits --");
                key = getch();
                cprintf("\r\n");
                if (key == 'q' || key == 'Q') {
                    fclose(input);
                    return 0;
                }
                lines = 0;
            }
        }
        length = 0;
    }
    if (length >= minimum) {
        text[length] = '\0';
        puts(text);
    }
    fclose(input);
    return 0;
}
