# PC Speaker Tone

The PC speaker uses PIT channel 2 and port `61h`. The PIT clock is
approximately 1,193,182 Hz, so the channel-2 divisor for a requested tone is
approximately:

```text
divisor = 1193182 / frequency_hz
```

Program channel 2 through data port `42h` and command port `43h`, then set
bits 0 and 1 at port `61h` to gate channel 2 and enable the speaker. Read and
preserve the other port-61h bits. To stop the tone, restore the saved port-61h
state; do not leave the speaker enabled after a program exits.

Reject zero/invalid divisors, keep the tone loop interrupt-friendly, and test
on the declared runner. The BIOS tick clock is separate: `INT 1Ah/AH=00h`
returns a coarse `CX:DX` count at approximately 18.2065 Hz.

**Citation:** [PIT, speaker, and BIOS tick reference](../dos-reference.md#ports-serial-pit-and-speaker)
and [time reference](../dos-reference.md#time-errors-and-drives); [IBM PC/AT
Technical Reference](http://www.bitsavers.org/pdf/ibm/pc/at/1502243_Technical_Reference_Mar84.pdf).
