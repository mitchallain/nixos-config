{ pkgs, ... }:

{
  home.packages = with pkgs; [
    darktable # RAW photo processing and workflow
    shotwell # Photo manager with device import and browsing
    gthumb # Lightweight photo browser and importer
    libgphoto2 # Camera USB import support
  ];
}
