# modules/common/gnome.nix - GNOME desktop environment configuration
{ config, pkgs, ... }:

{
  # Enable display server infrastructure (despite the name, this enables both X11 and Wayland)
  services.xserver.enable = true;

  # Enable GNOME Desktop Environment
  # GDM will default to Wayland, with X11 available as fallback
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Explicitly prefer Wayland (this is the default, but being explicit)
  services.displayManager.gdm.wayland = true;

  # To force X11 instead, uncomment:
  # services.xserver.displayManager.gdm.wayland = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS for printing
  services.printing.enable = true;

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # GNOME-specific packages
  environment.systemPackages = with pkgs; [
    gnome-tweaks
    gnome-extension-manager
    alacritty # Terminal emulator
  ];

  # Disable some GNOME services that might not be needed
  services.gnome.gnome-remote-desktop.enable = false;
}
