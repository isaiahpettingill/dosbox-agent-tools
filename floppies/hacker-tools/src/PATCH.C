#include <stdio.h>
#include <stdlib.h>

static int parse_hex(const char *text, unsigned long *value)
{
    unsigned long result;
    int digit;

    if (*text == '\0') {
        return 0;
    }
    result = 0;
    while (*text != '\0') {
        if (*text >= '0' && *text <= '9') {
            digit = *text - '0';
        } else if (*text >= 'A' && *text <= 'F') {
            digit = *text - 'A' + 10;
        } else if (*text >= 'a' && *text <= 'f') {
            digit = *text - 'a' + 10;
        } else {
            return 0;
        }
        result = (result << 4) | (unsigned long)digit;
        ++text;
    }
    *value = result;
    return 1;
}

int main(int argc, char *argv[])
{
    FILE *output;
    unsigned long offset;
    unsigned long file_size;
    unsigned long value;
    int index;

    if (argc < 4) {
        printf("Usage: PATCH file hex-offset hex-byte [hex-byte ...]\r\n");
        return 0;
    }
    if (!parse_hex(argv[2], &offset)) {
        printf("Invalid hexadecimal offset.\r\n");
        return 1;
    }
    output = fopen(argv[1], "r+b");
    if (output == NULL) {
        printf("Cannot open %s for writing.\r\n", argv[1]);
        return 1;
    }
    fseek(output, 0L, SEEK_END);
    file_size = (unsigned long)ftell(output);
    if (offset > file_size || (unsigned long)(argc - 3) > file_size - offset) {
        printf("Patch exceeds the existing file.\r\n");
        fclose(output);
        return 1;
    }
    if (fseek(output, (long)offset, SEEK_SET) != 0) {
        printf("Cannot seek to %lXh.\r\n", offset);
        fclose(output);
        return 1;
    }
    for (index = 3; index < argc; ++index) {
        if (!parse_hex(argv[index], &value) || value > 0xff) {
            printf("Invalid byte: %s\r\n", argv[index]);
            fclose(output);
            return 1;
        }
        if (fputc((int)value, output) == EOF) {
            printf("Write failed.\r\n");
            fclose(output);
            return 1;
        }
    }
    fclose(output);
    printf("Patched %d byte(s) at %lXh.\r\n", argc - 3, offset);
    return 0;
}
