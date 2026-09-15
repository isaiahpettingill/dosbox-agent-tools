# Compiler Cheat Sheets

These interfaces are toolchain-specific. Prefer the project wrapper Makefiles,
then confirm the installed toolchain version before adding a reusable sample.

## Open Watcom C

The repository default is `wcl -q -bt=dos -lr -ms -0`: DOS target, runtime
library, small memory model, and 8086/8088 instructions. The `-0` option is
the explicit CPU guard; `-ms` makes ordinary code and data near within the
small model.

| Need | Open Watcom interface |
| --- | --- |
| Far pointer construction/decomposition | `MK_FP(segment, offset)`, `FP_SEG(pointer)`, `FP_OFF(pointer)` from the Watcom DOS headers. Keep the result in a far-pointer type. |
| BIOS/DOS interrupt | `union REGS`, `struct SREGS`, `int86`, and `int86x`; populate all documented registers, then check returned flags/registers. |
| Port I/O | `inp`, `inpw`, `outp`, `outpw`; use only after validating the target port and hardware contract. |
| Console/keyboard helpers | `kbhit`, `getch`, `putch` from the DOS console headers. `getch` is not a replacement for a BIOS scan-code API when function or extended keys matter. |
| Memory-distance keyword | `far` and `near` are 16-bit memory-model tools. Do not add them without a segment ownership reason. |
| Video memory | Use a far pointer made from `MK_FP(0xB800, 0)` for color text memory; see [DOS direct text video](dos-reference.md#direct-text-video). |

The exact headers can vary by interface (`<dos.h>`, `<conio.h>`, and Watcom's
8086 headers). Include the header declaring the helper rather than recreating
the prototype.

**Citations:** [Open Watcom C/C++ User's Guide](https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html), especially 16-bit memory models, assembly-language considerations, and options `-0`, `-ms`, and `-bt`; the Open Watcom headers installed in the project's container image.

## Free Pascal i8086/MS-DOS

The wrapper invokes `ppcross8086 -Tmsdos -WmSmall`. Treat language facilities
as target-dependent: a symbol documented for another FPC DOS target is not
proof that it exists or behaves the same for i8086 MS-DOS.

| Need | Preferred interface |
| --- | --- |
| DOS-compatible files, directories, dates | `Dos` unit. It is the Turbo Pascal compatibility interface for DOS file-system and date/time calls. |
| Text UI and keyboard | `Crt` unit for simple single-byte text/keyboard programs; Free Vision for structured interactive applications. Neither is suitable for redirected standard I/O. |
| Absolute storage | `absolute` declarations are useful for fixed DOS/BIOS addresses, but require an explicit segment/offset and a documented target layout. |
| Interrupts and registers | Use the i8086/MS-DOS RTL's supported interrupt/register API only after compiling a minimal sample. Do not copy `Intr`, `Mem[]`, or `Port[]` syntax from a Go32/DPMI or another FPC target without checking this target. |
| Far access and ports | Prefer a small NASM helper when the i8086 RTL interface is not confirmed. Keep the ABI and memory model documented at the call boundary. |

The generic FPC `Mem` documentation currently describes a Go32V2-only
facility, not this repository's i8086 target. That is specifically not a
license to use `Mem[segment:offset]` here without a verified i8086 example.

**Citations:** [FPC `Dos` unit reference](https://www.freepascal.org/docs-html/rtl/dos/index.html), [FPC `Crt` unit reference](https://www.freepascal.org/docs-html/rtl/crt/index.html), and [FPC `Mem` reference](https://www.freepascal.org/docs-html/rtl/system/mem.html). The latter documents its Go32V2 restriction.

## NASM

For a plain DOS `.COM` program:

```nasm
cpu 8086
bits 16
org 100h
```

Assemble it with `nasm -f bin -o PROGRAM.COM PROGRAM.ASM`. `CPU 8086` is an
important guard against accidentally using a newer opcode. `BITS 16` controls
default operand/address sizes; it is not a CPU feature selector.

| Need | NASM form |
| --- | --- |
| DOS/BIOS call | Load documented registers, then `int 21h`, `int 10h`, `int 16h`, and so on. |
| Port I/O | `in al, dx`, `out dx, al` or immediate-port forms, with the port contract documented. |
| Segment access | Use explicit segment overrides such as `[es:di]` when a routine needs a segment other than NASM's default. |
| Load far pointer | `les di, [pointer]` and `lds si, [pointer]` load offset and segment together from a memory-resident far pointer. Use the correct `{offset, segment}` word order. |
| Far control transfer | `call far [pointer]`, `jmp far [pointer]`, or an explicitly encoded far immediate form as appropriate. Near and far returns are different: `ret` versus `retf`. |
| Block copy | `rep movsb` / `rep movsw` use `DS:SI` source, `ES:DI` destination, and `CX` count. Save/restore segment registers deliberately. |
| Mixed objects | NASM `-f rdf` produces RDOFF2 for Trubo Oberon interoperability; use the compiler's documented external-object ABI. |

**Citations:** [NASM directives: `BITS`, `CPU`, and `SECTION`](https://www.nasm.us/doc/nasm08.html); [NASM `bin`, `ORG`, and OMF output formats](https://www.nasm.us/doc/nasm09.html#section-9.1); [DOS process and memory notes](dos-reference.md#process-and-memory).

## Trubo Oberon

Trubo Oberon is a DOS-native, 8086-targeting compiler with a deliberately
different model from FPC and Open Watcom. Its default is a large memory model;
do not assume `CS`, `DS`, and `SS` coincide.

| Need | Trubo interface |
| --- | --- |
| Far addresses | `SYSTEM.ADR`, `SYSTEM.SEG`, `SYSTEM.OFS`, and `SYSTEM.PTR`. A `SYSTEM.ADDRESS` is a far value; its offset and segment must both be preserved. |
| Memory transfer | `SYSTEM.MOVE` and `SYSTEM.FILL`; typed pointers dereference with `^`. |
| Port I/O | `SYSTEM.PORTIN(port)` and `SYSTEM.PORTOUT(port, byte)`. |
| BIOS/DOS interrupt | Fill `SYSTEM.Registers`, including `DS` and `ES`, then call `SYSTEM.Intr`. The runtime loads both segment registers from the record. |
| Entry point | Export an entry procedure and build with `/ENTRY=Run`; the runtime initializes imports before it invokes it. |
| Strings/output | `Out.String`, `Out.Char`, `Out.Ln`; strings are arrays of `CHAR`, not C `$` or NUL-terminated pointers. |
| DOS files/screen/keyboard | `Files`, `Dos`, `Crt`, `KMouse`, and `Screen` are standard-library modules. Prefer them before raw calls. |
| NASM interoperability | Assemble RDOFF2 with NASM `-f rdf`, declare Oberon externals, and link them with the documented `$L` mechanism and calling convention. |

**Citation:** [Trubo Oberon Manual](https://github.com/DosWorld/toc/blob/master/MANUAL.MD), sections `SYSTEM`, `SYSTEM.Registers and SYSTEM.Intr`, compiling/linking, the standard library, and RDOFF2 interoperability. The manual documents a large memory model and far-pointer layout; it is authoritative over analogies to C or Pascal.
