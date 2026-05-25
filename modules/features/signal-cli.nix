{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.signalCli;
in
{
  options.mySystem.signalCli = {
    enable = mkEnableOption "signal-cli HTTP daemon";

    listenAddress = mkOption {
      type = types.str;
      default = "10.0.0.1:8081";
      description = "Host:port for the HTTP daemon (default: microvm bridge IP)";
    };

    accountFile = mkOption {
      type = types.path;
      description = "File containing the Signal phone number in E.164 format (e.g. +12125551234)";
    };
  };

  config = mkIf cfg.enable {
    users.users.signal-cli = {
      isSystemUser = true;
      group = "signal-cli";
      description = "signal-cli daemon";
    };
    users.groups.signal-cli = { };

    systemd.tmpfiles.rules = [
      "d /var/lib/signal-cli 0750 signal-cli signal-cli -"
    ];

    environment.systemPackages = [ pkgs.signal-cli ];

    # signal-cli HTTP daemon — exposes JSON-RPC at listenAddress for Hermes agent.
    #
    # Before first start, register or link an account:
    #   sudo -u signal-cli signal-cli -c /var/lib/signal-cli link -n fractal
    # Scan the printed URL as a QR code in the Signal app (Settings → Linked Devices).
    systemd.services.signal-cli-daemon = {
      description = "signal-cli HTTP daemon";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # Don't start if no account has been linked yet (avoids crash-loop before setup)
      unitConfig.ConditionPathExists = "/var/lib/signal-cli/data";
      serviceConfig = {
        Type = "simple";
        User = "signal-cli";
        Group = "signal-cli";
        ExecStart = pkgs.writeShellScript "signal-cli-start" ''
          account=$(tr -d '[:space:]' < ${cfg.accountFile})
          exec ${pkgs.signal-cli}/bin/signal-cli \
            -c /var/lib/signal-cli \
            -a "$account" \
            daemon \
            --http ${cfg.listenAddress} \
            --receive-mode on-connection \
            --no-receive-stdout
        '';
        Restart = "on-failure";
        RestartSec = 10;
      };
    };
  };
}
