{ config, pkgs, pkgs-unstable, ... }:

{
  # Home Manager state version - DO NOT CHANGE after initial setup
  home.stateVersion = "25.11";

  # User-level packages
  home.packages = with pkgs; [
    # Development tools
    python3
    nodejs
    rustc
    cargo
    neovim

    # CLI tools
    jq
    yq
    tree
    ncdu
    lazygit
    delta  # Better git diffs

    # System monitoring
    iotop
    iftop
    duf  # Modern df alternative

    # Modern CLI replacements
    bat  # Better cat
    eza  # Better ls
    zoxide  # Better cd
  ];

  # Environment variables
  home.sessionVariables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };

  # FZF Configuration
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # Direnv - for project-specific environments (useful with Nix)
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
