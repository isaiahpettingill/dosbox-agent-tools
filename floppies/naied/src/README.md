# Source Staging

`make build` copies the pinned upstream NaiED `src/` directory from
`third_party/naied` to `build/src` before compiling it. This keeps third-party
source immutable and generated compiler outputs inside `build/`.
