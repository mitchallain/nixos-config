# home/gnome.nix - GNOME-specific home-manager configuration
{ config, pkgs, ... }:

{
  # GNOME custom keyboard shortcuts
  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Open Terminal";
      command = "alacritty";
      binding = "<Alt><Shift>t";
    };
  };
}
