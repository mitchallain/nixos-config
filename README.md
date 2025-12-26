# NixOS Configuration Modules

Reusable NixOS modules and example configurations for building declarative, reproducible systems.

## Overview

This repository provides:
- **Reusable NixOS modules** for common system configurations
- **Example desktop configuration** showing how to use the modules
- **home-manager** integration for user-level configuration
- **sops-nix** support for secrets management

## Repository Structure

```
nixos-config/
├── flake.nix                    # Main flake exporting modules
├── modules/
│   ├── common/
│   │   ├── base.nix             # Core system config
│   │   └── gnome.nix            # GNOME desktop
│   └── features/
│       ├── development.nix      # Dev tools with language options
│       └── virtualization.nix   # Docker/Podman
├── hosts/
│   └── desktop/                 # Example machine configuration
│       ├── default.nix
│       └── hardware-configuration.nix
├── home/
│   └── base.nix                 # Base home-manager config
└── lib/
    └── default.nix              # Helper functions
```

## Available Modules

### `nixosModules.base`
Core system configuration including:
- User account setup (default: "mallain" - **change to your username**)
- Essential packages (vim, git, wget, etc.)
- SSH server
- NetworkManager
- Nix flakes and garbage collection
- Firewall configuration

> **Note:** The base module defines a user named "mallain". You should either:
> 1. Edit `modules/common/base.nix` to use your username, or
> 2. Override the user definition in your host configuration

### `nixosModules.gnome`
GNOME desktop environment with:
- GDM display manager
- Wayland support (X11 fallback)
- Pipewire audio
- CUPS printing

### `nixosModules.development`
Development environment with configurable language support:
```nix
mySystem.development = {
  enable = true;
  languages = {
    python = true;
    rust = true;
    nodejs = true;
    go = true;
  };
};
```

### `nixosModules.virtualization`
Container support (Docker or Podman):
```nix
mySystem.virtualization = {
  enable = true;
  backend = "docker";  # or "podman"
};
```

### `homeManagerModules.base`
Base home-manager configuration with:
- Modern CLI tools (bat, eza, zoxide)
- fzf and direnv
- Development packages

## Using These Modules

### In Your Own Flake

Add this repository as a flake input:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-config.url = "github:yourusername/nixos-config";
  };

  outputs = { self, nixpkgs, nixos-config, ... }:
    {
      nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import modules from this repo
          nixos-config.nixosModules.base
          nixos-config.nixosModules.gnome
          nixos-config.nixosModules.development

          # Your machine configuration
          ./hosts/mymachine
        ];
      };
    };
}
```

### Building the Example Desktop

Test the example desktop configuration:

```bash
# Build without installing
nix build github:yourusername/nixos-config#nixosConfigurations.desktop.config.system.build.toplevel

# Or clone and build locally
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
nix flake check
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
```

## Complete Installation Workflow

### 1. Fresh NixOS Installation

Boot from NixOS ISO and follow the standard installation process, then:

### 2. Install Dotfiles

Clone and install your dotfiles (if you have them):

```bash
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
git submodule update --init --recursive
./install  # Run dotbot
```

### 3. Create Your Machine Configuration

Create a new flake that imports these modules:

```bash
mkdir -p ~/sources/my-nixos-config
cd ~/sources/my-nixos-config
```

Create `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-config.url = "github:yourusername/nixos-config";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, nixos-config, home-manager, sops-nix }:
    {
      nixosConfigurations.mymachine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Import modules from nixos-config
          nixos-config.nixosModules.base
          nixos-config.nixosModules.gnome
          nixos-config.nixosModules.development

          # Your machine-specific config
          ./hosts/mymachine

          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.users.yourusername = import ./home/yourusername.nix;
          }

          # sops-nix
          sops-nix.nixosModules.sops
        ];
      };
    };
}
```

### 4. Generate Hardware Configuration

```bash
sudo nixos-generate-config --root /
sudo mv /etc/nixos/hardware-configuration.nix ~/sources/my-nixos-config/hosts/mymachine/
```

### 5. Create Machine-Specific Config

Create `hosts/mymachine/default.nix`:
```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "mymachine";

  # Enable features from nixos-config modules
  mySystem.development = {
    enable = true;
    languages.python = true;
  };
}
```

### 6. Apply Configuration

```bash
cd ~/sources/my-nixos-config
sudo nixos-rebuild switch --flake .#mymachine
```

## Example Private Repository Structure

For separating public modules from private machine configs:

```
my-private-nixos/
├── flake.nix              # Imports github:yourusername/nixos-config
├── hosts/
│   ├── laptop/
│   └── desktop/
├── secrets/               # sops-nix encrypted secrets
└── home/
    └── work.nix
```

See the "Complete Installation Workflow" section above for flake setup.

## Module Options

### Development Module

```nix
mySystem.development.enable = true;
mySystem.development.languages.python = true;
mySystem.development.languages.rust = true;
mySystem.development.languages.nodejs = true;
mySystem.development.languages.go = true;
```

### Virtualization Module

```nix
mySystem.virtualization.enable = true;
mySystem.virtualization.backend = "docker";  # or "podman"
```

## Updating

```bash
cd ~/sources/my-nixos-config
nix flake update
sudo nixos-rebuild switch --flake .
```

## Key Features

- **NixOS 25.11** (stable)
- **Dual Channels**: Access both stable and unstable packages
- **GNOME Desktop**: Wayland by default
- **Development Tools**: Python, Rust, Node.js, Go (optional)
- **Containers**: Docker or Podman support
- **Secrets Management**: sops-nix integration
- **home-manager**: User-level declarative configuration

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [home-manager Documentation](https://nix-community.github.io/home-manager/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Nix Pills](https://nixos.org/guides/nix-pills/)

## License

MIT
