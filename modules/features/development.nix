# modules/features/development.nix - Development environment module
#
# Example feature module demonstrating the pattern.
# Enable with: mySystem.development.enable = true;
{ config, lib, pkgs, ... }:

with lib;

{
  options.mySystem.development = {
    enable = mkEnableOption "development environment";

    languages = {
      python = mkEnableOption "Python development tools";
      rust = mkEnableOption "Rust development tools";
      nodejs = mkEnableOption "Node.js development tools";
      go = mkEnableOption "Go development tools";
    };
  };

  config = mkIf config.mySystem.development.enable {
    environment.systemPackages = with pkgs; [
      # Core development tools
      git
      gh  # GitHub CLI
      lazygit
      delta  # Better git diffs
      ripgrep
      xclip
      neovim

      # Build tools
      gnumake
      cmake
      pkg-config

      # Debugging
      gdb
      lldb

      # Modern CLI tools for development
      jq
      yq
      tree
      ncdu

      # Language-specific tools
    ] ++ optionals config.mySystem.development.languages.python [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      poetry
      uv
    ] ++ optionals config.mySystem.development.languages.rust [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ] ++ optionals config.mySystem.development.languages.nodejs [
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.pnpm
    ] ++ optionals config.mySystem.development.languages.go [
      go
      gopls
      gotools
      go-tools
    ];

    # Docker for containerized development (optional)
    # Uncomment to enable (change "mallain" to your username):
    # virtualisation.docker.enable = true;
    # users.users.mallain.extraGroups = [ "docker" ];
  };
}
