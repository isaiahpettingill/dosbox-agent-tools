HACKER TOOLS FOR DOS
====================

STRINGS file [minimum]
  Lists printable ASCII runs. Default minimum is 4 characters. Press any key
  at each page; Q stops the listing.

DISASM file[.EXE|.COM]
  Produces a linear 8086 assembly-like listing on standard output. Use DOS
  redirection to save it: DISASM PROGRAM.EXE > PROGRAM.ASM
  It recognizes a useful subset of common 8086 instructions. Unknown bytes
  are emitted as DB directives. The result needs review before reassembly.

SERMON
  Lists BIOS COM1-COM4 addresses, then monitors a selected UART at 9600 8N1.
  Commands: I shows UART status, R drains received bytes, S sends hex bytes,
  Q quits. Example: S 41 54 0D sends "AT" followed by carriage return.

PATCH file hex-offset hex-byte [hex-byte ...]
  Writes bytes in place. Example: PATCH GAME.EXE 1F2 90 90 90
  Make a backup first. Offsets and bytes are hexadecimal without a 0x prefix.

ASMLITE input.asm output.com
  Tiny assembler for COM-sized patches. It supports ORG, DB, NOP, RET, INT,
  MOV register/immediate, PUSH register, and POP register. It is deliberately
  not a replacement for a full assembler.

Source and the MIT license are included on this disk.
