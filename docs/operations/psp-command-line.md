# PSP Command Line

For a raw DOS `.COM` utility, the command tail lives in the program segment
prefix (PSP), not in an argv array.

```text
PSP:80h  one-byte tail length
PSP:81h  tail characters
PSP:81h + length  carriage return (0Dh)
```

The characters are not NUL-terminated. Copy at most the length byte into a
buffer and add a terminator only if the target routine needs one. The tail
normally includes the space between the program name and the first argument.

For a `.COM` program, source uses `ORG 100h`; the program image begins after
the 256-byte PSP. Do not transplant this layout into an `.EXE` startup routine
without checking its runtime's PSP access method.

**Citation:** [RBIL INT 21h index](https://www.delorie.com/djgpp/doc/rbinter/ix/21/)
and DOS PSP notes; [NASM `ORG` documentation](https://www.nasm.us/doc/nasm09.html#section-9.1.1);
[process and memory reference](../dos-reference.md#psp-and-com-programs).
