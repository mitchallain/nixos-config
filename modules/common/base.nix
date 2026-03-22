# modules/common/base.nix - Base system configuration shared across all hosts
{ config, pkgs, ... }:

{
  # System state version - DO NOT CHANGE after initial install
  system.stateVersion = "25.11";

  # Bootloader configuration for UEFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set timezone (adjust as needed)
  time.timeZone = "America/Los_Angeles";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Define your user account
  # IMPORTANT: Change "mallain" to your actual username
  # This username must match what you use when importing these modules
  users.users.mallain = {
    isNormalUser = true;
    description = "mallain";
    extraGroups = [ "networkmanager" "wheel" ];  # wheel = sudo access
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System-wide packages (common to all systems)
  environment.systemPackages = with pkgs; [
    # Essential tools
    vim
    neovim
    git
    wget
    curl
    htop
    btop
    tmux
    fzf
    ripgrep
    fd

    # Development tools
    gcc
    gnumake
    cmake

    # Network tools
    nmap
    netcat
    inetutils

    # Compression tools
    unzip
    zip
    p7zip

    # System tools
    lshw
    pciutils
    usbutils
  ];

  # Enable the OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Automatic garbage collection (experimental-features and auto-optimise-store
  # are managed by Determinate Nix)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };

  # Enable NetworkManager for easy network configuration
  networking.networkmanager.enable = true;
}
