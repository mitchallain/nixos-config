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
      hash = "sha256:03scwpi97b8nb0sd8cdx5v865q4yf3wkqw62qhan1p7kkrnca4pc";
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
      hash = "sha256:0h2ypc7ydn90x0xi7xkbzmi4fjsnk4rs1v6cay4j6xs8yg86axqy";
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
