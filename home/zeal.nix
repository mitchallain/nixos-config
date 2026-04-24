{ pkgs, lib, ... }:

let
  mkZealDocset =
    {
      name,
      docsetName,
      url,
      hash,
    }:
    {
      inherit docsetName;
      path = pkgs.stdenvNoCC.mkDerivation {
        inherit name;
        src = pkgs.fetchurl { inherit url hash; };
        dontUnpack = true;
        installPhase = ''
          mkdir -p $out
          tar -xzf $src -C $out
        '';
      };
    };

  zealDocsets = [
    (mkZealDocset {
      name = "zeal-docset-python";
      docsetName = "Python.docset";
      url = "https://kapeli.com/feeds/Python.tgz";
      hash = "sha256-QfOJ4Y8YCoc8CurOTfaoxnu2D25gPtwysUfKobARMnM=";
    })
    (mkZealDocset {
      name = "zeal-docset-cpp";
      docsetName = "C++.docset";
      url = "https://kapeli.com/feeds/C++.tgz";
      hash = "sha256:0m020hpvchw7q4f0hx7bn1n4qzy8b9rsklavl0wnmw6vw4jw4fjm";
    })
    (mkZealDocset {
      name = "zeal-docset-rust";
      docsetName = "Rust.docset";
      url = "https://kapeli.com/feeds/Rust.tgz";
      hash = "sha256-jJtzuXiCh+v9cduLl95rFly0BnL1xPQOmbwgPLOmsxw=";
    })
  ];
in

{
  home.file = lib.mkMerge (
    map (docset: {
      ".local/share/Zeal/Zeal/docsets/${docset.docsetName}".source =
        "${docset.path}/${docset.docsetName}";
    }) zealDocsets
  );
}
