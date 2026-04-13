{
  config,
  pkgs,
  ...
}:

{
  imports = [ ./zeal.nix ];
  # Home Manager state version - DO NOT CHANGE after initial setup
  home.stateVersion = "25.11";

  # Neovim - use programs.neovim so extraPackages are in neovim's PATH
  # (required for nvim-treesitter to compile parsers)
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      tree-sitter
      gcc
    ];
  };

  # User-level packages
  home.packages = with pkgs; [
    # Development tools
    python3
    nodejs
    rustc
    cargo

    # Git tools
    forgit # Interactive git commands via fzf (gd, gco, gss, etc.)

    # AI tools (from llm-agents-nix overlay)
    llm-agents.claude-code
    llm-agents.qmd

    # CLI tools
    jq
    yq
    tree
    ncdu
    lazygit
    delta # Better git diffs

    # Documentation
    zeal # Offline API documentation browser
    anki # Spaced repetition flashcard app

    # System monitoring
    iotop
    iftop
    duf # Modern df alternative

    # Modern CLI replacements
    bat # Better cat
    eza # Better ls
    zoxide # Better cd
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
      source ${pkgs.forgit}/share/forgit/forgit.plugin.sh
    '';
    # bash_profile: HM's generated version already sources .profile and .bashrc — skip
    # bash_logout: only has Ubuntu-specific clear_console, no-op on NixOS — skip
    # profile: dotfiles/profile only has PATH additions (poetry, go, cargo) which are
    # all no-ops on NixOS — HM's generated .profile handles session vars
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

  # Yazi - terminal file manager with solarized dark theme
  programs.yazi = {
    enable = true;
    theme = {
      mgr = {
        cwd = { fg = "blue"; };
        hovered = {
          fg = "#002b36";
          bg = "blue";
          bold = true;
        };
        marker_selected = { fg = "blue"; bg = "blue"; };
        marker_copied = { fg = "green"; bg = "green"; };
        marker_cut = { fg = "red"; bg = "red"; };
        tab_active = {
          fg = "#002b36";
          bg = "blue";
          bold = true;
        };
        tab_inactive = { fg = "#839496"; bg = "#073642"; };
        border_style = { fg = "#586e75"; };
      };
      status = {
        mode_normal = {
          fg = "#002b36";
          bg = "blue";
          bold = true;
        };
        mode_select = {
          fg = "#002b36";
          bg = "green";
          bold = true;
        };
        mode_unset = {
          fg = "#002b36";
          bg = "#cb4b16";
          bold = true;
        };
        permissions_t = { fg = "blue"; };
        permissions_r = { fg = "yellow"; };
        permissions_w = { fg = "red"; };
        permissions_x = { fg = "green"; };
        permissions_s = { fg = "#586e75"; };
      };
      filetype = {
        rules = [
          { mime = "image/*"; fg = "yellow"; }
          { mime = "video/*"; fg = "magenta"; }
          { mime = "audio/*"; fg = "magenta"; }
          {
            mime = "application/zip";
            fg = "green";
          }
          {
            mime = "application/gzip";
            fg = "green";
          }
          {
            mime = "application/x-tar";
            fg = "green";
          }
          {
            name = "*/";
            fg = "blue";
            bold = true;
          }
        ];
      };
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
