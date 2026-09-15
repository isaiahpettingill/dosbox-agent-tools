# Purpose

These instructions govern the DOS development workspace (`containers/`,
`toolchains/`, `floppies/`, `libs/`, `samples/`, and its reference docs).
The root PowerShell module and setup scripts provide the host-side REST
client; follow the root README for their PowerShell 7 requirements.

This repository is a small monorepo for building 16-bit real-mode DOS software
and floppy-disk images with coding-agent assistance.

It is centered on self-contained projects in `floppies/`, reusable DOS compiler
tooling, small shared libraries, successful examples in `samples/`, and
containerized modern-Linux tooling. Keep it simple: do not add a database, RAG
service, general-purpose build framework, VM orchestration layer, or custom
agent harness unless plain files and Makefiles have demonstrably stopped
working.

The host requires only `make` and a Docker-compatible container engine such as
Podman or Docker. Everything else runs in containers.

# Target Platform

The default target is MS-DOS compatible, i8086/i8088, 16-bit real mode, and
80x25 text mode. Do not silently introduce 286+ instructions, protected mode,
DPMI, DOS extenders, DOS/4GW, Win16/Win32, or Linux/POSIX runtime dependencies.
A project may explicitly opt into another target, but plain real-mode 8086 DOS
is the repository default.

# Toolchains And Execution

The initial toolchains are Open Watcom v2 C, Free Pascal i8086/MS-DOS, NASM,
and Trubo Oberon. Open Watcom is the default C compiler; Free Pascal is the
default Pascal compiler and may use Free Vision. NASM is for `.COM` programs,
interrupts, BIOS/DOS I/O, and low-level helpers. Trubo Oberon is the first
DOS-native historical compiler.

Turbo Pascal 7 and Microsoft FORTRAN 5 have dedicated container wrappers,
with a verified hello-world sample and an ANOVA calculator respectively.
Use their toolchain READMEs for the historical compiler setup.

Do not add other historical compilers from `davidly/dos_compilers` until an
actual floppy or sample needs one.

There are two normal execution paths:

- Use NTVDM in Docker for DOS compilers, command-line utilities, quick smoke
  tests, simple applications, and fast compile/run iteration.
- Use DOSBox Automation in Docker for interactive text-mode programs,
  keyboard-driven tests, screen-state inspection, and historical workflows.

Prefer DOSBox Automation's text-screen automation interface over screenshots.
Do not add QEMU to the normal workflow. Do not use official DOSBox binaries:
`containers/dosbox-automation/Containerfile` builds the
`dosbox-automation/dosbox-automation` repository from source.

Modern Linux tooling belongs in a container, including compilers, assemblers,
emulators, FAT tools, and asset conversion. Makefiles may orchestrate Podman
or Docker; they must not invoke a host-installed compiler or disk-image tool.

# Layout

```text
containers/        Docker images for compilers, runners, and FAT tools
toolchains/        Docker-backed compiler and image commands
libs/              Small code reused by at least two consumers
samples/           Searchable, verified DOS techniques
floppies/<name>/   Independently buildable DOS disk projects
```

Every floppy contains a `Makefile`, `README.md`, `src/`, `assets/`, `files/`,
and generated `build/`. Generated output belongs in `build/` or `dist/` and is
not committed without a specific reason.

# Makefile Contracts

The root Makefile has a deliberately small stable interface:

```text
make images
make samples
make floppies
make floppy NAME=<name>
make clean
```

`make images` builds every Docker image. `make samples` builds every sample.
`make floppies` creates every floppy image. `make floppy NAME=typing` creates
one image.

Each `floppies/<name>/Makefile` provides:

```text
make build
make test
make image
make clean
```

`build` compiles programs, `test` performs useful smoke or interactive tests,
`image` creates the final FAT12 image, and `clean` removes generated output.
Keep Makefiles declarative; put complicated build behavior in an image or a
small helper that executes in a container.

# Floppy Images

Use the `floppy-tools` image for image creation, formatting, copying, listing,
and size checks. Supported sizes are 360 KiB, 720 KiB, and 1.44 MiB. Every
project declares its size, for example:

```make
FLOPPY_SIZE := 360
IMAGE := build/ORACLE.IMG
```

FAT12 images are made with mtools. The copy operation must fail if content does
not fit. Prefer deterministic builds where practical.

# Compiler Defaults

Toolchain Makefiles mount the caller's project at `/work`; projects must not
know container installation paths.

- Open Watcom defaults to `wcl -q -bt=dos -lr -ms -0`: 16-bit DOS real mode,
  i8086, small memory model.
