{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Cloud storage
    insync # Google Drive sync client (proprietary)
  ];
}
