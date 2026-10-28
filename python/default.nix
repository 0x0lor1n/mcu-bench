{
  buildPythonPackage,
  setuptools,
  schemdraw,
  ziamath,
  latex2mathml,
}:

buildPythonPackage {
  pname = "mcubench";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ setuptools ];
  # For mcubench.schematic only; boards and fritzing are stdlib-only.
  dependencies = [
    schemdraw
    ziamath # schemdraw text="path"
    latex2mathml # ziamath imports it unconditionally
  ];
  pythonImportsCheck = [
    "mcubench.boards.promicro"
    "mcubench.fritzing.espprog"
    "mcubench.fritzing.sketch"
    "mcubench.fritzing.soic8clip"
    "mcubench.schematic"
  ];
}
