# B800 Text Cell

Color 80x25 text memory begins at `B800:0000`. Each screen cell is two bytes:
the character byte followed by its attribute byte.

```text
cell_offset = (row * 80 + column) * 2
B800:cell_offset     = character
B800:cell_offset + 1 = attribute
```

`row` and `column` are zero based. Check bounds before calculating the offset:
valid positions are rows `0..24` and columns `0..79` for the default mode.
The normal attribute layout is foreground in bits `0..3`, background in bits
`4..6`, and blink or high-background behavior in bit `7`.

This is color video memory. A monochrome adapter uses `B000:0000`; direct
writes are wrong in graphics modes and should not replace BIOS text output for
generic display compatibility.

**Citation:** [DOS direct text-video reference](../dos-reference.md#direct-text-video);
[IBM PC/AT Technical Reference](http://www.bitsavers.org/pdf/ibm/pc/at/1502243_Technical_Reference_Mar84.pdf).
