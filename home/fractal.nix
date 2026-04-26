{ pkgs, lib, ... }:

{
  # Generate a default SSH keypair on first activation if none exists
  home.activation.generateSshKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N "" -C "mallain@fractal"
    fi
  '';

  # Hermes LLM agent microVM — host-only bridge network, key regenerates on rebuild
  programs.ssh.matchBlocks."hermes" = {
    hostname = "10.0.0.2";
    user = "root";
    identityFile = "~/.ssh/id_ed25519";
    extraOptions = {
      StrictHostKeyChecking = "no";
      UserKnownHostsFile = "/dev/null";
    };
  };

  # WirePlumber - set HDMI (Nvidia GPU / DELL U3417W) as default audio output
  # Node name: alsa_output.pci-0000_01_00.1.hdmi-stereo
  home.file.".config/wireplumber/wireplumber.conf.d/99-default-sink.conf".text = ''
    monitor.alsa.rules = [
      {
        matches = [
          {
            node.name = "alsa_output.pci-0000_01_00.1.hdmi-stereo"
          }
        ]
        actions = {
          update-props = {
            priority.session = 2000
          }
        }
      }
    ]
  '';
}
