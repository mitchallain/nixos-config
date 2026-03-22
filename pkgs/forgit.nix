# pkgs/forgit.nix - Interactive git commands powered by fzf
# https://github.com/wfxr/forgit
{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation rec {
  pname = "forgit";
  version = "26.01.0";

  src = fetchFromGitHub {
    owner = "wfxr";
    repo = "forgit";
    rev = version;  # Tags have no 'v' prefix
    # Run `nix build` once with lib.fakeHash to get the correct hash:
    hash = "sha256-3PjKFARsN3BE5c3/JonNj+LpKBPT1N3hc1bK6NdWDTQ=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/share/forgit
    cp forgit.plugin.sh $out/share/forgit/
    cp forgit.plugin.zsh $out/share/forgit/
    # Install completions if present
    [ -d completions ] && cp -r completions $out/share/forgit/ || true
  '';

  meta = with lib; {
    description = "A utility tool powered by fzf for using git interactively";
    homepage = "https://github.com/wfxr/forgit";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
