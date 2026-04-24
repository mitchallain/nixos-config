{
  description = "Reusable NixOS modules and example configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-secrets.url = "git+ssh://git@github.com/mitchallain/sops-secrets";
    sops-secrets.flake = false;
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
    llm-agents-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      sops-nix,
      sops-secrets,
      determinate,
      llm-agents-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Overlay that auto-discovers all packages under pkgs/
      localOverlay = final: prev:
        nixpkgs.lib.packagesFromDirectoryRecursive {
          inherit (final) callPackage;
          directory = ./pkgs;
        }
        // {
          python3 = prev.python3.override {
            packageOverrides = pyFinal: pyPrev:
              nixpkgs.lib.packagesFromDirectoryRecursive {
                callPackage = pyFinal.callPackage;
                directory = ./pythonPkgs;
              };
          };
          python3Packages = final.python3.pkgs;
        };

      mkSystem =
        {
          system,
          hostname,
          modules,
          homeModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit sops-secrets;
            pkgs-unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = modules ++ [
            determinate.nixosModules.default
            { nixpkgs.overlays = [ localOverlay llm-agents-nix.overlays.default ]; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mallain = {
                imports = [
                  ./home/base.nix
                  ./home/niri.nix
                ]
                ++ homeModules;
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
        notes = import ./modules/features/notes.nix;
      };

      homeManagerModules = {
        base = import ./home/base.nix;
        gnome = import ./home/gnome.nix;
        niri = import ./home/niri.nix;
        personal = import ./home/personal.nix;
        photography = import ./home/photography.nix;
        notes = import ./home/notes.nix;
      };

      nixosConfigurations = {
        fractal = mkSystem {
          system = "x86_64-linux";
          hostname = "fractal";
          modules = [
            ./hosts/fractal
            sops-nix.nixosModules.sops
          ];
          homeModules = [
            ./home/personal.nix
            ./home/photography.nix
            ./home/notes.nix
            ./home/fractal.nix
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
