# Everything a bench project needs, built on the caller's pkgs so the
# project's flake.lock alone decides what goes into the .hex.
pkgs:
let
  inherit (pkgs) lib;

  fzgen = pkgs.python3Packages.callPackage ../fzgen { };

  # d2 embeds its font as @font-face, which resvg ignores, so the PNG pass
  # substitutes a real font-family first. Shell snippet: writes <out>.svg and
  # <out>.png; needs d2 and resvg in nativeBuildInputs (renderInputs).
  renderD2 = src: out: ''
    d2 ${src} ${out}.svg
    sed -E 's/font-family: "?d2-[0-9]+-font-(bold|italic|regular)"?/font-family: "Source Sans 3"/' \
      ${out}.svg > d2-render.svg
    resvg --skip-system-fonts --use-fonts-dir ${pkgs.source-sans}/share/fonts \
      --font-family "Source Sans 3" d2-render.svg ${out}.png
  '';
  renderInputs = [
    pkgs.d2
    pkgs.resvg
  ];
in
{
  inherit fzgen renderD2 renderInputs;

  boards = {
    promicro = import ./boards/promicro.nix pkgs;
  };

  # One interpreter for generators, the devshell and the checks.
  python = extra: pkgs.python3.withPackages (p: [ (p.callPackage ../fzgen { }) ] ++ extra p);

  # Copies an output dir over a tracked one (docs/), then shows what changed.
  mkRenderDocs =
    {
      attr ? "docs",
      dir ? "docs",
    }:
    pkgs.writeShellApplication {
      name = "render-docs";
      text = ''
        cp -r --no-preserve=mode "$(nix build --no-link --print-out-paths .#${attr})"/. ${dir}/
        git -C ${dir} status --short .
      '';
    };

  # Tracked files must equal what their sources render to.
  mkFreshCheck =
    name: built: tracked: files:
    pkgs.runCommand name { } ''
      for f in ${lib.escapeShellArgs files}; do
        cmp -s ${built}/$f ${tracked}/$f \
          || { echo "$f is stale, run render-docs" >&2; exit 1; }
      done
      touch $out
    '';

  # gen: script called as `gen <fritzing parts dir> <out dir>`.
  mkBenchFzz =
    {
      name,
      gen,
      python,
    }:
    pkgs.runCommand name { nativeBuildInputs = [ python ]; } ''
      python3 ${gen} ${pkgs.fritzing}/share/fritzing/parts $out
    '';

  # Lints what Fritzing saved, not what the generator placed: the two differ
  # after a GUI edit. cases: script called as `cases <Fritzing> <dir>`.
  mkBenchLint =
    {
      fzz,
      sketches,
      cases ? null,
      python,
    }:
    pkgs.runCommand "bench-lint" { nativeBuildInputs = [ python ]; } ''
      export HOME=$PWD/home QT_QPA_PLATFORM=offscreen
      cp ${fzz}/* . && chmod u+w *
      ${pkgs.fritzing}/bin/Fritzing -svg $PWD > /dev/null 2>&1
      for s in ${lib.escapeShellArgs sketches}; do
        fzgen-lint $s.fzz ''${s}_breadboard.svg $s.nets.json
      done
      ${
        lib.optionalString (cases != null) "python3 ${cases} ${pkgs.fritzing}/bin/Fritzing $PWD"
      } | tee $out
    '';

  mkFizzel =
    name: file:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        f=''${1:-${file}}
        [ -e "$f" ] || { echo "no $f: run from the repo root"; exit 1; }
        exec ${pkgs.fritzing}/bin/Fritzing "$f"
      '';
    };

  # The sketch compiled for the host against a fake core: `firmware` and
  # `test` dirs are copied to src/firmware and test/, `main` is compiled
  # from test/ with -I test.
  mkSim =
    {
      name,
      firmware,
      test,
      main ? "sim.cpp",
      flags ? "",
    }:
    pkgs.runCommandCC name { } ''
      mkdir -p src
      cp -r ${firmware} src/firmware
      cp -r ${test} test
      $CXX -std=c++17 -Wall -Werror -Wno-unused-function ${flags} -I test test/${main} -o sim
      ./sim | tee $out
    '';

  # Devshell with the git hooks (lefthook.yml takes linters from PATH) and a
  # command table printed on entry. commands: [ [ "cmd args" "what it does" ] ].
  mkDevShell =
    {
      name,
      packages ? [ ],
      commands ? [ ],
      shellHook ? "",
    }:
    let
      # Rows with an empty description (long one-liners) don't widen the column.
      described = lib.filter (c: lib.last c != "") commands;
      width = lib.foldl' lib.max 0 (map (c: lib.stringLength (lib.head c)) described) + 2;
      pad = s: s + lib.concatStrings (lib.genList (_: " ") (width - lib.stringLength s));
      row = c: if lib.last c == "" then "  ${lib.head c}" else "  ${pad (lib.head c)}${lib.last c}";
      help = lib.concatMapStringsSep "\n" row commands;
    in
    pkgs.mkShell {
      packages = packages ++ [
        pkgs.lefthook
        pkgs.gitleaks
        pkgs.nixfmt
        pkgs.deadnix
        pkgs.statix
        pkgs.ruff
        pkgs.clang-tools
        pkgs.cppcheck
      ];
      shellHook = ''
        lefthook install >/dev/null || echo "lefthook install failed; git hooks not installed" >&2
        cat <<'BENCH_HELP'
        ${name} devshell
        ${help}
        BENCH_HELP
      ''
      + shellHook;
    };
}
