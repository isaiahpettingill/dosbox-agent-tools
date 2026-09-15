#include <ctype.h>
#include <stdio.h>
#include <string.h>

static char *trim(char *text)
{
    char *end;

    while (*text == ' ' || *text == '\t') {
        ++text;
    }
    end = text + strlen(text);
    while (end > text && (end[-1] == ' ' || end[-1] == '\t' ||
           end[-1] == '\r' || end[-1] == '\n')) {
        *--end = '\0';
    }
    return text;
}

static void uppercase(char *text)
{
    while (*text != '\0') {
        *text = (char)toupper((unsigned char)*text);
        ++text;
    }
}

static int number(const char *text, unsigned int *value)
{
    unsigned int result;
    int digit;
    size_t length;

    length = strlen(text);
    if (length == 0) {
        return 0;
    }
    if (text[length - 1] == 'H' || text[length - 1] == 'h') {
        --length;
    }
    if (length == 0) {
        return 0;
    }
    result = 0;
    while (length-- != 0) {
        if (*text >= '0' && *text <= '9') {
            digit = *text - '0';
        } else if (*text >= 'A' && *text <= 'F') {
            digit = *text - 'A' + 10;
        } else if (*text >= 'a' && *text <= 'f') {
            digit = *text - 'a' + 10;
        } else {
            return 0;
        }
        result = (result << 4) | (unsigned int)digit;
        ++text;
    }
    *value = result;
    return 1;
}

static int register_number(const char *text, int *is_byte)
{
    static const char *words[] = { "AX", "CX", "DX", "BX", "SP", "BP", "SI", "DI" };
    static const char *bytes[] = { "AL", "CL", "DL", "BL", "AH", "CH", "DH", "BH" };
    int index;

    for (index = 0; index < 8; ++index) {
        if (strcmp(text, words[index]) == 0) {
            *is_byte = 0;
            return index;
        }
        if (strcmp(text, bytes[index]) == 0) {
            *is_byte = 1;
            return index;
        }
    }
    return -1;
}

static int emit_byte(FILE *output, unsigned int value)
{
    return fputc((int)(value & 0xff), output) == EOF;
}

static int assemble_db(FILE *output, char *arguments)
{
    char *item;
    unsigned int value;

    item = strtok(arguments, ",");
    while (item != NULL) {
        item = trim(item);
        if (*item == '\'' && item[strlen(item) - 1] == '\'') {
            item[strlen(item) - 1] = '\0';
            ++item;
            while (*item != '\0') {
                if (emit_byte(output, (unsigned char)*item++)) {
                    return 0;
                }
            }
        } else if (!number(item, &value) || value > 0xff || emit_byte(output, value)) {
            return 0;
        }
        item = strtok(NULL, ",");
    }
    return 1;
}

static int assemble_line(FILE *output, char *line)
{
    char *opcode;
    char *arguments;
    char *comma;
    unsigned int value;
    int register_index;
    int is_byte;

    if ((arguments = strchr(line, ';')) != NULL) {
        *arguments = '\0';
    }
    line = trim(line);
    if (*line == '\0') {
        return 1;
    }
    opcode = strtok(line, " \t");
    arguments = strtok(NULL, "\r\n");
    uppercase(opcode);
    if (arguments != NULL && strcmp(opcode, "DB") != 0) {
        arguments = trim(arguments);
        uppercase(arguments);
    }
    if (strcmp(opcode, "ORG") == 0) {
        return arguments != NULL && number(arguments, &value);
    }
    if (strcmp(opcode, "DB") == 0) {
        return arguments != NULL && assemble_db(output, arguments);
    }
    if (strcmp(opcode, "NOP") == 0) {
        return emit_byte(output, 0x90) == 0;
    }
    if (strcmp(opcode, "RET") == 0) {
        return emit_byte(output, 0xc3) == 0;
    }
    if (strcmp(opcode, "INT") == 0) {
        return arguments != NULL && number(arguments, &value) && value <= 0xff &&
            emit_byte(output, 0xcd) == 0 && emit_byte(output, value) == 0;
    }
    if (strcmp(opcode, "PUSH") == 0 || strcmp(opcode, "POP") == 0) {
        register_index = arguments == NULL ? -1 : register_number(arguments, &is_byte);
        return register_index >= 0 && !is_byte &&
            emit_byte(output, (strcmp(opcode, "PUSH") == 0 ? 0x50 : 0x58) + register_index) == 0;
    }
    if (strcmp(opcode, "MOV") != 0 || arguments == NULL ||
        (comma = strchr(arguments, ',')) == NULL) {
        return 0;
    }
    *comma++ = '\0';
    arguments = trim(arguments);
    comma = trim(comma);
    register_index = register_number(arguments, &is_byte);
    if (register_index < 0 || !number(comma, &value) || (is_byte && value > 0xff)) {
        return 0;
    }
    if (is_byte) {
        return emit_byte(output, 0xb0 + register_index) == 0 && emit_byte(output, value) == 0;
    }
    return emit_byte(output, 0xb8 + register_index) == 0 && emit_byte(output, value) == 0 &&
        emit_byte(output, value >> 8) == 0;
}

int main(int argc, char *argv[])
{
    FILE *input;
    FILE *output;
    char line[256];
    unsigned int line_number;

    if (argc != 3) {
        printf("Usage: ASMLITE input.asm output.com\r\n");
        return 0;
    }
    input = fopen(argv[1], "rt");
    output = fopen(argv[2], "wb");
    if (input == NULL || output == NULL) {
        printf("Cannot open input or output file.\r\n");
        if (input != NULL) fclose(input);
        if (output != NULL) fclose(output);
        return 1;
    }
    line_number = 0;
    while (fgets(line, sizeof(line), input) != NULL) {
        ++line_number;
        if (!assemble_line(output, line)) {
            printf("Assembly error on line %u.\r\n", line_number);
            fclose(input);
            fclose(output);
            return 1;
        }
    }
    fclose(input);
    fclose(output);
    printf("Assembled %s to %s.\r\n", argv[1], argv[2]);
    return 0;
}
