{
  buildPythonPackage,
  setuptools,
  schemdraw,
  ziamath,
  latex2mathml,
}:

buildPythonPackage {
  pname = "fzgen";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ setuptools ];
  dependencies = [
    schemdraw
    ziamath # schemdraw text="path"
    latex2mathml # ziamath imports it unconditionally
  ];
  pythonImportsCheck = [
    "fzgen.sketch"
    "fzgen.schematic"
  ];
}
