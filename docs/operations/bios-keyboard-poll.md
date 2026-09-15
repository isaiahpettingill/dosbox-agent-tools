# BIOS Keyboard Poll

Use `INT 16h`, `AH=01h` to test whether a BIOS keyboard keystroke is waiting.

```text
AH = 01h
INT 16h

ZF clear: key available; AH = scan code, AL = ASCII/extended indication
ZF set:   no key available
```

The call does not remove the waiting key. To consume it, use `INT 16h`,
`AH=00h`, which waits if necessary and returns the same `AH:AL` pair. Preserve
both bytes: extended keys commonly use an ASCII byte of zero, while the scan
code identifies the key.

Use BIOS keyboard services when scan codes or function keys matter. DOS
character input (`INT 21h`) has different echo and Ctrl-C behavior.

**Citation:** [RBIL INT 16h index](https://www.delorie.com/djgpp/doc/rbinter/ix/16/);
[keyboard and console reference](../dos-reference.md#keyboard-and-video-bios).
