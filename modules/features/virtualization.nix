# modules/features/virtualization.nix - Docker/Podman containerization module
#
# Example feature module for containerization.
# Enable with: mySystem.virtualization.enable = true;
{ config, lib, pkgs, ... }:

with lib;

{
  options.mySystem.virtualization = {
    enable = mkEnableOption "containerization (Docker/Podman)";

    backend = mkOption {
      type = types.enum [ "docker" "podman" ];
      default = "docker";
      description = "Container backend to use";
    };
  };

  config = mkIf config.mySystem.virtualization.enable {
    # Docker configuration
    virtualisation.docker = mkIf (config.mySystem.virtualization.backend == "docker") {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # Podman configuration (Docker-compatible alternative)
    virtualisation.podman = mkIf (config.mySystem.virtualization.backend == "podman") {
      enable = true;
      dockerCompat = true;  # Create docker alias
      defaultNetwork.settings.dns_enabled = true;
    };

    # Add user to docker/podman group
    users.users.mallain.extraGroups = [
      (if config.mySystem.virtualization.backend == "docker" then "docker" else "podman")
    ];

    # Install docker-compose
    environment.systemPackages = with pkgs; [
      docker-compose
    ] ++ optionals (config.mySystem.virtualization.backend == "podman") [
      podman-compose
    ];
  };
}
