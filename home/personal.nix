{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud storage
    insync # Google Drive sync client (proprietary)
  ];

  programs.ssh = {
    enable = true;
    matchBlocks."github.com" = {
      user = "git";
      identityFile = "/run/secrets/github_ssh_key";
    };
  };
}
