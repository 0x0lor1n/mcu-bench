# mcu-bench

Nix helpers for small microcontroller projects, shared by
[nas-power-button](https://github.com/0x0lor1n/nas-power-button) and
[pro-micro-to-ps2](https://github.com/0x0lor1n/pro-micro-to-ps2).

Everything is built on the caller's `pkgs`, so a project's own `flake.lock`
decides what goes into its `.hex`:

```nix
inputs.mcu-bench = {
  url = "github:0x0lor1n/mcu-bench";
  inputs.nixpkgs.follows = "nixpkgs";
};
# ...
b = mcu-bench.lib pkgs;
firmware = b.boards.promicro.mkFirmware { name = "fw"; ino = ./src/firmware/firmware.ino; };
flash = b.boards.promicro.mkFlash "flash" firmware;
```

## What's in it

- `boards.promicro`: `mkFirmware` (arduino-builder, Leonardo core, optional
  libraries and extra flags), `mkFlash` (1200-baud touch, waits for the
  Caterina bootloader, avrdude), `devPackages`, `console`. One attrset per
  board; Uno/Pico get their own when a project needs them.
- `fzgen`: Fritzing sketches from code. Place parts by "this pin goes into
  that hole", check nets through the breadboard strips, write a `.fzz`; then
  `fzgen-lint` re-reads what Fritzing rendered. `mkBenchFzz`, `mkBenchLint`
  (with lint mutations that must be caught), `mkFizzel` (opens a sketch).
- `fzgen.schematic` + `renderSchematic`: schemdraw schematics with a Pro
  Micro box whose pins are checked against the same board map fzgen places.
- `mkSim`: compiles an unchanged `.ino` against a project's fake Arduino core
  and runs it.
- `renderD2`, `mkRenderDocs`, `mkFreshCheck`: d2 diagrams to svg/png, and a
  check that the tracked copy is current.
- `mkDevShell { name, packages, commands }`: lefthook hooks, linters and a
  command table on entry.
- `templates.project`: lefthook, gitleaks, clang-format, ruff, direnv config
  (`nix flake init -t github:0x0lor1n/mcu-bench#project`).

## License

MIT
