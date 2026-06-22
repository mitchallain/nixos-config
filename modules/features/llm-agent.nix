{
  config,
  lib,
  pkgs,
  pkgs-unstable,
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
  signalCliPort = 8081;
in
{
  options.mySystem.llmAgent = {
    enable = mkEnableOption "Hermes LLM agent microVM";
  };

  config = mkIf config.mySystem.llmAgent.enable {
    # ── Host directory creation ──────────────────────────────────────
    systemd.tmpfiles.rules = [
      "d /var/lib/microvms/hermes/agent-config 0755 root root -"
      "d /var/lib/microvms/hermes/proposals 0755 root root -"
      "d /var/lib/microvms/hermes/agent-secrets 0755 root root -"
    ];

    # ── Activation script: generate CONTEXT.md ───────────────────────
    system.activationScripts.hermes-agent-context = {
      deps = [ ];
      text =
        let
          contextFile = pkgs.writeText "CONTEXT.md" ''
            # Hermes Agent — Self Context

            This file is generated at activation time and describes your current
            configuration, constraints, and how to propose changes to yourself.

            ## Current Configuration

            - **Model:** google/gemini-2.5-flash (via OpenRouter)
            - **Toolsets:** all

            ## Network Constraints

            You are running inside a kernel-isolated microVM. Your network access is
            restricted at the host firewall:

            - **Allowed outbound:** ports 80 and 443 (OpenRouter inference, web search, HTTPS)
            - **Blocked:** everything else — you cannot reach LAN hosts, host services
              (Immich, notes server, SSH), or arbitrary host ports

            You cannot modify your own firewall rules from inside the VM.

            ## Proposing Changes

            If you want to change your own configuration (add tools, change model,
            adjust network rules, add API keys, etc.), write a Markdown proposal file
            to `/run/proposals/`. A host-side agent or human will review and apply it.

            ### Proposal format

            File: `/run/proposals/YYYY-MM-DD-<short-title>.md`

            ```markdown
            # Proposal: <title>

            ## Summary
            One sentence description of the change.

            ## Motivation
            Why is this change needed? What will it enable?

            ## Proposed Nix Change
            Exact diff or replacement block for the relevant .nix file.
            Reference file: modules/features/llm-agent.nix

            ## Expected Impact
            What changes after rebuild? Any risks?
            ```

            ## Module Source

            Your full module definition is at `modules/features/llm-agent.nix` in the
            nixos-config repository. A copy is available at `/run/agent-config/llm-agent.nix`.

            ## Phase 2 (not yet implemented)

            The following are planned but not yet active:
            - API key injection via sops-nix (OpenRouter fallback, web search API key)
            - These will appear as `environmentFiles` in your systemd service config
          '';
        in
        ''
          mkdir -p /var/lib/microvms/hermes/agent-config
          cp ${contextFile} /var/lib/microvms/hermes/agent-config/CONTEXT.md
          mkdir -p /var/lib/microvms/hermes/proposals
        '';
    };

    # ── Bridge interface (host side) ─────────────────────────────────
    # Empty interfaces — vm-hermes is created by cloud-hypervisor at runtime,
    # so we attach it via udev when it appears rather than at network-setup time.
    networking.bridges.${bridgeName}.interfaces = [ ];
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="vm-hermes", RUN+="${pkgs.iproute2}/bin/ip link set %k master ${bridgeName}"
    '';
    networking.interfaces.${bridgeName}.ipv4.addresses = [
      {
        address = hostIP;
        prefixLength = prefixLen;
      }
    ];

    # ── Firewall rules for the bridge interface ──────────────────────
    # Defined here so they are removed with the module.
    networking.firewall.extraCommands = ''
      # Allow VM → outbound internet (web search)
      iptables -A FORWARD -i ${bridgeName} -p tcp --dport 80 -j ACCEPT
      iptables -A FORWARD -i ${bridgeName} -p tcp --dport 443 -j ACCEPT
      # Allow VM → DNS (required for hostname resolution)
      iptables -A FORWARD -i ${bridgeName} -p udp --dport 53 -j ACCEPT
      iptables -A FORWARD -i ${bridgeName} -p tcp --dport 53 -j ACCEPT
      # Drop everything else from the bridge
      iptables -A FORWARD -i ${bridgeName} -j DROP
      # Allow established return traffic
      iptables -A FORWARD -o ${bridgeName} -m state --state ESTABLISHED,RELATED -j ACCEPT
      # NAT outbound traffic from the VM
      iptables -t nat -A POSTROUTING -s ${vmIP}/32 -j MASQUERADE
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D FORWARD -i ${bridgeName} -p tcp --dport 80 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -p tcp --dport 443 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -p udp --dport 53 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -p tcp --dport 53 -j ACCEPT || true
      iptables -D FORWARD -i ${bridgeName} -j DROP || true
      iptables -D FORWARD -o ${bridgeName} -m state --state ESTABLISHED,RELATED -j ACCEPT || true
      iptables -t nat -D POSTROUTING -s ${vmIP}/32 -j MASQUERADE || true
    '';

    # Allow VM → signal-cli daemon on host (INPUT, not FORWARD — traffic is destined for host)
    networking.firewall.interfaces.${bridgeName}.allowedTCPPorts = [ signalCliPort ];

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
          vsock.cid = 3;
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
            {
              # Read-only context: CONTEXT.md and other host-generated config files
              tag = "agent-config";
              source = "/var/lib/microvms/hermes/agent-config";
              mountPoint = "/run/agent-config";
              proto = "virtiofs";
            }
            {
              # Read-write proposals: Hermes writes proposal files here, host reads them
              tag = "proposals";
              source = "/var/lib/microvms/hermes/proposals";
              mountPoint = "/run/proposals";
              proto = "virtiofs";
            }
            {
              # API keys written as real files by host activation script (not sops symlinks)
              tag = "hermes-secrets";
              source = "/var/lib/microvms/hermes/agent-secrets";
              mountPoint = "/run/agent-secrets";
              proto = "virtiofs";
            }
          ];
        };

        # Persist hermes CLI config alongside the service's state directory
        systemd.tmpfiles.rules = [
          "L /root/.hermes - - - - /var/lib/hermes/.hermes"
        ];

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

        # Re-run activation after the persistent disk is mounted.
        # The hermes-agent module writes config.yaml during activation, but
        # /var/lib/hermes is a microvm disk image mounted by systemd — after
        # stage 2 activation runs. This service replays activation once the
        # mount is ready so config.yaml is always written declaratively.
        systemd.services.hermes-activation-replay = {
          description = "Replay NixOS activation after persistent disk mount";
          after = [ "var-lib-hermes.mount" ];
          before = [
            "hermes-agent.service"
            "hermes-env-setup.service"
          ];
          wantedBy = [ "hermes-agent.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Discover the booted system store path at runtime from the kernel
            # cmdline — avoids a circular dependency on system.build.toplevel.
            ExecStart = pkgs.writeShellScript "hermes-activation-replay" ''
              system=$(grep -oP 'init=\K\S+' /proc/cmdline | sed 's|/init$||')
              exec "$system/activate"
            '';
          };
        };

        # Write .env after virtiofs mounts are ready (activation runs too early)
        systemd.services.hermes-env-setup = {
          description = "Write Hermes .env from virtiofs secrets share";
          after = [
            "run-agent\\x2dsecrets.mount"
            "hermes-activation-replay.service"
          ];
          before = [ "hermes-agent.service" ];
          wantedBy = [ "hermes-agent.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "hermes-env-setup" ''
              install -o hermes -g hermes -m 0640 /run/agent-secrets/env /var/lib/hermes/.hermes/.env

              # agent-browser downloads generic Linux Chrome which can't run on NixOS.
              # Replace any downloaded Chrome binaries with a wrapper calling NixOS Chromium.
              AB_BROWSERS="/var/lib/hermes/.agent-browser/browsers"
              mkdir -p "$AB_BROWSERS"
              chown hermes:hermes "$AB_BROWSERS"
              for dir in "$AB_BROWSERS"/chrome-*/; do
                [ -d "$dir" ] || continue
                printf '#!/bin/sh\nexec ${pkgs.chromium}/bin/chromium "$@"\n' > "$dir/chrome"
                chmod +x "$dir/chrome"
                chown -R hermes:hermes "$dir"
              done

              # First-time setup: if no Chrome directory exists yet, run agent-browser install
              # (downloads the directory structure), then immediately replace the binary.
              if ! ls "$AB_BROWSERS"/chrome-* 2>/dev/null | grep -q .; then
                su -s /bin/sh hermes -c "HOME=/var/lib/hermes ${pkgs-unstable.agent-browser}/bin/agent-browser install" || true
                for dir in "$AB_BROWSERS"/chrome-*/; do
                  [ -d "$dir" ] || continue
                  printf '#!/bin/sh\nexec ${pkgs.chromium}/bin/chromium "$@"\n' > "$dir/chrome"
                  chmod +x "$dir/chrome"
                  chown -R hermes:hermes "$dir"
                done
              fi

              # hermes browser_tool checks ~/.cache/ms-playwright/chromium-* to detect
              # Chromium (written for agent-browser 0.26+ which uses Playwright builds).
              # Create a stub so the browser toolset is advertised as available.
              mkdir -p /var/lib/hermes/.cache/ms-playwright/chromium-stub
              chown -R hermes:hermes /var/lib/hermes/.cache
            '';
          };
        };

        # agent-browser is in the system PATH but the hermes-agent service has a
        # restricted PATH — shutil.which() can't find it. Inject it explicitly.
        systemd.services.hermes-agent.path = [
          pkgs-unstable.agent-browser
          pkgs.chromium
        ];

        # Hermes agent (native mode — no container)
        services.hermes-agent = {
          enable = true;
          settings = {
            model = {
              provider = "openrouter";
              default = "google/gemini-2.5-flash";
            };
            toolsets = [ "all" ];
            terminal = {
              backend = "local";
              cwd = ".";
              timeout = 180;
            };
            compression = {
              enabled = true;
              threshold = 0.7;
              summary_model = "google/gemma-4-26b-a4b-it:free";
            };
            auxiliary.compression = {
              provider = "openrouter";
            };
          };
        };

        # SSH access from host
        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "prohibit-password";
        };
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINwCt7EppWledVMQxd3sBn1bvYJaGyZCM79DtrzXuL0 mallain@fractal"
        ];

        environment.systemPackages = [
          hermes-agent.packages.x86_64-linux.default
          pkgs-unstable.agent-browser # not yet in stable nixpkgs
          pkgs.chromium # used as Chrome backend for agent-browser (NixOS-compatible)
        ];

        # Minimal system config for the guest
        system.stateVersion = "25.11";
      };
    };
  };
}
