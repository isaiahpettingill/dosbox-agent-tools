#include <stdio.h>
static const char *word_registers[] = {
    "ax", "cx", "dx", "bx", "sp", "bp", "si", "di"
};
static const char *byte_registers[] = {
    "al", "cl", "dl", "bl", "ah", "ch", "dh", "bh"
};

static unsigned int read_word(FILE *input)
{
    unsigned int low;
    unsigned int high;

    low = (unsigned int)fgetc(input);
    high = (unsigned int)fgetc(input);
    return low | (high << 8);
}

static int read_byte(FILE *input)
{
    return fgetc(input);
}

static void emit_byte(unsigned long address, int value)
{
    printf("loc_%04lX: db %02Xh\n", address, value & 0xff);
}

static void disassemble(FILE *input, unsigned long image_size)
{
    unsigned long address;
    int opcode;
    int argument;
    unsigned int word;

    address = 0;
    while (address < image_size && (opcode = read_byte(input)) != EOF) {
        ++address;
        if (opcode == 0x90) {
            printf("loc_%04lX: nop\n", address - 1);
        } else if (opcode == 0xc3) {
            printf("loc_%04lX: ret\n", address - 1);
        } else if (opcode == 0xcb) {
            printf("loc_%04lX: retf\n", address - 1);
        } else if (opcode == 0xcc) {
            printf("loc_%04lX: int 03h\n", address - 1);
        } else if (opcode == 0xcd && address < image_size &&
                   (argument = read_byte(input)) != EOF) {
            printf("loc_%04lX: int %02Xh\n", address - 1, argument & 0xff);
            ++address;
        } else if (opcode >= 0x40 && opcode <= 0x47) {
            printf("loc_%04lX: inc %s\n", address - 1, word_registers[opcode - 0x40]);
        } else if (opcode >= 0x48 && opcode <= 0x4f) {
            printf("loc_%04lX: dec %s\n", address - 1, word_registers[opcode - 0x48]);
        } else if (opcode >= 0x50 && opcode <= 0x57) {
            printf("loc_%04lX: push %s\n", address - 1, word_registers[opcode - 0x50]);
        } else if (opcode >= 0x58 && opcode <= 0x5f) {
            printf("loc_%04lX: pop %s\n", address - 1, word_registers[opcode - 0x58]);
        } else if (opcode >= 0xb0 && opcode <= 0xb7 && address < image_size &&
                   (argument = read_byte(input)) != EOF) {
            printf("loc_%04lX: mov %s, %02Xh\n", address - 1,
                byte_registers[opcode - 0xb0], argument & 0xff);
            ++address;
        } else if (opcode >= 0xb8 && opcode <= 0xbf && address + 1 < image_size) {
            word = read_word(input);
            printf("loc_%04lX: mov %s, %04Xh\n", address - 1,
                word_registers[opcode - 0xb8], word);
            address += 2;
        } else if (opcode == 0xe8 && address + 1 < image_size) {
            word = read_word(input);
            printf("loc_%04lX: call loc_%04lX\n", address - 1,
                address + 2 + (long)(short)word);
            address += 2;
        } else if (opcode == 0xe9 && address + 1 < image_size) {
            word = read_word(input);
            printf("loc_%04lX: jmp loc_%04lX\n", address - 1,
                address + 2 + (long)(short)word);
            address += 2;
        } else if (opcode == 0xeb && address < image_size &&
                   (argument = read_byte(input)) != EOF) {
            printf("loc_%04lX: jmp loc_%04lX\n", address - 1,
                address + 1 + (long)(signed char)argument);
            ++address;
        } else if (opcode >= 0x70 && opcode <= 0x7f && address < image_size &&
                   (argument = read_byte(input)) != EOF) {
            static const char *conditions[] = {
                "jo", "jno", "jb", "jnb", "jz", "jnz", "jbe", "ja",
                "js", "jns", "jp", "jnp", "jl", "jge", "jle", "jg"
            };
            printf("loc_%04lX: %s loc_%04lX\n", address - 1, conditions[opcode - 0x70],
                address + 1 + (long)(signed char)argument);
            ++address;
        } else {
            emit_byte(address - 1, opcode);
        }
    }
}

int main(int argc, char *argv[])
{
    FILE *input;
    unsigned char header[28];
    unsigned long header_size;
    unsigned int entry_ip;
    unsigned int entry_cs;
    unsigned long file_size;
    unsigned long image_size;

    if (argc != 2) {
        printf("Usage: DISASM file.EXE|file.COM > listing.asm\r\n");
        return 0;
    }
    input = fopen(argv[1], "rb");
    if (input == NULL) {
        printf("Cannot open %s.\r\n", argv[1]);
        return 1;
    }
    fseek(input, 0L, SEEK_END);
    file_size = (unsigned long)ftell(input);
    rewind(input);
    if (fread(header, 1, sizeof(header), input) == sizeof(header) &&
        header[0] == 'M' && header[1] == 'Z') {
        header_size = ((unsigned long)header[8] | ((unsigned long)header[9] << 8)) * 16;
        entry_ip = (unsigned int)header[20] | ((unsigned int)header[21] << 8);
        entry_cs = (unsigned int)header[22] | ((unsigned int)header[23] << 8);
        if (header_size >= file_size) {
            printf("Invalid MZ header.\r\n");
            fclose(input);
            return 1;
        }
        printf("; Linear MZ image from %s\n", argv[1]);
        printf("; Entry point %04X:%04X, relocations are not applied\n", entry_cs, entry_ip);
        printf("org 0h\n\n");
        fseek(input, (long)header_size, SEEK_SET);
        image_size = file_size - header_size;
    } else {
        printf("; Linear COM or raw image from %s\norg 100h\n\n", argv[1]);
        rewind(input);
        image_size = file_size;
    }
    disassemble(input, image_size);
    fclose(input);
    return 0;
}
