# DOS File Read

Use `INT 21h`, `AH=3Fh` to read from an already-open DOS file handle.

```text
BX    file handle
CX    requested byte count
DS:DX destination buffer

CF clear: AX = bytes actually read
CF set:   AX = DOS error code
```

`AX` may be smaller than `CX` at end of file. A zero-byte successful read is
EOF only when the requested count was nonzero. Do not treat a short result as
an error by itself; advance the buffer and remaining count by `AX` if a caller
needs an exact-length read.

Open the handle first with `INT 21h/AH=3Dh`, and close it with `AH=3Eh`.
`DS:DX` is a real-mode far buffer address, not a flat pointer.

**Citation:** [RBIL INT 21h index](https://www.delorie.com/djgpp/doc/rbinter/ix/21/),
function `AH=3Fh`; [DOS file reference](../dos-reference.md#dos-files-directories-and-dta).
