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

  # Bash - source dotfiles bashrc after home-manager's generated preamble
  # (fzf/direnv hooks are injected by HM first, dotfiles bashrc duplicates are harmless no-ops)
  programs.bash = {
    enable = true;
    initExtra = ''
      source ${config.home.homeDirectory}/dotfiles/bashrc
    '';
    # bash_profile: HM's generated version already sources .profile and .bashrc,
    # covering everything in dotfiles/bash_profile.sh (.cargo/env is in .bashrc anyway)
    # bash_logout: dotfiles version only clears console via /usr/bin/clear_console
    # which doesn't exist on NixOS - skip it
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

  # Dotfile symlinks
  # Shell
  home.file.".gitconfig".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/gitconfig";
  home.file.".bash_aliases".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/bash_aliases.sh";
  home.file.".profile".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/profile";
  home.file.".aliases/fzf_functions.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/fzf_functions.sh";
  home.file.".aliases/nix_aliases.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/aliases/nix_aliases.sh";
  home.file.".aliases/llm_aliases.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/aliases/llm_aliases.sh";

  # Editor
  home.file.".vimrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/vimrcs/vimrc";
  home.file.".vimrcs".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/vimrcs";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";

  # Terminal
  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux.conf";
  home.file.".tmux.powerline.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/tmux.powerline.conf";
  home.file.".config/alacritty".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/alacritty";

  # Development tools
  home.file.".clang-format".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/clang/.clang-format";
  home.file.".cmake-format.py".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/cmake/.cmake-format.py";
  home.file.".config/clangd/config.yaml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/clang/clangd.yaml";
  home.file.".gdbinit".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/.gdbinit";
  home.file.".flake8".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/flake8";
  home.file.".pylintrc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/pylintrc";

  # Tools
  home.file.".config/btop/btop.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/btop/btop.conf";
  home.file.".config/matplotlib/stylelib".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/matplotlib/stylelib";
  home.file.".config/yapf/style".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/yapf/style";
  home.file.".config/.rgignore".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/rgignore";
  home.file.".mermaid.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/mermaid.json";
  home.file.".pandoc".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/pandoc";
  home.file.".ipython/profile_default/startup".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/ipython/profile_default/startup";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
