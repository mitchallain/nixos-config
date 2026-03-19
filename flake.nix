{
  description = "Reusable NixOS modules and example configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, sops-nix }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      mkSystem = { system, hostname, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = modules ++ [
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mallain = import ./home/base.nix;
              home-manager.extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            }
          ];
        };
    in {
      # Export modules for use in other flakes
      nixosModules = {
        base = import ./modules/common/base.nix;
        gnome = import ./modules/common/gnome.nix;
        development = import ./modules/features/development.nix;
        virtualization = import ./modules/features/virtualization.nix;
        zfs = import ./modules/features/zfs.nix;
        immich = import ./modules/features/immich.nix;
      };

      homeManagerModules = {
        base = import ./home/base.nix;
      };

      nixosConfigurations = {
        fractal = mkSystem {
          system = "x86_64-linux";
          hostname = "fractal";
          modules = [
            ./hosts/fractal
            sops-nix.nixosModules.sops
          ];
        };
      };

      # Helper functions (optional)
      lib = import ./lib;

      # Overlay with pkgs-unstable (optional)
      overlays.default = final: prev: {
        unstable = import nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      };
    };
}
