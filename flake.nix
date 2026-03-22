{
  description = "Reusable NixOS modules and example configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      determinate,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Overlay that auto-discovers all packages under pkgs/
      localOverlay =
        final: prev:
        nixpkgs.lib.packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          directory = ./pkgs;
        };

      mkSystem =
        {
          system,
          hostname,
          modules,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = modules ++ [
            determinate.nixosModules.default
            { nixpkgs.overlays = [ localOverlay ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mallain = {
                imports = [
                  ./home/base.nix
                  ./home/niri.nix
                ];
              };
              home-manager.extraSpecialArgs = {
                pkgs-unstable = import nixpkgs-unstable {
                  inherit system;
                  config.allowUnfree = true;
                };
              };
            }
          ];
        };
    in
    {
      # Export modules for use in other flakes
      nixosModules = {
        base = import ./modules/common/base.nix;
        gnome = import ./modules/common/gnome.nix;
        niri = import ./modules/common/niri.nix;
        development = import ./modules/features/development.nix;
        virtualization = import ./modules/features/virtualization.nix;
        zfs = import ./modules/features/zfs.nix;
        immich = import ./modules/features/immich.nix;
      };

      homeManagerModules = {
        base = import ./home/base.nix;
        gnome = import ./home/gnome.nix;
        niri = import ./home/niri.nix;
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

      # Nix formatter - run with `nix fmt`
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "fmt" ''
          find "$@" -name "*.nix" -print0 | xargs -0 ${pkgs.nixfmt}/bin/nixfmt
        ''
      );

      # Helper functions (optional)
      lib = import ./lib;

      # Export local packages overlay (auto-discovers pkgs/)
      overlays.default = localOverlay;
    };
}
