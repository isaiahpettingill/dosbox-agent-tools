# DOS development workflow

Run Make from Linux or WSL with Docker or Podman available. On a fresh clone,
initialize the pinned dependencies with `git submodule update --init --recursive`.
`make images` builds missing compiler, emulator, asset, and floppy-tool images.
Use `CONTAINER_ENGINE=docker` on each Make invocation to select Docker explicitly.

## Agent prompt

Start with `AGENTS.md`, the relevant compiler README under `toolchains/`, and
the nearest DOS reference or verified sample. A useful task prompt is:

> Create a self-contained novelty floppy under floppies/. Target 8086 real-mode
> DOS and 80x25 text. Use Open Watcom C or Free Pascal, with all compilation and
> image creation in containers. Provide build, test, image, and clean targets.
> Test deterministic behavior through NTVDM and interactive keyboard/screen
> behavior through DOSBox Automation. Document exactly what was verified.
> Promote reusable successful techniques to small searchable samples.

The [Turbo Pascal hello-world](../samples/misc/turbopascal-hello/README.md)
sample compiles with the actual DOS compiler from `dos_compilers` and checks
the output under NTVDM. Other categories are placeholders; never treat an
empty category as evidence of verification.

## Build and run

```sh
make floppy NAME=magic8
make -C floppies/magic8 test
make -C toolchains/ntvdm run WORKDIR="$PWD/floppies/hello/build" PROGRAM=HELLO.EXE
```

`make samples` discovers sample Makefiles. `make floppies` builds the included
floppy images. Individual projects expose `build`, `test`, `image`, and `clean`;
some tests are only build checks, as described in their project README.

## Interactive automation

`make dosbox-automation` builds the upstream DOSBox Automation source in a
container. Its bundled config mounts `/work` as drive C. For REST-driven
testing, supply a primary configuration enabling the webserver and token file,
and persist the token directory in a host mount. Follow the module's setup and
configuration instructions in the root README, then attach with
`Connect-DosboxSession -BaseUrl <url> -TokenFile <path>`.

Use `Get-DosboxScreenText`, `Send-DosboxKey`, and `Wait-DosboxScreenText` to
assert visible behavior; use screenshots for graphics modes. Publish a
container's API port only on loopback when running local tests. The bundled
container config by itself does not enable the REST server.

Use `Start-DosboxSession` with the root setup script for a host-installed
DOSBox Automation session. Mount a built floppy or its build directory to
exercise the same programs through the PowerShell module.

## Import validation (2026-09-15)

Using the available compiler images with Podman under WSL:

- `make -C floppies/magic8 test image`, `hello test image`, and
  `typing test image` passed compilation, NTVDM tests, and FAT12 packaging.
- `make -C floppies/personality build image` passed compilation and packaging.
- `make -C floppies/hacker-tools test image` and `naied test image` passed.
- `make turbopascal` and `make -C samples/misc/turbopascal-hello test` passed
  using the actual Turbo Pascal 7 compiler and the resulting DOS executable.
- `make msfortran` and `make -C floppies/anova test image` passed using
  Microsoft FORTRAN 5.00, six DOS output checks, and FAT12 packaging.
- The other included floppy projects passed their `image` targets.
- DWED's optional `make -C floppies/dwed test` rebuild stalled while running
  the historical help compiler under NTVDM and was stopped. Its `image` target
  packages the pinned upstream release binaries successfully.

These checks do not verify the full interactive behavior of every application
or rebuild every compiler image from scratch.
