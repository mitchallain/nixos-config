# NixOS Configuration Modules - Context for Claude

This repository provides reusable NixOS modules and an example configuration. It's designed to be imported by other flakes.

## Repository Purpose

**Public Repository:** Reusable modules for NixOS systems
**Use Cases:**
- Share common system configuration across multiple machines
- Provide base modules for personal and work systems
- Example desktop configuration for documentation and testing

## Architecture Philosophy

### Hierarchical Structure
```
modules/
  common/        # Base system configuration
  features/      # Optional, composable features
hosts/
  desktop/       # Example machine configuration
home/            # Base home-manager configuration
scripts/         # Helper scripts
```

### Key Design Decisions

1. **Modular Features**: Optional functionality uses enable flags:
   ```nix
   mySystem.development.enable = true;
   mySystem.virtualization.enable = true;
   ```

2. **Dual Channels**:
   - `pkgs` = stable (nixos-25.11)
   - `pkgs-unstable` = unstable packages when needed

3. **Namespace**: All custom options use `mySystem.*` namespace to avoid conflicts

4. **Secrets Support**: Includes sops-nix integration (example in secrets/)

## Module Overview

### modules/common/

**base.nix** - Core system configuration:
- User accounts (single-user setup)
- Base packages (vim, git, wget, tmux)
- Nix settings (flakes, auto-gc)
- SSH server
- NetworkManager
- Firewall defaults

**gnome.nix** - GNOME desktop environment:
- GDM display manager
- GNOME desktop with Wayland
- Pipewire audio
- Essential GNOME apps

### modules/features/

**development.nix** - Development tools:
- Language-specific options (Python, Rust, Node.js, Go)
- Build tools (gcc, cmake, pkg-config)
- Version control (git, mercurial)
- Documentation tools

**virtualization.nix** - Container support:
- Docker or Podman (configurable)
- User group membership
- Storage driver options

### hosts/desktop/

Example configuration showing how to use the modules:
- Hostname: "desktop"
- All features enabled
- GNOME desktop
- Development tools for all languages
- Docker enabled

### home/

**base.nix** - Base home-manager configuration:
- Modern CLI tools (bat, eza, zoxide)
- Development packages (neovim, lazygit)
- Shell enhancements (fzf, direnv)
- Basic developer workflow

## Using These Modules

### In Your Own Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixos-config.url = "github:yourusername/nixos-config";
  };

  outputs = { self, nixpkgs, nixos-config, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Import the modules you need
        nixos-config.nixosModules.base
        nixos-config.nixosModules.gnome
        nixos-config.nixosModules.development

        # Your machine-specific config
        ./configuration.nix
      ];
    };
  };
}
```

### Available Module Exports

- `nixosModules.base` - Core system configuration
- `nixosModules.gnome` - GNOME desktop
- `nixosModules.development` - Development tools
- `nixosModules.virtualization` - Docker/Podman
- `homeManagerModules.base` - Base home-manager config

## Module Options

### mySystem.development

```nix
mySystem.development = {
  enable = true;  # Enable development module
  languages = {
    python = true;   # Install Python toolchain
    rust = true;     # Install Rust toolchain
    nodejs = true;   # Install Node.js toolchain
    go = true;       # Install Go toolchain
  };
};
```

### mySystem.virtualization

```nix
mySystem.virtualization = {
  enable = true;
  backend = "docker";  # or "podman"
};
```

## Building the Example Configuration

```bash
# Clone the repository
git clone https://github.com/yourusername/nixos-config
cd nixos-config

# Check the flake
nix flake check

