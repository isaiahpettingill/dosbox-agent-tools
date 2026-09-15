# DOS Reference Notes

These are concise reference notes for the 8086 real-mode DOS target. They are
not verified samples and do not replace compiler-matched examples under
`samples/`. They exist to make register contracts, memory layouts, and
compiler interfaces easy to find before writing code.

- [DOS and PC reference](dos-reference.md): interrupt contracts, video memory,
  files, DOS process details, and PC hardware ports.
- [Compiler cheat sheets](compiler-cheatsheets.md): Open Watcom, Free Pascal,
  NASM, and Trubo Oberon interfaces.

## One-Operation Notes

- [DOS file read](operations/dos-file-read.md)
- [BIOS keyboard poll](operations/bios-keyboard-poll.md)
- [B800 text cell](operations/b800-put-cell.md)
- [PSP command line](operations/psp-command-line.md)
- [COM1 byte write](operations/com1-write-byte.md)
- [PC speaker tone](operations/pc-speaker-tone.md)

## Sources

The DOS and BIOS contracts are primarily drawn from [Ralf Brown's Interrupt
List, release 61](https://www.delorie.com/djgpp/doc/rbinter/), indexed by
interrupt and function. The list is a historical reference; target DOS
versions and emulators can have extensions or quirks.

Compiler-specific material is cited in the relevant cheat sheet. Consult the
upstream source before relying on an undocumented extension or on hardware
that is optional on a real PC.
