# Hacker Tools

A 360 KiB 8086 real-mode DOS utility floppy. It contains a paginated printable
string scanner, a small MZ EXE/COM linear disassembler, an interactive COM port
monitor, a binary patcher, and a compact COM assembler. The source and MIT
license are included on the image.

`DISASM.EXE` emits assembly-like output for manual analysis; it is not a
high-level language decompiler and does not reconstruct labels, data, or DOS
relocations. `ASMLITE.EXE` supports `DB`, `NOP`, `RET`, `INT`, `MOV` immediate,
`PUSH`, and `POP`, so it is useful for tiny patches rather than general builds.

Build with `make build`, run deterministic command-line smoke tests with `make
test`, and create the FAT12 image with `make image`. `SERMON.EXE` needs a real
or emulated UART and is tested interactively.
