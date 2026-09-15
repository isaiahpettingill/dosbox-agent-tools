# COM1 Byte Write

The conventional COM1 base port is `3F8h`. Its transmitter holding register
(THR) is at base `+0`; the line-status register (LSR) is at base `+5`.

```text
wait until (IN(3FDh) AND 20h) <> 0  ; LSR bit 5: THR empty
OUT 3F8h, byte                       ; write THR
```

This assumes a UART has already been initialized. A minimal initialization
disables UART interrupts, sets DLAB in LCR (`+3`), writes the low/high divisor
to `+0/+1`, then clears DLAB and writes the line format. `03h` in LCR selects
8 data bits, no parity, one stop bit (8N1).

`3F8h` is a historical conventional base, not a guarantee. For hardware
compatibility, discover ports through BIOS data before touching them. Under an
emulator, port access may be virtualized or absent.

**Citation:** [PC serial and port reference](../dos-reference.md#ports-serial-pit-and-speaker);
[IBM PC/AT Technical Reference](http://www.bitsavers.org/pdf/ibm/pc/at/1502243_Technical_Reference_Mar84.pdf);
[Intel SDM](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html).
