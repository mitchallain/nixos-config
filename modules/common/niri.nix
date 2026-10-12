# modules/common/niri.nix - Niri scrollable-tiling Wayland compositor
{ config, pkgs, ... }:

let
  flameshot-path = pkgs.writeShellScriptBin "flameshot-path" ''
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    file="$dir/screenshot-$(date +%Y%m%d-%H%M%S).png"
    flameshot gui --path "$file"
    if [ -f "$file" ]; then
      printf '%s' "$file" | wl-copy
    fi
  '';
in

{
  # Enable niri compositor (installs niri, sets up polkit, etc.)
  programs.niri = {
    enable = true;
    # Use Nautilus as the default file manager within niri
    useNautilus = true;
  };

  # Lightweight display manager with tuigreet for niri
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # Audio via PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # XDG portals for screen sharing, file pickers, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome # Needed for screencasting in niri
    ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
    };
  };

  # Printing support
  services.printing.enable = true;

  # PAM for swaylock (screen locker)
  security.pam.services.swaylock = { };

  # Wayland session variables for Electron apps and Nvidia
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron apps: use Wayland backend
    MOZ_ENABLE_WAYLAND = "1"; # Firefox: force Wayland
    QT_QPA_PLATFORM = "wayland"; # Qt apps: use Wayland
    SDL_VIDEODRIVER = "wayland"; # SDL apps: use Wayland
  };

  # Essential packages for a functional niri desktop
  environment.systemPackages = with pkgs; [
    waybar # Status bar
    swaybg # Wallpaper setter
    fuzzel # App launcher
    mako # Notification daemon
    swaylock # Screen locker
    swayidle # Idle management (dim/lock/suspend)
    grim # Screenshot tool
    slurp # Screen region selector (used with grim)
    flameshot # Screenshot tool with annotation
    flameshot-path # Wrapper: saves screenshot and copies path to clipboard
    wl-clipboard # Clipboard (wl-copy / wl-paste)
    cliphist # Clipboard history
    brightnessctl # Screen brightness
    libnotify # Desktop notifications (notify-send)
    xwayland # Compatibility for X11 apps
    xwayland-satellite # XWayland integration for niri
    nautilus # File manager
    polkit_gnome # Polkit authentication agent
    networkmanagerapplet # WiFi/network management GUI
    overskride # Bluetooth management
    pavucontrol # PipeWire/PulseAudio volume control GUI
  ];
}
