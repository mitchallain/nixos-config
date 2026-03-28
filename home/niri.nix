# home/niri.nix - Niri compositor user configuration
{ config, pkgs, ... }:

let
  wallpaper = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/o3/wallhaven-o3r9p7.png";
    sha256 = "sha256-IN1+5sIyuSOEilxsq/v5gxsSdCYCT3ZGrp0IzY64ICo=";
  };
in

{
  # Cursor theme - Adwaita 24px is clean and standard
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  # Niri config.kdl - scrollable-tiling compositor configuration
  home.file.".config/niri/config.kdl".text = ''
        // Niri configuration
        // Mod key = Super (Windows key)

        input {
            keyboard {
                xkb {
                    layout "us"
                    options "caps:super"
                }
                repeat-delay 600
                repeat-rate 25
            }
            mouse {
                // natural-scroll (off by default)
            }
            touchpad {
                tap
                natural-scroll
                dwt  // disable-while-typing
            }
        }

        // Monitor configuration
        // Run `niri msg outputs` to see connected outputs
        // Uncomment and adjust as needed:
        // output "DP-1" {
        //     mode "2560x1440@144.001"
        //     scale 1.0
        //     position x=0 y=0
        // }

        layout {
            gaps 8

            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }

            default-column-width { proportion 0.5; }

            focus-ring {
                off
            }

            border {
                width 2
                active-color "#7fc8ff"
                inactive-color "#404040"
            }

            shadow {
                on
            }
        }

        // Use server-side decorations (better for tiling)
        prefer-no-csd

        // Window appearance
        window-rule {
            geometry-corner-radius 8
            clip-to-geometry true
            draw-border-with-background false
        }

        // Screenshot save location
        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        // Autostart applications
        spawn-at-startup "swaybg" "-m" "fill" "-i" "${wallpaper}"
        spawn-at-startup "waybar"
    spawn-at-startup "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1"
        spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "timeout" "310" "niri msg action power-off-monitors" "resume" "niri msg action power-on-monitors" "before-sleep" "swaylock -f"

        // Environment variables passed to all spawned processes
        environment {
            DISPLAY ":0"  // Ensure XWayland display is set for X11 apps
        }

        animations {
            slowdown 0.8
        }

        binds {
            // ── Launchers ──────────────────────────────────────────────────────────
            Mod+Return   { spawn "alacritty"; }
            Alt+Shift+T  { spawn "alacritty"; }  // Mirror GNOME terminal shortcut
            Mod+D        { spawn "fuzzel"; }
            Mod+E        { spawn "nautilus"; }

            // ── Window management ──────────────────────────────────────────────────
            Mod+Q { close-window; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            Mod+C { center-column; }

            // ── Focus movement (vim keys + arrows) ─────────────────────────────────
            Mod+H     { focus-column-left; }
            Mod+L     { focus-column-right; }
            Mod+J     { focus-window-down; }
            Mod+K     { focus-window-up; }
            Mod+Left  { focus-column-left; }
            Mod+Right { focus-column-right; }
            Mod+Down  { focus-window-down; }
            Mod+Up    { focus-window-up; }

            // First/last column
            Mod+Home { focus-column-first; }
            Mod+End  { focus-column-last; }

            // ── Move windows ───────────────────────────────────────────────────────
            Mod+Shift+H     { move-column-left; }
            Mod+Shift+L     { move-column-right; }
            Mod+Shift+J     { move-window-down; }
            Mod+Shift+K     { move-window-up; }
            Mod+Shift+Left  { move-column-left; }
            Mod+Shift+Right { move-column-right; }
            Mod+Shift+Home  { move-column-to-first; }
            Mod+Shift+End   { move-column-to-last; }

            // ── Resize ─────────────────────────────────────────────────────────────
            Mod+R          { switch-preset-column-width; }
            Mod+Shift+R    { reset-window-height; }
            Mod+Minus      { set-column-width "-10%"; }
            Mod+Equal      { set-column-width "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }

            // ── Workspaces ─────────────────────────────────────────────────────────
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }

            Mod+Ctrl+Up    { focus-workspace-up; }
            Mod+Ctrl+Down  { focus-workspace-down; }
            Mod+Ctrl+Shift+Up   { move-column-to-workspace-up; }
            Mod+Ctrl+Shift+Down { move-column-to-workspace-down; }

            // ── Multi-monitor ──────────────────────────────────────────────────────
            Mod+Shift+Tab { focus-monitor-left; }
            Mod+Tab       { focus-monitor-right; }
            Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
            Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

            // ── Screenshots ────────────────────────────────────────────────────────
            Print             { screenshot; }
            Ctrl+Print        { screenshot-screen; }
            Alt+Print         { screenshot-window; }

            // ── Audio ──────────────────────────────────────────────────────────────
            XF86AudioRaiseVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
            XF86AudioLowerVolume  allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
            XF86AudioMute         allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute                             { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

            // ── Brightness ─────────────────────────────────────────────────────────
            XF86MonBrightnessUp   { spawn "brightnessctl" "set" "+10%"; }
            XF86MonBrightnessDown { spawn "brightnessctl" "set" "10%-"; }

            // ── Session ────────────────────────────────────────────────────────────
            Mod+Ctrl+L { spawn "sh" "-c" "swaylock -f & sleep 10 && pgrep swaylock && niri msg action power-off-monitors"; }
            Mod+Shift+E { quit; }

            // ── Help ───────────────────────────────────────────────────────────────
            Mod+Shift+Slash { show-hotkey-overlay; }
        }
  '';

  # Mako notification daemon
  services.mako = {
    enable = true;
    settings.default-timeout = 10000;
  };

  # Ensure Screenshots directory exists
  home.file."Pictures/Screenshots/.keep".text = "";

  # Waybar
  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        margin-top = 8;
        margin-left = 12;
        margin-right = 12;
        height = 36;

        modules-left = [ "wlr/taskbar" ];
        modules-right = [
          "tray"
          "network"
          "wireplumber"
          "cpu"
          "memory"
          "clock"
        ];

        "wlr/taskbar" = {
          format = "{icon}";
          icon-size = 16;
          icon-theme = "Adwaita";
          tooltip-format = "{title}";
          on-click = "activate";
          on-click-middle = "close";
        };

        "tray" = {
          icon-size = 18;
          spacing = 6;
        };

        "network" = {
          format-wifi = "󰤨  {essid}";
          format-ethernet = "󰈀  {ifname}";
          format-disconnected = "󰤭  disconnected";
          tooltip-format-wifi = "{essid} — {signalStrength}%";
          on-click = "alacritty -e nmtui";
        };

        "wireplumber" = {
          format = "󰕾  {volume}%";
          format-muted = "󰖁  muted";
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          scroll-step = 5;
        };

        "cpu" = {
          interval = 5;
          format = "󰻠  {usage}%";
        };

        "memory" = {
          interval = 10;
          format = "󰍛  {used:0.1f}G";
        };

        "clock" = {
          format = "󰥔  {:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<tt>{calendar}</tt>";
        };
      }
    ];

    style = ''
      * {
        font-family: "MesloLGMDZ Nerd Font Mono", monospace;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background: rgba(12, 12, 16, 0.82);
        border-radius: 10px;
        color: #d0d0d0;
      }

      #taskbar {
        padding: 0 4px;
      }

      #taskbar button {
        padding: 0 5px;
        margin: 6px 2px;
        border-radius: 6px;
        background: transparent;
        box-shadow: none;
        transition: background 0.15s ease;
      }

      #taskbar button:hover {
        background: rgba(255, 255, 255, 0.08);
      }

      #taskbar button.active {
        background: rgba(255, 255, 255, 0.12);
      }

      #network,
      #wireplumber,
      #wireplumber.muted,
      #cpu,
      #cpu.warning,
      #cpu.critical,
      #memory,
      #memory.warning,
      #memory.critical,
      #clock {
        color: #d0d0d0;
        background: transparent;
        padding: 0 10px;
      }

      #clock {
        padding-right: 14px;
      }
    '';
  };
}
