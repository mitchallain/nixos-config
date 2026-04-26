{
  config,
  lib,
  pkgs,
  microvm,
  hermes-agent,
  ...
}:
with lib;
let
  bridgeName = "microvm0";
  hostIP = "10.0.0.1";
  vmIP = "10.0.0.2";
  prefixLen = 24;
  ollamaPort = 11434;
  # Capture host config value before entering guest config scope
  ollamaModel = config.mySystem.llmAgent.ollamaModel;
in
{
  options.mySystem.llmAgent = {
    enable = mkEnableOption "Hermes LLM agent microVM";
    ollamaModel = mkOption {
      type = types.str;
      default = "qwen3.5:9b";
      description = "Model name passed to Hermes (must match a model pulled by mySystem.ollama)";
    };
  };

  config = mkIf config.mySystem.llmAgent.enable {
    # ── Bridge interface (host side) ─────────────────────────────────
    networking.bridges.${bridgeName}.interfaces = [ ];
    networking.interfaces.${bridgeName}.ipv4.addresses = [
      {
        address = hostIP;
        prefixLength = prefixLen;
      }
    ];

    # ── Firewall rules for the bridge interface ──────────────────────
    # Defined here so they are removed with the module.
    networking.firewall.extraCommands = ''
      # Allow VM → Ollama on host
      iptables -A FORWARD -i ${bridgeName} -d ${hostIP} -p tcp --dport ${toString ollamaPort} -j ACCEPT
      # Allow VM → outbound internet (web search)
      iptables -A FORWARD -i ${bridgeName} -p tcp --dport 80 -j ACCEPT
      iptables -A FORWARD -i ${bridgeName} -p tcp --dport 443 -j ACCEPT
      # Drop everything else from the bridge
      iptables -A FORWARD -i ${bridgeName} -j DROP
      # Allow established return traffic
      iptables -A FORWARD -o ${bridgeName} -m state --state ESTABLISHED,RELATED -j ACCEPT
      # NAT outbound traffic from the VM
      iptables -t nat -A POSTROUTING -s ${vmIP}/32 -j MASQUERADE
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D FORWARD -i ${bridgeName} -d ${hostIP} -p tcp --dport ${toString ollamaPort} -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -p tcp --dport 80 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -p tcp --dport 443 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -j DROP || true
      iptables -D FORWARD -o ${bridgeName} -m state --state ESTABLISHED,RELATED -j ACCEPT || true
      iptables -t nat -D POSTROUTING -s ${vmIP}/32 -j MASQUERADE || true
    '';

    # Enable IP forwarding so the VM can reach the internet via the host
    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # ── microVM definition ───────────────────────────────────────────
    microvm.vms.hermes = {
      autostart = true;
      config = {
        imports = [
          hermes-agent.nixosModules.default
        ];

        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 2;
          mem = 2048;
          interfaces = [
            {
              type = "tap";
              id = "vm-hermes";
              mac = "02:00:00:00:00:01";
            }
          ];
          volumes = [
            {
              mountPoint = "/var/lib/hermes";
              image = "/var/lib/microvms/hermes/data.img";
              size = 8192;
            }
          ];
          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
              proto = "virtiofs";
            }
          ];
        };

        # Guest networking via systemd-networkd
        systemd.network.enable = true;
        networking.useNetworkd = true;
        systemd.network.networks."10-eth" = {
          matchConfig.Type = "ether";
          networkConfig = {
            Address = [ "${vmIP}/${toString prefixLen}" ];
            Gateway = hostIP;
            DNS = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            DHCP = "no";
          };
        };

        # Hermes agent (native mode — no container)
        services.hermes-agent = {
          enable = true;
          settings = {
            model = {
              base_url = "http://${hostIP}:${toString ollamaPort}/v1";
              default = ollamaModel;
            };
            toolsets = [ "all" ];
            terminal = {
              backend = "local";
              cwd = ".";
              timeout = 180;
            };
          };
          # TODO: phase 2 — add environmentFiles here for API keys
          # environmentFiles = [ "/run/secrets/hermes-env" ];
        };

        # Minimal system config for the guest
        system.stateVersion = "25.11";
      };
    };
  };
}