# Build the example desktop configuration
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Or build and install (if on NixOS)
sudo nixos-rebuild switch --flake .#desktop
```

## Directory Details

### modules/common/base.nix

Core configuration shared by all systems:
- Single user: `mallain` (UID 1000)
- sudo access for wheel group
- Base packages: vim, wget, git, tmux, htop
- Nix settings: flakes enabled, auto-gc weekly
- SSH server enabled
- NetworkManager for networking
- Default firewall (SSH allowed)

### modules/features/development.nix

Configurable development environment:
- **Core tools**: gcc, cmake, pkg-config, gdb
- **Python**: python3 with pip, virtualenv
- **Rust**: rustc, cargo, clippy, rustfmt
- **Node.js**: nodejs, npm, yarn
- **Go**: go compiler and tools
- **Optional**: Each language can be enabled/disabled

### modules/features/virtualization.nix

Container runtime support:
- **Docker**: When backend = "docker"
  - Docker daemon
  - Docker CLI
  - User added to docker group
- **Podman**: When backend = "podman"
  - Podman CLI
  - Rootless containers

## Common Tasks

### Adding System Packages

```nix
# In your host configuration
environment.systemPackages = with pkgs; [
  # Add your packages here
  firefox
  thunderbird
];
```

### Using Unstable Packages

```nix
# pkgs-unstable is automatically available
environment.systemPackages = with pkgs; [
  pkgs-unstable.latest-package
];
```

### Creating a New Feature Module

1. Create `modules/features/myfeature.nix`:
```nix
{ config, lib, pkgs, ... }:
with lib;
{
  options.mySystem.myfeature.enable = mkEnableOption "my feature";

  config = mkIf config.mySystem.myfeature.enable {
    environment.systemPackages = with pkgs; [ mypackage ];
  };
}
```

2. Export in `flake.nix`:
```nix
nixosModules = {
  myfeature = import ./modules/features/myfeature.nix;
};
```

3. Use in a host:
```nix
imports = [ nixos-config.nixosModules.myfeature ];
mySystem.myfeature.enable = true;
```

## Secrets Management

This repo includes sops-nix support. See `secrets/README.md` for details.

Basic usage:
```nix
# Import sops-nix in your flake
sops-nix.url = "github:Mic92/sops-nix";

# In your configuration
sops.defaultSopsFile = ./secrets/common.yaml;
sops.age.keyFile = "/etc/ssh/ssh_host_ed25519_key";
sops.secrets.my-secret = {};
```

Generate age key:
```bash
./scripts/generate-age-key.sh
```

## Helper Scripts

### scripts/generate-age-key.sh

Generates an age public key from SSH host key for use with sops-nix:

```bash
./scripts/generate-age-key.sh
```

Outputs the age public key to add to `.sops.yaml`.

### rebuild.sh / update.sh

Convenience scripts for rebuilding:

```bash
# Rebuild current system (auto-detects based on hostname)
./rebuild.sh

# Update flake inputs and rebuild
./update.sh
```

## Testing

```bash
# Validate flake syntax
nix flake check

# Build without installing
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Show flake structure
nix flake show
```

## Best Practices

### 1. Keep Modules Generic

These modules should be reusable across different machines:
- No hardcoded hostnames
- No machine-specific hardware configuration
- Use options for customization

### 2. Use Enable Options

All features should be optional:
```nix
config = mkIf config.mySystem.feature.enable {
  # Configuration here
};
```

### 3. Document Options

Add descriptions to all options:
```nix
options.mySystem.feature = {
  enable = mkEnableOption "feature description";

  option = mkOption {
    type = types.str;
    description = "What this option does";
    default = "value";
  };
};
```

### 4. Namespace Everything

Use `mySystem.*` for all custom options to avoid conflicts.

## Integration with Private Configurations

Typical pattern for using these modules:

```
your-private-config/
├── flake.nix           # Imports nixos-config as input
├── hosts/
│   ├── laptop/
│   └── vm/
└── secrets/            # Private secrets
```

Your private flake imports these modules:
```nix
inputs.nixos-config.url = "github:yourusername/nixos-config";

modules = [
  nixos-config.nixosModules.base
  nixos-config.nixosModules.gnome
  ./hosts/laptop
];
```

## Version Information

- **NixOS**: 25.11 (stable channel)
- **home-manager**: release-25.11
- **nixpkgs-unstable**: For latest packages when needed
- **State version**: 25.11

## Troubleshooting

### "Path not tracked by Git"

Flakes require files to be tracked:
```bash
git add .
```

### Module Not Found

Ensure module is imported in `flake.nix` nixosModules:
```nix
nixosModules = {
  mymodule = import ./modules/features/mymodule.nix;
};
```

### Option Conflicts

Check for option name collisions. Use unique namespace (`mySystem.*`).

## Contributing

This is a personal configuration repo, but you can:
1. Fork for your own use
2. Adapt modules for your needs
3. Use as reference for your own modular setup

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [home-manager Documentation](https://nix-community.github.io/home-manager/)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
