{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mySystem.healthCheck;

  runtimeDeps = with pkgs; [
    zfs
    curl
    findutils
    coreutils
    gnugrep
    gawk
    systemd
  ];

  healthCheck = pkgs.writeShellScriptBin "health-check" ''
    export PATH="${makeBinPath runtimeDeps}:$PATH"
    exec ${pkgs.bash}/bin/bash ${../../scripts/health-check.sh} "$@"
  '';
in
{
  options.mySystem.healthCheck = {
    enable = mkEnableOption "daily system health check";

    schedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Systemd OnCalendar expression for the health check timer";
    };

    notify = {
      enable = mkEnableOption "Signal message on health check failure";

      accountFile = mkOption {
        type = types.path;
        description = "File containing the Signal account phone number in E.164 format";
      };

      recipient = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Recipient phone number (E.164). Defaults to self (same as account) if null.";
      };

      daemonAddress = mkOption {
        type = types.str;
        default = "http://10.0.0.1:8081";
        description = "signal-cli HTTP daemon address; must match mySystem.signalCli.listenAddress";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ healthCheck ];

    systemd.services.health-check = {
      description = "System health check";
      unitConfig = mkIf cfg.notify.enable {
        OnFailure = "health-check-notify.service";
      };
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${healthCheck}/bin/health-check";
      };
    };

    systemd.services.health-check-notify = mkIf cfg.notify.enable {
      description = "Signal notification for health check failure";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = pkgs.writeShellScript "health-check-notify" ''
          ${if cfg.notify.recipient != null
            then "recipient=${lib.escapeShellArg cfg.notify.recipient}"
            else "recipient=$(${pkgs.coreutils}/bin/tr -d '[:space:]' < ${cfg.notify.accountFile})"}
          output=$(${pkgs.systemd}/bin/journalctl -u health-check -n 30 --no-pager -o cat 2>/dev/null \
            || echo "(could not retrieve logs)")
          body=$(${pkgs.jq}/bin/jq -n \
            --arg r "$recipient" \
            --arg m "$(printf 'Health check FAILED on %s\n\n%s' "${config.networking.hostName}" "$output")" \
            '{"jsonrpc":"2.0","method":"send","id":1,"params":{"recipient":[$r],"message":$m}}')
          ${pkgs.curl}/bin/curl -sf -X POST "${cfg.notify.daemonAddress}/api/v1/rpc" \
            -H "Content-Type: application/json" \
            -d "$body"
        '';
      };
    };

    systemd.timers.health-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };
  };
}