- Free Pascal targets i8086 MS-DOS with the small memory model.
- NASM DOS sources normally use `bits 16`; `.COM` programs also use `org 100h`
  and normally assemble with `-f bin`.
- Trubo Oberon runs as a DOS-native compiler through NTVDM. Keep its DOS
  environment and library path details in `toolchains/trubo-oberon/`.

# Samples Are The Knowledge Base

There is no RAG system. Learn repository-specific DOS techniques from files in
`samples/`, `libs/`, `docs/`, toolchain READMEs, and floppy projects. Search
with `rg`, `find`, or `git grep` before inventing unfamiliar DOS code. Read the
nearest sample README before copying it and prefer examples for the active
compiler. Use cited docs to confirm interrupt and hardware contracts, but do
not mark a technique verified until its sample compiles and executes.

Each reusable successful example has its own directory, such as
`samples/text/openwatcom-direct-b800/`. Its `README.md` begins with TOML
Markdown frontmatter:

```toml
+++
id = "openwatcom-direct-b800"
category = "text/video"
language = "c"
compiler = "openwatcom-v2"
target = "dos-real-mode"
cpu = "i8086"
memory_model = "small"
verified = true
verified_with = ["ntvdm"]
tags = ["b800", "video-memory", "text-mode", "80x25"]
behaviors = ["write-character-cell", "write-attribute-byte"]
+++
```

Document what it does, why it is useful, DOS/compiler constraints, how to
build it, and how it was verified. Use useful synonyms naturally: a B800 sample
should mention video memory, VRAM, screen memory, text buffer, `B800:0000`,
direct screen writes, and 80x25 text mode. This lexical detail makes ordinary
search work without an index.

Start categories with `text`, `keyboard`, `files`, `bios`, `interrupts`,
`serial`, `tui`, `freevision`, `memory`, `timing`, `random`, `process`, and
`misc`. Add categories only when they are needed.

# Promote Verified Work

When a reusable DOS technique succeeds, promote the smallest useful version to
`samples/`:

1. Reduce it to the minimal useful example.
2. Give it a descriptive directory name and small Makefile.
3. Add a README with TOML frontmatter and searchable terminology.
4. Build with its declared compiler.
5. Execute it with NTVDM or DOSBox Automation.
6. Set `verified = true` only after it works.

Good candidates include keyboard polling, function keys, direct B800 output,
BIOS cursor movement, DOS files, far pointers, COM1, interrupt hooks, simple
menus, text inputs, and Free Vision dialogs. Do not promote every generated
program; samples teach reusable techniques.

# Shared Libraries

Build shared libraries gradually from repeated, successful samples. Use small
modules in `libs/c/`, `libs/pascal/`, `libs/asm/`, or `libs/oberon/`; C source
and headers, Pascal units, Oberon modules, and documented NASM includes are
preferred. Do not make a cross-language framework.

Move a routine into `libs/` only after at least two projects or samples need
it. Libraries remain 8086-safe unless their README/frontmatter clearly states
otherwise.

# Interactive Tests

Keep DOSBox Automation tests focused. A test may launch an executable, wait for
known text, send a key, and verify the next text screen. Prefer deterministic
seeds or stable assertions where behavior is random. A small script running in
the DOSBox Automation container is sufficient; do not create a test framework.

# Agent Rules

When working here:

- Read this file first and identify the changed floppy, sample, library, or
  tooling component.
- Identify the compiler before writing compiler-specific code.
- Assume 8086 real mode unless the project explicitly says otherwise.
- Search samples and libraries before inventing DOS-specific mechanisms.
- Reuse an existing small library, but do not introduce an abstraction for one
  use.
- Build through Makefiles and containerized tooling only.
- Use NTVDM for quick execution; use DOSBox Automation when interactive screen
  state matters.
- Keep generated files in `build/` or `dist/`.
- Promote minimal verified techniques into samples.
- Never mark a sample verified without compiling and executing it.
- Keep documentation short, factual, and searchable.
- Prefer a working small DOS program over generalized infrastructure.

Favor small executables, few dependencies, text-mode interaction, predictable
memory use, plain APIs, and obvious control flow. BIOS, DOS interrupts, and
direct video memory are acceptable when appropriate; document
compiler-specific behavior.

# Definition Of Done

A floppy is done when it builds through its Makefile, all modern tooling is
containerized, its DOS executable runs through NTVDM or DOSBox Automation,
important interactive behavior has been checked, its FAT12 image builds and
contains the intended files, and no undeclared host tool is required.

A sample is done when it demonstrates one reusable behavior, has searchable
frontmatter, builds through Make, executes successfully, and its `verified`
field accurately records that verification.

Keep the repository centered on shipping weird little DOS floppies, not on
building infrastructure for its own sake.
