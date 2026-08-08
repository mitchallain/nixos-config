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
      hash = "sha256-YEu4/sN7VrAtOh6djTDdxttnyj/0G2C7p000g0qdxc4=";
    })
    (mkZealDocset {
      name = "zeal-docset-cpp";
      docsetName = "C++.docset";
      url = "https://kapeli.com/feeds/C++.tgz";
      hash = "sha256-84sCt4NVQ1cdFFR0hrIZBB496cmvgejg6vIZ6zCQJVg=";
    })
    (mkZealDocset {
      name = "zeal-docset-rust";
      docsetName = "Rust.docset";
      url = "https://kapeli.com/feeds/Rust.tgz";
      hash = "sha256-AzHDeUgc2Ni5G8Yn77jfdahMkXM/hLJ0b7sdJMG1aSA=";
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
