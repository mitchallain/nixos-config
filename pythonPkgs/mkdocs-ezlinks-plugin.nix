# pythonPkgs/mkdocs-ezlinks-plugin.nix
# https://github.com/orbikm/mkdocs-ezlinks-plugin
# Wikilink ([[page]]) resolution for mkdocs; not yet packaged in nixpkgs.
{ buildPythonPackage, fetchPypi, setuptools, mkdocs, pygtrie }:

buildPythonPackage rec {
  pname = "mkdocs-ezlinks-plugin";
  version = "0.1.14";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-PiCFwWqFDgIjk+gBlMF2Eue1Xeh/tFs/+2GLXf2xCBE=";
  };

  build-system = [ setuptools ];
  dependencies = [ mkdocs pygtrie ];

  doCheck = false;
}
