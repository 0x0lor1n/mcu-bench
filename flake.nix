{
  description = "Nix helpers for small microcontroller projects: firmware build, flashers, Fritzing sketches from code, devshell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in
    {
      # Call with the project's own pkgs: `bench = mcu-bench.lib pkgs;`. The
      # project's flake.lock then decides the toolchain, not this one.
      lib = import ./nix;

      templates.default = {
        path = ./templates/project;
        description = "Repo config for a bench project: lefthook, gitleaks, clang-format, direnv";
      };

      packages = forAll (pkgs: rec {
        inherit (self.lib pkgs) fzgen;
        default = fzgen;
      });

      devShells = forAll (pkgs: {
        default = (self.lib pkgs).mkDevShell {
          name = "mcu-bench";
          packages = [ ((self.lib pkgs).python (_: [ ])) ];
          commands = [
            [
              "nix flake check"
              "fzgen import, flash script shellcheck"
            ]
          ];
        };
      });

      checks = forAll (
        pkgs:
        let
          bench = self.lib pkgs;
        in
        {
          inherit (bench) fzgen;
          # writeShellApplication runs shellcheck at build time.
          flash-promicro = bench.boards.promicro.mkFlash "flash" pkgs.emptyDirectory;
        }
      );
    };
}
