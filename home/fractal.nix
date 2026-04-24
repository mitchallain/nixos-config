{ ... }:

{
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
