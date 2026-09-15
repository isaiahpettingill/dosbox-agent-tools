# Magic 8 Ball

A colored 80x25 text-mode Magic 8 Ball for i8086-compatible DOS machines,
written in Open Watcom C. Type twelve arbitrary keys to shake the oracle. Each
keypress is mixed with a latched 8253/PIT timer cycle count using prime
multipliers before an answer is selected.

The screen fills with changing colored ASCII noise while it shakes, then shows
a large `8` and an answer. Press `Enter` to shake again or `Q` to quit. Extra
shake keys are discarded before the answer screen accepts input.

Use `make build`, `make test`, or `make image`. The focused test verifies the
seed mixing and answer range through NTVDM; inspect the interactive screen in
DOSBox Automation when its behavior changes.
