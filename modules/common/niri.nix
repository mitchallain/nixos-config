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
  # Fix NetworkManager Wi-Fi UAF crash in Quickshell 0.3.0 when AvailableConnections changes during scan/roam
  nixpkgs.overlays = [
    (final: prev: {
      quickshell = prev.quickshell.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          ${prev.python3}/bin/python3 - <<'EOF'
          from pathlib import Path

          p = Path("src/network/nm/network.cpp")
          s = p.read_text()

          old_ref = """\t// If the network has an active connection, use its settings as the reference.
          \tif (this->mActiveConnection) {
          \t\tauto* settings = this->mSettings.value(this->mActiveConnection->connection().path());
          \t\tif (settings && settings != this->bReferenceSettings) {
          \t\t\tthis->bReferenceSettings = settings;
          \t\t}
          \t\treturn;
          \t}"""
          new_ref = """\t// If the network has an active connection, use its settings as the reference.
          \tif (this->mActiveConnection) {
          \t\tif (auto* settings = this->mSettings.value(this->mActiveConnection->connection().path())) {
          \t\t\tif (settings != this->bReferenceSettings) {
          \t\t\t\tthis->bReferenceSettings = settings;
          \t\t\t}
          \t\t\treturn;
          \t\t}
          \t}"""
          assert old_ref in s, "old_ref not found"
          s = s.replace(old_ref, new_ref)

          old_settings_destroy = """\tauto onDestroyed = [this, settings]() {
          \t\tif (this->mSettings.take(settings->path())) {
          \t\t\temit this->settingsRemoved(settings);
          \t\t\tthis->updateReferenceSettings();
          \t\t\tif (this->mSettings.isEmpty()) this->bKnown = false;
          \t\t}
          \t};"""
          new_settings_destroy = """\tauto onDestroyed = [this, settings]() {
          \t\tif (this->mSettings.take(settings->path())) {
          \t\t\tthis->updateReferenceSettings();
          \t\t\tif (this->mSettings.isEmpty()) this->bKnown = false;
          \t\t\temit this->settingsRemoved(settings);
          \t\t}
          \t};"""
          assert old_settings_destroy in s, "old_settings_destroy not found"
          s = s.replace(old_settings_destroy, new_settings_destroy)

          old_active = """\tthis->bState.setBinding([active]() { return active->state(); });
          \tthis->bReason.setBinding([active]() { return active->stateReason(); });"""
          new_active = """\tconst QPointer<NMActiveConnection> activePtr = active;
          \tthis->bState.setBinding([activePtr]() { return activePtr ? activePtr->state() : NMConnectionState::Deactivated; });
          \tthis->bReason.setBinding([activePtr]() { return activePtr ? activePtr->stateReason() : NMConnectionStateReason::None; });"""
          assert old_active in s, "old_active not found"
          s = s.replace(old_active, new_active)

          old_sec = """\tauto updateSecurity = [this]() {
          \t\tif (NMSettings* settings = this->bReferenceSettings) {
          \t\t\tthis->bSecurity.setBinding([settings]() { return securityFromSettingsMap(settings->map()); });
          \t\t} else if (NMAccessPoint* ap = this->bReferenceAp) {
          \t\t\tthis->bSecurity.setBinding([ap]() { return ap->security(); });
          \t\t} else {
          \t\t\tthis->bSecurity = WifiSecurityType::Unknown;
          \t\t}
          \t\treturn;
          \t};"""
          new_sec = """\tauto updateSecurity = [this]() {
          \t\tif (const QPointer<NMAccessPoint> ap = this->bReferenceAp.value()) {
          \t\t\tthis->bSecurity.setBinding([ap]() { return ap ? ap->security() : WifiSecurityType::Unknown; });
          \t\t} else if (const QPointer<NMSettings> settings = this->bReferenceSettings.value()) {
          \t\t\tthis->bSecurity.setBinding([settings]() { return settings ? securityFromSettingsMap(settings->map()) : WifiSecurityType::Unknown; });
          \t\t} else {
          \t\t\tthis->bSecurity = WifiSecurityType::Unknown;
          \t\t}
          \t\treturn;
          \t};"""
          assert old_sec in s, "old_sec not found"
          s = s.replace(old_sec, new_sec)

          old_ap_ref = """\tif (this->bReferenceAp != selectedAp) {
          \t\tthis->bReferenceAp = selectedAp;
          \t\tthis->bSignalStrength.setBinding([selectedAp]() { return selectedAp->signalStrength(); });
          \t}"""
          new_ap_ref = """\tif (this->bReferenceAp != selectedAp) {
          \t\tthis->bReferenceAp = selectedAp;
          \t\tconst QPointer<NMAccessPoint> apPtr = selectedAp;
          \t\tthis->bSignalStrength.setBinding([apPtr]() { return apPtr ? apPtr->signalStrength() : quint8(0); });
          \t}"""
          assert old_ap_ref in s, "old_ap_ref not found"
          s = s.replace(old_ap_ref, new_ap_ref)

          old_ap_destroy = """\tauto onDestroyed = [this, ap]() {
          \t\tif (this->mAccessPoints.take(ap->path())) {
          \t\t\temit this->apRemoved(ap);
          \t\t\tthis->updateReferenceAp();
          \t\t}
          \t};"""
          new_ap_destroy = """\tauto onDestroyed = [this, ap]() {
          \t\tif (this->mAccessPoints.take(ap->path())) {
          \t\t\tthis->updateReferenceAp();
          \t\t\temit this->apRemoved(ap);
          \t\t}
          \t};"""
          assert old_ap_destroy in s, "old_ap_destroy not found"
          s = s.replace(old_ap_destroy, new_ap_destroy)

          p.write_text(s)

          p = Path("src/network/nm/utils.cpp")
          s = p.read_text()
          s = s.replace(
              "if (!settings.contains(mapName)) return WifiSecurityType::Unknown;",
              "if (!settings.contains(mapName)) return WifiSecurityType::Open;",
          )
          p.write_text(s)

          p = Path("src/network/nm/wireless.cpp")
          s = p.read_text()
          s = s.replace(
              'if (mode == "infrastructure") {',
              'if (mode.isEmpty() || mode == "infrastructure") {',
          )
          p.write_text(s)
          EOF
        '';
      });
    })
  ];

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

  # UPower daemon for battery & Bluetooth device power monitoring in Quickshell
  services.upower.enable = true;

  # PAM for swaylock (screen locker)
  security.pam.services.swaylock = { };

  # Wayland session variables for Electron apps and Nvidia
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Electron apps: use Wayland backend
    MOZ_ENABLE_WAYLAND = "1"; # Firefox: force Wayland
    QT_QPA_PLATFORM = "wayland"; # Qt apps: use Wayland
    SDL_VIDEODRIVER = "wayland"; # SDL apps: use Wayland
  };

  # UI fonts used by Vicinae and Pond shell
  fonts.packages = [
    (pkgs.google-fonts.override { fonts = [ "Onest" "AdventPro" ]; })
    pkgs.ibm-plex
  ];

  # Essential packages for a functional niri desktop
  environment.systemPackages = with pkgs; [
    waybar # Status bar (fallback)
    quickshell # Pond OS status bar & widget shell
    swaybg # Wallpaper setter
    vicinae # App launcher & command palette
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
