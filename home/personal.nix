{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud storage
    insync # Google Drive sync client (proprietary)
  ];

  # Register personal notes as a qmd collection on first activation
  home.activation.qmdNotesCollection = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.llm-agents.qmd}/bin/qmd collection add "$HOME/Google Drive/05 Notes" --name notes 2>/dev/null || true
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      user = "git";
      identityFile = "/run/secrets/github_ssh_key";
    };
  };
}
