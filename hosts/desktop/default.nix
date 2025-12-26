# hosts/desktop/default.nix - Example desktop configuration
{ config, pkgs, ... }:

{
  imports = [
    # Hardware configuration (will be generated during install)
    ./hardware-configuration.nix

    # Import modules from this flake
    ../../modules/common/base.nix
    ../../modules/common/gnome.nix
    ../../modules/features/development.nix
    ../../modules/features/virtualization.nix
  ];

  # Hostname for desktop
  networking.hostName = "desktop";

  # sops-nix configuration - age key derived from SSH host key
  sops.age.keyFile = "/etc/ssh/ssh_host_ed25519_key";

  # Enable development features
  mySystem.development = {
    enable = true;
    languages = {
      python = true;
      rust = true;
      nodejs = true;
      go = true;
    };
  };

  # Enable Docker
  mySystem.virtualization = {
    enable = true;
    backend = "docker";
  };
}
