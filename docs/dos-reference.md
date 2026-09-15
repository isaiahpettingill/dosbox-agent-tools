# DOS And PC Reference

Target: i8086/i8088, 16-bit real mode, MS-DOS-compatible DOS, 80x25 text
mode. Register pairs in this document are high word then low word, so `CX:DX`
is a 32-bit value. Unless stated otherwise, DOS file functions report errors
with CF set and an error code in `AX`.

**Primary citation:** [Ralf Brown's Interrupt List (RBIL), release
61](https://www.delorie.com/djgpp/doc/rbinter/). Each DOS and BIOS function
below is indexed under its interrupt number and `AH` function. This file is a
quick contract, not a replacement for RBIL's version-specific notes.

## Process And Memory

| Operation | Contract |
| --- | --- |
| Normal DOS exit | `INT 21h`, `AH=4Ch`, `AL=process exit code`. Use this from raw assembly; do not assume a language `return` has raw-DOS semantics. |
| Segment:offset | Physical address is normally `segment * 16 + offset`. Multiple segment:offset pairs can address the same byte. Do not increment a far pointer as though it were a flat 32-bit address. |
| Allocate DOS memory | `INT 21h`, `AH=48h`, `BX=paragraphs`; success `AX=segment`. On failure `BX` is the largest available block. A paragraph is 16 bytes. |
| Free DOS memory | `INT 21h`, `AH=49h`, `ES=allocated segment`. |
| Resize DOS memory | `INT 21h`, `AH=4Ah`, `ES=block segment`, `BX=new paragraph count`; on failure `BX` reports the largest possible size. |
| DOS version | `INT 21h`, `AH=30h`; `AL=major`, `AH=minor`. Treat it as compatibility information, not reliable feature detection: SETVER and clones can alter it. |
| Equipment word | `INT 11h`; returns the BIOS equipment flags in `AX`. Decode only the fields needed by a sample. |
| Conventional memory | `INT 12h`; returns conventional memory size in KiB in `AX`. |

### PSP And `.COM` Programs

A DOS `.COM` program is a flat image loaded at offset `0100h`; NASM source
normally starts with `BITS 16` and `ORG 100h`. At initial entry, DOS supplies
`CS`, `DS`, `ES`, and `SS` for the program's PSP segment, with execution at
`CS:0100h`. The image and stack share that 64 KiB segment, so the practical
maximum file image is `65536 - 256 = 65280` bytes and is smaller when it needs
stack or runtime data. `.EXE` startup and segment assumptions are different.

The PSP command tail begins at `PSP:80h`: byte `80h` is the length, characters
start at `81h`, and the tail is terminated by a carriage return. It is neither
NUL-terminated nor an argv array. Use a language runtime's argument API for
ordinary `.EXE` programs; use the PSP deliberately for tiny raw `.COM` tools.

**Citations:** RBIL's `INT 21h/AH=4Ch`, `48h`, `49h`, `4Ah`, and `30h` entries;
RBIL `INT 11h` and `INT 12h`; [NASM `bin` format and `ORG`
documentation](https://www.nasm.us/doc/nasm09.html#section-9.1).

## DOS Console

| Function | Input | Result and caveat |
| --- | --- | --- |
| Write character | `INT 21h`, `AH=02h`, `DL=character` | Writes one character to standard output. |
| Write string | `INT 21h`, `AH=09h`, `DS:DX=$`-terminated string | The terminating `$` is not written. This is not an ASCIIZ string API, so embedded `$` cannot be printed with it. |
| Read with echo | `INT 21h`, `AH=01h` | Waits for a character, echoes it, returns it in `AL`; normal break handling applies. |
| Read without echo | `INT 21h`, `AH=07h` | Waits for a character without echo and does not check Ctrl-C/Ctrl-Break. |
| Read without echo, break-aware | `INT 21h`, `AH=08h` | Waits without echo; normal Ctrl-C/Ctrl-Break handling applies. |
| Buffered line input | `INT 21h`, `AH=0Ah`, `DS:DX=buffer` | Buffer byte 0 is max input length; byte 1 is returned character count excluding CR; bytes 2 onward hold input and the terminating CR. |

Do not apply UTF-8 assumptions to these calls. They deal in single-byte DOS
code-page characters. `AH=01h` and `08h` may invoke the Ctrl-C/Ctrl-Break path
(`INT 23h`); `AH=07h` is the deliberate exception. [RBIL: INT
21h](https://www.delorie.com/djgpp/doc/rbinter/ix/21/).

## Keyboard And Video BIOS

| Operation | Contract |
| --- | --- |
| Wait for key | `INT 16h`, `AH=00h`; returns ASCII in `AL` and scan code in `AH`. Preserve the full `AX` result; extended keys commonly have `AL=00h` (or an enhanced-key prefix). |
| Poll key | `INT 16h`, `AH=01h`; ZF clear means a key is available and `AX` contains it, ZF set means none. It does not remove the key. |
| Set video mode | `INT 10h`, `AH=00h`, `AL=mode`. Mode 03h is the normal 80x25 color text mode. This resets screen state. |
| Set cursor position | `INT 10h`, `AH=02h`, `BH=page`, `DH=row`, `DL=column`. Rows and columns are zero based. |
| Read cursor and shape | `INT 10h`, `AH=03h`, `BH=page`; position returns in `DH:DL`, shape in `CH:CL`. |
| Set cursor shape | `INT 10h`, `AH=01h`, `CH=start scan line`, `CL=end scan line`. Cursor hiding behavior is adapter-dependent; use the BIOS convention documented by RBIL. |
| Scroll or clear window | `INT 10h`, `AH=06h`, `AL=lines` (`0` clears), `BH=attribute`, `CH:CL=upper-left`, `DH:DL=lower-right`. |
| Write repeated cell | `INT 10h`, `AH=09h`, `AL=character`, `BH=page`, `BL=attribute`, `CX=count`. |
| Teletype output | `INT 10h`, `AH=0Eh`, `AL=character`, `BH=page` and, on graphics adapters, `BL=color`. It advances the cursor and handles control characters. |

**Citation:** [RBIL: INT 10h](https://www.delorie.com/djgpp/doc/rbinter/ix/10/)
and [RBIL: INT 16h](https://www.delorie.com/djgpp/doc/rbinter/ix/16/).

## Direct Text Video

Color text memory starts at `B800:0000`; monochrome text memory starts at
`B000:0000`. In an 80-column text mode, each cell is two bytes: character then
attribute. For zero-based `row` and `column`, the byte offset is:

```text
(row * 80 + column) * 2
```

Use the current mode and adapter deliberately. Direct `B800h` writes are right
for a color-text TUI, but are not a universal terminal abstraction and are
wrong for a monochrome adapter or a non-text mode.

The conventional color attribute byte is:

```text
bit 7      blink, or high-intensity background when blink is disabled
bits 6..4  background color (0..7)
bits 3..0  foreground color (0..15; bit 3 is intensity)
```

The blink-versus-bright-background interpretation depends on adapter state;
do not assume bit 7 is always a background intensity bit.

**Citations:** RBIL `INT 10h` text-mode notes; IBM PC/AT Technical Reference,
[Video Subsystem and Adapter](http://www.bitsavers.org/pdf/ibm/pc/at/1502243_Technical_Reference_Mar84.pdf);
[OSDev VGA hardware overview](https://wiki.osdev.org/VGA_Hardware).

## DOS Files, Directories, And DTA

All file path arguments below are `DS:DX` ASCIIZ strings unless noted.

| Operation | Contract |
| --- | --- |
| Open | `INT 21h`, `AH=3Dh`, `AL=0` read, `1` write, `2` read/write; returns handle in `AX`. |
| Create/truncate | `INT 21h`, `AH=3Ch`, `CX=attribute bits`; returns handle in `AX`. |
| Read | `INT 21h`, `AH=3Fh`, `BX=handle`, `CX=requested bytes`, `DS:DX=buffer`; `AX=bytes actually read`, including a short read at EOF. |
| Write | `INT 21h`, `AH=40h`, `BX=handle`, `CX=bytes`, `DS:DX=buffer`; `AX=bytes actually written`. A short write is not success. |
| Seek | `INT 21h`, `AH=42h`, `AL=0` start, `1` current, `2` end; signed offset in `CX:DX`; returns absolute position in `DX:AX`. |
| Close | `INT 21h`, `AH=3Eh`, `BX=handle`. |
| Delete | `INT 21h`, `AH=41h`, `DS:DX=path`. |
| Rename | `INT 21h`, `AH=56h`, `DS:DX=old path`, `ES:DI=new path`. |
| Get/set attributes | `INT 21h`, `AH=43h`; `AL=0` gets attributes in `CX`, `AL=1` sets attributes from `CX`. |
| Change directory | `INT 21h`, `AH=3Bh`, `DS:DX=path`. |
| Get current directory | `INT 21h`, `AH=47h`, `DL=drive` (`0` default), `DS:SI=buffer`. The returned path has no drive prefix. |
| Set default drive | `INT 21h`, `AH=0Eh`, `DL=0` for A:, `1` for B:, etc.; `AL` returns drive count. |
| Get default drive | `INT 21h`, `AH=19h`; `AL=0` for A:, etc. |
| Free space | `INT 21h`, `AH=36h`, `DL=drive`; `AX=FFFFh` is invalid drive, otherwise use `AX*CX*BX` for free bytes. |

### Directory Enumeration

The Disk Transfer Area (DTA) is process-global state used by find-first/next.

| Operation | Contract |
| --- | --- |
| Set DTA | `INT 21h`, `AH=1Ah`, `DS:DX=new DTA`. Supply at least the conventional 43-byte DTA. |
| Get DTA | `INT 21h`, `AH=2Fh`; returns `ES:BX`. |
| Find first | `INT 21h`, `AH=4Eh`, `CX=attribute mask`, `DS:DX=pattern`; fills current DTA. |
| Find next | `INT 21h`, `AH=4Fh`; consumes and replaces the current DTA result. |

Set a private DTA before enumeration, leave it valid until `FindNext` finishes,
then restore the old DTA. Any DOS call or library routine that changes the DTA
between first and next can corrupt the search state.

**Citation:** [RBIL: INT 21h](https://www.delorie.com/djgpp/doc/rbinter/ix/21/),
especially functions `1Ah`, `2Fh`, `3Ch` through `43h`, `47h`, and `4Eh/4Fh`.

## Time, Errors, And Drives

| Operation | Contract |
| --- | --- |
| DOS date | `INT 21h`, `AH=2Ah`; returns `CX=year`, `DH=month`, `DL=day`, `AL=weekday`. |
| DOS time | `INT 21h`, `AH=2Ch`; returns `CH=hour`, `CL=minute`, `DH=second`, `DL=hundredths`. |
| BIOS ticks | `INT 1Ah`, `AH=00h`; returns tick count since midnight in `CX:DX`, rollover indicator in `AL`. The rate is about 18.2065 Hz. |
| Critical error | `INT 24h` is DOS's critical-error callback. Hooking it needs a dedicated, tested handler that follows its return-action contract and restores the prior vector. |

Use the BIOS tick count as a coarse timer or a non-cryptographic seed only. It
is not a millisecond clock, and rollover handling matters.

**Citation:** [RBIL: INT 1Ah](https://www.delorie.com/djgpp/doc/rbinter/ix/1a/)
and [RBIL: INT 21h](https://www.delorie.com/djgpp/doc/rbinter/ix/21/).

## Ports, Serial, PIT, And Speaker

Raw port I/O requires a real PC-compatible environment. It may be unavailable,
virtualized, or unsafe under emulators and protected environments.

| Hardware | Contract |
| --- | --- |
| COM1 / COM2 base | Conventional bases are `3F8h` and `2F8h`; prefer BIOS data-area discovery when hardware compatibility matters. |
| UART data register | RBR (read) and THR (write) are base `+0`. |
| UART line-status | LSR is base `+5`; bit 5 means THR empty and is the usual polling condition before writing. |
| UART setup | Disable interrupts at base `+1`; set LCR (base `+3`) bit 7 (DLAB); write divisor low to `+0`, high to `+1`; clear DLAB and set line format (for 8N1, `03h`). Set modem control as needed, commonly DTR/RTS/OUT2. |
| PIT | Channel data ports are `40h`, `41h`, `42h`; command port is `43h`. Channel 0 drives the system tick. |
| PC speaker | Program PIT channel 2, then use port `61h`: bit 0 gates channel 2 and bit 1 enables the speaker. Preserve unrelated port bits and restore the prior state. |

The PIT input clock is approximately 1,193,182 Hz. A speaker-tone divisor is
therefore approximately `1193182 / requested_hz`; reject a zero divisor and
restore channel/speaker state afterward.

**Citations:** RBIL port and timer notes; IBM PC/AT Technical Reference,
[8253/8254 timer and serial adapter sections](http://www.bitsavers.org/pdf/ibm/pc/at/1502243_Technical_Reference_Mar84.pdf);
[Intel Software Developer's Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
for `IN` and `OUT` instruction semantics.

## Before Writing A Sample

1. Check the matching compiler cheat sheet and nearest existing sample.
2. Use a DOS or BIOS interrupt only after confirming the function's exact
   RBIL entry, including carry-flag errors and register preservation notes.
3. Keep raw interrupt, DTA, ISR, and port-I/O examples minimal and test them
   under the declared DOS runner before marking them verified.
